"""
ConversationSummaryService — Application/Services Layer
========================================================
Generates and persists structured AI summaries of AYA conversation sessions.

Session detection:
  A "session" is a contiguous block of interacoes with < SESSION_GAP_MINUTES between
  consecutive messages. When the gap exceeds 30 minutes the session is considered closed
  and eligible for summarisation.

Summarisation chain:
  Uses LangChain with OpenRouter (Gemini) to produce a structured JSON object covering
  the six spec-mandated topics. The raw LLM response is validated against
  ConversationSummaryTopics before persisting — invalid JSON triggers the fallback path.

Fallback:
  If LLM generation fails or validation fails, a row is written with resumo_pendente=True
  so the retry cron job can reattempt it without data loss.
"""

from __future__ import annotations

import json
import re
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

import structlog
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.config.settings import get_settings
from app.infrastructure.persistence.models.conversation_summary_model import (
    ConversationSummaryModel,
)
from app.infrastructure.persistence.repositories.conversation_summary_repository import (
    ConversationSummaryRepository,
)
from app.presentation.schemas.conversation_summary_schema import ConversationSummaryTopics
from app.services.observability import get_callbacks_for_chain, flush_langfuse

logger = structlog.get_logger()
settings = get_settings()

SESSION_GAP_MINUTES = 30  # inactivity threshold that closes a session

_SUMMARISATION_SYSTEM_PROMPT = """\
Você é um assistente especialista em turismo. Sua tarefa é analisar uma conversa \
entre um cliente e a assistente virtual AYA da Cadife Tour e gerar um briefing \
estruturado em tópicos para o consultor humano que irá dar continuidade ao atendimento.

REGRAS OBRIGATÓRIAS:
1. Retorne APENAS um objeto JSON válido. Sem explicações, sem markdown, sem texto fora do JSON.
2. Se uma informação não foi mencionada na conversa, use null para esse campo.
3. Seja conciso — cada tópico deve ter no máximo 2-3 frases.
4. NUNCA invente preços, datas, destinos ou disponibilidades que não foram citados explicitamente.
5. Use português brasileiro.

SCHEMA JSON OBRIGATÓRIO:
{{
  "intencao_principal": "string ou null",
  "datas_e_passageiros": "string ou null",
  "orcamento": "string ou null",
  "restricoes_e_preferencias": "string ou null",
  "decisoes_tomadas": "string ou null",
  "proximos_passos": "string ou null"
}}"""

_SUMMARISATION_HUMAN_PROMPT = """\
Gere o briefing estruturado para a seguinte conversa entre cliente e AYA:

{conversation}"""


def _build_session_id(lead_id: uuid.UUID, session_end_ts: datetime) -> str:
    """Deterministic session key: {lead_id_short}:{YYYYMMDD_HHMM}"""
    ts_str = session_end_ts.strftime("%Y%m%d_%H%M")
    return f"{str(lead_id)[:8]}:{ts_str}"


def _segment_into_sessions(
    interacoes: list[dict],
    gap_minutes: int = SESSION_GAP_MINUTES,
) -> list[list[dict]]:
    """Group interacoes into sessions separated by > gap_minutes of inactivity."""
    if not interacoes:
        return []

    sessions: list[list[dict]] = []
    current: list[dict] = [interacoes[0]]

    for prev, curr in zip(interacoes, interacoes[1:]):
        prev_ts: datetime = prev["timestamp"]
        curr_ts: datetime = curr["timestamp"]

        if prev_ts.tzinfo is None:
            prev_ts = prev_ts.replace(tzinfo=timezone.utc)
        if curr_ts.tzinfo is None:
            curr_ts = curr_ts.replace(tzinfo=timezone.utc)

        if (curr_ts - prev_ts) > timedelta(minutes=gap_minutes):
            sessions.append(current)
            current = []
        current.append(curr)

    sessions.append(current)
    return sessions


def _format_session_as_text(session_messages: list[dict]) -> str:
    lines = []
    for msg in session_messages:
        if msg.get("mensagem_cliente"):
            lines.append(f"CLIENTE: {msg['mensagem_cliente']}")
        if msg.get("mensagem_ia"):
            lines.append(f"AYA: {msg['mensagem_ia']}")
    return "\n".join(lines)


def _parse_topics(raw: str) -> Optional[ConversationSummaryTopics]:
    """Parse LLM output into ConversationSummaryTopics, stripping markdown fences."""
    cleaned = raw.strip()
    if "```" in cleaned:
        match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", cleaned, re.DOTALL)
        if match:
            cleaned = match.group(1)
        else:
            cleaned = re.sub(r"```(?:json)?", "", cleaned).strip().rstrip("`").strip()
    try:
        data = json.loads(cleaned)
        return ConversationSummaryTopics.model_validate(data)
    except Exception:
        return None


def _get_summarisation_llm() -> ChatOpenAI:
    return ChatOpenAI(
        model=settings.OPENROUTER_MODEL,
        temperature=0.1,
        timeout=30,
        max_retries=2,
        openai_api_key=settings.OPENROUTER_API_KEY,
        openai_api_base="https://openrouter.ai/api/v1",
        default_headers={
            "HTTP-Referer": "https://cadifetour.com",
            "X-Title": "Cadife Smart Travel — Summary",
        },
    )


async def _generate_topics(
    conversation_text: str,
) -> tuple[Optional[ConversationSummaryTopics], int]:
    """Call LLM and return (parsed_topics, tokens_used). Returns (None, 0) on failure."""
    llm = _get_summarisation_llm()
    prompt = ChatPromptTemplate.from_messages(
        [
            ("system", _SUMMARISATION_SYSTEM_PROMPT),
            ("human", _SUMMARISATION_HUMAN_PROMPT),
        ]
    )
    chain = prompt | llm

    callbacks = get_callbacks_for_chain()
    config = {"callbacks": callbacks} if callbacks else {}

    try:
        response = await chain.ainvoke(
            {"conversation": conversation_text}, config=config
        )
        flush_langfuse()

        tokens_used: int = 0
        if hasattr(response, "usage_metadata") and response.usage_metadata:
            tokens_used = response.usage_metadata.get("total_tokens", 0)
        elif hasattr(response, "response_metadata"):
            meta = response.response_metadata or {}
            tokens_used = meta.get("token_usage", {}).get("total_tokens", 0)

        topics = _parse_topics(str(response.content))
        return topics, tokens_used
    except Exception as exc:
        logger.error("summarisation_llm_failed", error=str(exc))
        flush_langfuse()
        return None, 0


async def summarise_closed_sessions(
    db: AsyncSession,
    lead_id: uuid.UUID,
    interacoes: list[dict],
) -> list[ConversationSummaryModel]:
    """
    Detect closed sessions in interacoes and generate summaries for any that
    do not yet have a row in conversation_summaries.

    Called from process_whatsapp_message after saving the interaction so the
    most recent message is included.

    Returns the list of summary rows created (may be empty if all sessions are
    already summarised or the last session is still open).
    """
    repo = ConversationSummaryRepository(db)
    sessions = _segment_into_sessions(interacoes)

    created: list[ConversationSummaryModel] = []

    # Only summarise sessions that are "closed" — i.e. all but the last one,
    # since the last session may still be receiving messages.
    closed_sessions = sessions[:-1] if len(sessions) > 1 else []

    for session_msgs in closed_sessions:
        if not session_msgs:
            continue

        last_msg = session_msgs[-1]
        last_ts: datetime = last_msg["timestamp"]
        if last_ts.tzinfo is None:
            last_ts = last_ts.replace(tzinfo=timezone.utc)

        sessao_id = _build_session_id(lead_id, last_ts)

        # Idempotency: skip if already summarised
        existing = await repo.get_by_sessao(lead_id, sessao_id)
        if existing:
            continue

        conversation_text = _format_session_as_text(session_msgs)
        topics, tokens_used = await _generate_topics(conversation_text)

        if topics is None:
            # Fallback: persist a pending row for retry
            row = await repo.create_pending(lead_id, sessao_id)
            logger.warning(
                "conversation_summary_pending",
                lead_id=str(lead_id),
                sessao_id=sessao_id,
            )
        else:
            row = ConversationSummaryModel(
                id=uuid.uuid4(),
                lead_id=lead_id,
                sessao_id=sessao_id,
                resumo_json=topics.model_dump(exclude_none=True),
                resumo_pendente=False,
                tokens_utilizados=tokens_used or None,
            )
            db.add(row)
            await db.flush()
            logger.info(
                "conversation_summary_created",
                lead_id=str(lead_id),
                sessao_id=sessao_id,
                tokens=tokens_used,
            )

        await db.commit()
        created.append(row)

    return created


async def retry_pending_summaries(
    db: AsyncSession,
    batch_size: int = 50,
) -> int:
    """
    Retry generation for rows with resumo_pendente=True.
    Called by the cron job every 15 minutes.
    Returns the number of successfully resolved rows.
    """
    repo = ConversationSummaryRepository(db)
    pending_rows = await repo.get_pending(limit=batch_size)

    if not pending_rows:
        return 0

    # Import here to avoid circular imports
    from app.services.lead_service import get_recent_interacoes  # noqa: PLC0415

    resolved = 0
    for row in pending_rows:
        try:
            interacoes = await get_recent_interacoes(db, row.lead_id, limit=200)
            sessions = _segment_into_sessions(interacoes)

            # Find the session that matches this sessao_id
            target_msgs: list[dict] = []
            for session_msgs in sessions:
                if not session_msgs:
                    continue
                last_msg = session_msgs[-1]
                last_ts: datetime = last_msg["timestamp"]
                if last_ts.tzinfo is None:
                    last_ts = last_ts.replace(tzinfo=timezone.utc)
                if _build_session_id(row.lead_id, last_ts) == row.sessao_id:
                    target_msgs = session_msgs
                    break

            if not target_msgs:
                logger.warning(
                    "retry_summary_session_not_found",
                    lead_id=str(row.lead_id),
                    sessao_id=row.sessao_id,
                )
                continue

            conversation_text = _format_session_as_text(target_msgs)
            topics, tokens_used = await _generate_topics(conversation_text)

            if topics is None:
                continue

            row.resumo_json = topics.model_dump(exclude_none=True)
            row.resumo_pendente = False
            row.tokens_utilizados = tokens_used or None
            await db.commit()
            resolved += 1

            logger.info(
                "conversation_summary_retry_resolved",
                lead_id=str(row.lead_id),
                sessao_id=row.sessao_id,
                tokens=tokens_used,
            )
        except Exception as exc:
            await db.rollback()
            logger.error(
                "conversation_summary_retry_failed",
                lead_id=str(row.lead_id),
                sessao_id=row.sessao_id,
                error=str(exc),
            )

    return resolved
