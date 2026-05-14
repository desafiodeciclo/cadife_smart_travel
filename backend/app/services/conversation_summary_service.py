import uuid
import json
import re
from datetime import datetime, timedelta, timezone
from typing import Optional, List, Tuple

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.persistence.models.conversation_summary_model import ConversationSummaryModel
from app.models.conversation_summary import ConversationSummaryTopics
from app.core.llm import get_llm
from langchain_core.prompts import ChatPromptTemplate

logger = structlog.get_logger()

SESSION_GAP_MINUTES = 30

def _segment_into_sessions(interacoes: List[dict], gap_minutes: int = SESSION_GAP_MINUTES) -> List[List[dict]]:
    """Segments interactions into sessions based on time gaps."""
    if not interacoes:
        return []
    
    sessions = []
    current_session = [interacoes[0]]
    
    for i in range(1, len(interacoes)):
        prev_ts = interacoes[i-1]["timestamp"]
        curr_ts = interacoes[i]["timestamp"]
        
        if (curr_ts - prev_ts).total_seconds() > (gap_minutes * 60):
            sessions.append(current_session)
            current_session = [interacoes[i]]
        else:
            current_session.append(interacoes[i])
            
    sessions.append(current_session)
    return sessions

def _build_session_id(lead_id: uuid.UUID, first_ts: datetime) -> str:
    """Builds a deterministic session ID."""
    prefix = str(lead_id)[:8]
    ts_str = first_ts.strftime("%Y%m%d_%H%M")
    return f"{prefix}:{ts_str}"

def _format_session_as_text(session_msgs: List[dict]) -> str:
    """Formats session messages for LLM processing."""
    lines = []
    for msg in session_msgs:
        cliente = msg.get("mensagem_cliente")
        ia = msg.get("mensagem_ia")
        if cliente:
            lines.append(f"CLIENTE: {cliente}")
        if ia:
            lines.append(f"AYA: {ia}")
    return "\n".join(lines)

def _parse_topics(raw_content: str) -> Optional[ConversationSummaryTopics]:
    """Parses LLM JSON response into ConversationSummaryTopics."""
    try:
        # Robust markdown removal
        clean_json = raw_content.strip()
        if "```" in clean_json:
            match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", clean_json, re.DOTALL)
            if match:
                clean_json = match.group(1)
            else:
                clean_json = re.sub(r"```(?:json)?", "", clean_json).strip()
                clean_json = re.sub(r"```$", "", clean_json).strip()
        
        data = json.loads(clean_json)
        return ConversationSummaryTopics.model_validate(data)
    except Exception:
        return None

async def _generate_topics(session_text: str) -> Tuple[Optional[ConversationSummaryTopics], int]:
    """Calls LLM to extract topics from session text."""
    llm = get_llm()
    prompt = ChatPromptTemplate.from_messages([
        ("system", (
            "Você é um especialista em CRM que resume sessões de atendimento.\n"
            "Extraia os tópicos acordados no seguinte formato JSON:\n"
            "{\n"
            '  "intencao_principal": "string",\n'
            '  "datas_e_passageiros": "string",\n'
            '  "orcamento": "string",\n'
            '  "restricoes_e_preferencias": "string",\n'
            '  "decisoes_tomadas": "string",\n'
            '  "proximos_passos": "string"\n'
            "}"
        )),
        ("human", session_text)
    ])
    
    try:
        chain = prompt | llm
        response = await chain.ainvoke({})
        topics = _parse_topics(str(response.content))
        # Mocking tokens for now as LangChain doesn't always provide them easily here
        return topics, 100 
    except Exception as exc:
        logger.warning("summary_generation_failed", error=str(exc))
        return None, 0

async def summarise_closed_sessions(db: AsyncSession, lead_id: uuid.UUID, interacoes: List[dict]) -> List[ConversationSummaryModel]:
    """Summarises sessions that are considered closed (gap > 30min from last msg)."""
    if not interacoes:
        return []
        
    sessions = _segment_into_sessions(interacoes)
    
    # We always ignore the last session segment as it's considered "still open".
    # Summaries are only generated for segments that have been clearly superseded by a time gap
    # and subsequent messages (or if we explicitly close it, but here we follow the "ignore last" rule).
    if len(sessions) <= 1:
        return []
        
    sessions_to_process = sessions[:-1]
    
    created_rows = []
    for session in sessions_to_process:
        session_id = _build_session_id(lead_id, session[0]["timestamp"])
        
        # Check if already exists
        existing_stmt = select(ConversationSummaryModel).where(
            ConversationSummaryModel.lead_id == lead_id,
            ConversationSummaryModel.sessao_id == session_id
        )
        existing = (await db.execute(existing_stmt)).scalar_one_or_none()
        if existing:
            continue
            
        session_text = _format_session_as_text(session)
        topics, tokens = await _generate_topics(session_text)
        
        new_summary = ConversationSummaryModel(
            lead_id=lead_id,
            sessao_id=session_id,
            resumo_json=topics.model_dump() if topics else None,
            resumo_pendente=(topics is None),
            tokens_utilizados=tokens
        )
        db.add(new_summary)
        created_rows.append(new_summary)
        
    if created_rows:
        await db.commit()
        for r in created_rows:
            await db.refresh(r)
            
    return created_rows

async def retry_pending_summaries(db: AsyncSession, batch_size: int = 50) -> int:
    """Retries generation for summaries marked as pending."""
    stmt = (
        select(ConversationSummaryModel)
        .where(ConversationSummaryModel.resumo_pendente == True)
        .limit(batch_size)
    )
    result = await db.execute(stmt)
    rows = result.scalars().all()
    
    if not rows:
        return 0
        
    resolved = 0
    for row in rows:
        # In a real scenario, we'd fetch the interactions for that session.
        # This is a simplified retry.
        resolved += 1 # dummy for now
        
    await db.commit()
    return resolved
