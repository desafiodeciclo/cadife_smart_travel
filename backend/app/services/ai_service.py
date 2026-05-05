import json
import re
import time
from typing import Optional

import structlog
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_classic.memory import ConversationBufferWindowMemory
from langchain_community.chat_message_histories import RedisChatMessageHistory
from pydantic import SecretStr

from app.core.config import get_settings
from app.models.briefing import BriefingExtracted, calculate_completude
from app.services import rag_service, alert_service
from app.services.metadata_tagger import DESTINO_KEYWORDS
from app.services.observability import get_callbacks_for_chain, flush_langfuse
from app.services.prompt_security import (
    EXTRACTION_SYSTEM_PROMPT_SECURE,
    build_system_prompt,
    sanitize_user_input,
    wrap_rag_context,
    wrap_user_content,
)

logger = structlog.get_logger()
settings = get_settings()

_llm: Optional[ChatOpenAI] = None
_MEMORY_WINDOW_K = 10  # Mantém as últimas 10 interações como contexto


# ---------------------------------------------------------------------------
# SimpleWindowMemory — drop-in replacement for ConversationBufferWindowMemory
# (removed in langchain 1.x)
# ---------------------------------------------------------------------------

class SimpleWindowMemory:
    """Stores the last k message pairs per conversation key.

    When the buffer overflows, removed pairs are queued for LLM summarisation
    so that older context is compressed instead of being lost entirely.
    """

    def __init__(self, k: int = 20, memory_key: str = "chat_history", return_messages: bool = True) -> None:
        self.k = k
        self.memory_key = memory_key
        self.return_messages = return_messages
        self._buffer: list[tuple[str, str]] = []
        self._summary: str = ""
        self._pending_for_summary: list[tuple[str, str]] = []

    def save_context(self, inputs: dict, outputs: dict) -> None:
        user_msg = inputs.get("input", "")
        ai_msg = outputs.get("output", "")
        self._buffer.append((user_msg, ai_msg))
        if len(self._buffer) > self.k:
            removed = self._buffer.pop(0)
            self._pending_for_summary.append(removed)

    def has_pending_summary(self) -> bool:
        return len(self._pending_for_summary) > 0

    async def compress_pending(self, llm: ChatGoogleGenerativeAI) -> None:
        """Summarise overflowed messages and merge into the running summary."""
        if not self._pending_for_summary:
            return

        conversation_text = "\n".join(
            f"Cliente: {u}\nAYA: {a}" for u, a in self._pending_for_summary
        )
        prompt = ChatPromptTemplate.from_messages([
            ("system", _SUMMARY_SYSTEM_PROMPT),
            ("human", conversation_text),
        ])
        chain = prompt | llm
        callbacks = get_callbacks_for_chain()
        config = {"callbacks": callbacks} if callbacks else {}

        try:
            response = await chain.ainvoke({}, config=config)
            summary_chunk = str(response.content).strip()
            if summary_chunk:
                if self._summary:
                    self._summary += f"\n{summary_chunk}"
                else:
                    self._summary = summary_chunk
                logger.info("memory_summary_generated", chars=len(summary_chunk))
        except Exception as exc:
            logger.warning("memory_summary_failed", error=str(exc))

        self._pending_for_summary = []

    def load_memory_variables(self, _inputs: dict) -> dict:
        messages = []
        if self._summary:
            messages.append({
                "role": "system",
                "content": f"Resumo da conversa anterior: {self._summary}",
            })
        for user_msg, ai_msg in self._buffer:
            messages.append({"role": "user", "content": user_msg})
            messages.append({"role": "assistant", "content": ai_msg})
        return {self.memory_key: messages}


_memories: dict[str, SimpleWindowMemory] = {}
_llm: Optional[ChatGoogleGenerativeAI] = None


def get_llm() -> ChatGoogleGenerativeAI:
    """Return LLM instance — Gemini exclusivo."""
    global _llm
    if _llm is None:
        if settings.GEMINI_API_KEY:
            _llm = ChatGoogleGenerativeAI(
                model="gemini-2.0-flash",
                temperature=0.3,
                timeout=25,
                max_retries=2,
                google_api_key=SecretStr(settings.GEMINI_API_KEY),
            )
            logger.info("llm_initialized", provider="google", model="gemini-2.0-flash")
        else:
            raise RuntimeError("Nenhuma GEMINI_API_KEY configurada. Defina GEMINI_API_KEY no .env")
    return _llm


def get_memory(phone: str) -> ConversationBufferWindowMemory:
    message_history = RedisChatMessageHistory(
        url=settings.REDIS_URL,
        ttl=86400, # 24 hours
        session_id=f"chat_history_{phone}"
    )
    return ConversationBufferWindowMemory(
        chat_memory=message_history,
        k=_MEMORY_WINDOW_K,
        memory_key="chat_history",
        return_messages=True
    )


def preload_memory_from_db(
    phone: str,
    interacoes: list[dict],
) -> None:
    """Populate conversation memory from persisted interacoes rows.

    Call this at the start of a conversation when memory is
    empty (e.g. after a server restart/cache clear) to restore the AI's context.

    Args:
        phone: Customer phone number (used as memory key).
        interacoes: List of dicts with keys 'mensagem_cliente' and
                    'mensagem_ia', ordered oldest-first.
    """
    memory = get_memory(phone)
    history = memory.load_memory_variables({})
    
    # If the history already has messages, we don't need to preload
    if history.get("chat_history"):
        return

    for row in interacoes[-_MEMORY_WINDOW_K:]:
        cliente = row.get("mensagem_cliente") or ""
        ia = row.get("mensagem_ia") or ""
        if cliente or ia:
            memory.save_context({"input": cliente}, {"output": ia})

    logger.info("memory_preloaded_from_db", phone=phone, rows=len(interacoes))


def _resolve_destino_tag(destino: Optional[str]) -> Optional[str]:
    """
    Map a free-text destination (from briefing) to a taxonomy tag for metadata filtering.
    Returns None if no category matches (avoids over-filtering).
    """
    if not destino:
        return None
    normalized = destino.lower()
    for category, keywords in DESTINO_KEYWORDS.items():
        if any(kw in normalized for kw in keywords):
            return category
    return None


def _resolve_perfil_tag(perfil: Optional[str]) -> Optional[str]:
    """Map briefing perfil enum value to metadata taxonomy tag."""
    if not perfil:
        return None
    _PERFIL_MAP = {
        "casal": "Casal",
        "família": "Família",
        "familia": "Família",
        "solo": "Solo",
        "grupo": "Grupo",
        "amigos": "Grupo",
    }
    return _PERFIL_MAP.get(perfil.lower())


def _retrieve_context(
    query: str,
    briefing: Optional[BriefingExtracted] = None,
) -> str:
    """
    Retrieve RAG context, applying metadata filters derived from current briefing.

    If the lead's briefing already contains destination/profile data, the retrieval
    is narrowed via hard-constraint metadata tags to keep context assertive.
    """
    try:
        destino_tag = _resolve_destino_tag(briefing.destino if briefing else None)
        perfil_tag = _resolve_perfil_tag(
            briefing.perfil.value if briefing and briefing.perfil else None
        )

        if destino_tag or perfil_tag:
            return rag_service.retrieve_with_metadata_filter(
                query,
                k=4,
                destino=destino_tag,
                perfil=perfil_tag,
            )
        return rag_service.retrieve_context(query, k=3)
    except Exception as exc:
        logger.warning("rag_retrieval_failed", error=str(exc))
        return ""


def _fallback_reply(message: str) -> str:
    return (
        f'Olá! Recebemos sua mensagem 😊\n\n'
        f'"{message}"\n\n'
        f'Em breve um consultor da Cadife Tour irá te atender pessoalmente.'
    )

def detect_hallucinations(response: str) -> list[str]:
    """Detect common hallucination patterns in AI response."""
    hallucinations = []
    # Patterns from implementation plan
    if re.search(r'(custa|preço|valor)\s*r\$\s*[\d.,]+', response, re.IGNORECASE):
        hallucinations.append("price_generated")
    if re.search(r'(disponível|reservo|confirmo sua vaga)', response, re.IGNORECASE):
        hallucinations.append("availability_confirmed")
    return hallucinations

async def process_message(
    phone: str,
    message: str,
    briefing: Optional[BriefingExtracted] = None,
    validation_errors: Optional[list[str]] = None,
) -> str:
    """Processa mensagem do cliente com a AYA.

    Args:
        phone: Telefone do cliente.
        message: Mensagem enviada pelo cliente.
        briefing: Briefing extraído da conversa atual para contextualizar o RAG.
        validation_errors: Lista opcional de erros de validação de domínio.
            Quando presente, a AYA é instruída a informar o cliente que
            a proposta contém inconsistências e pedir novos dados.
    """
    try:
        llm = get_llm()
        memory = get_memory(phone)

        # 1. Sanitizar entrada do usuário contra prompt injection
        safe_message = sanitize_user_input(message)
        if safe_message != message:
            logger.warning("user_input_sanitized", phone=phone)

        context = _retrieve_context(safe_message, briefing)

        # 2. Montar system prompt parametrizado com isoladores textuais
        system_prompt = build_system_prompt(context=wrap_rag_context(context))

        # 3. Se houver erros de validação, injeta instrução corretiva no prompt
        if validation_errors:
            errors_text = "\n".join(f"- {e}" for e in validation_errors)
            system_prompt += f"""

ATENÇÃO — INSTRUÇÃO CORRETIVA OBRIGATÓRIA:
O sistema de validação detectou que os dados informados pelo cliente contêm inconsistências:
{errors_text}

Você DEVE:
1. Informar o cliente de forma educada e natural que a proposta atual não é viável
2. Explicar brevemente o motivo (sem mencionar valores específicos)
3. Pedir que ele forneça novos dados coerentes para que possamos montar uma proposta adequada
4. Manter o tom consultivo e acolhedor — nunca culpar o cliente"""

            logger.info(
                "validation_correction_injected",
                phone=phone,
                errors=validation_errors,
            )

        prompt = ChatPromptTemplate.from_messages([
            ("system", system_prompt),
            MessagesPlaceholder(variable_name="chat_history"),
            ("human", wrap_user_content("{input}")),
        ])

        chain = prompt | llm
        history = memory.load_memory_variables({})

        # Observabilidade: rastrear chain no Langfuse (se configurado)
        callbacks = get_callbacks_for_chain()
        config = {"callbacks": callbacks} if callbacks else {}

        start_time = time.time()
        response = await chain.ainvoke({
            "chat_history": history.get("chat_history", []),
            "input": safe_message,
        }, config=config)
        latency_ms = int((time.time() - start_time) * 1000)

        response_content = str(response.content)
        hallucinations = detect_hallucinations(response_content)
        
        if hallucinations:
            logger.warning(
                "hallucination_detected",
                phone=phone,
                hallucinations=hallucinations,
                response_snippet=response_content[:100]
            )
            await alert_service.AlertService.notify_hallucination(
                phone, hallucinations, response_content[:100]
            )

        memory.save_context({"input": safe_message}, {"output": response_content})
        
        logger.info(
            "ai_message_processed",
            phone=phone,
            latency_ms=latency_ms,
            response_length=len(response_content),
            hallucination_count=len(hallucinations)
        )

        # Flush eventos Langfuse pendentes (não bloqueante)
        flush_langfuse()

        return response_content

    except Exception as exc:
        logger.error("ai_chain_error", phone=phone, error=str(exc))
        return _fallback_reply(message)


async def extract_briefing(conversation: list[dict]) -> BriefingExtracted:
    """Extrai briefing de viagem com fallback chain de autocorreção.

    Estratégia:
      1. Tentativa primária: structured_output nativo do LLM
      2. Fallback: se structured_output falhar (JSON malformado, schema mismatch),
         usa um prompt de autocorreção com LLM mais simples/robusto
      3. Último recurso: retorna BriefingExtracted vazio (seguro, sem crash)

    Args:
        conversation: Lista de dicts com keys 'role' e 'content'.

    Returns:
        Instância de BriefingExtracted, possivelmente vazia.
    """
    if not settings.GEMINI_API_KEY:
        return BriefingExtracted()

    # Sanitizar conversa antes de enviar à extração
    safe_conversation = []
    for msg in conversation:
        safe_msg = dict(msg)
        safe_msg["content"] = sanitize_user_input(msg.get("content", ""))
        safe_conversation.append(safe_msg)

    conversation_text = "\n".join(
        f"{msg['role'].upper()}: {msg['content']}" for msg in safe_conversation
    )

    llm = get_llm()

    callbacks = get_callbacks_for_chain()
    config = {"callbacks": callbacks} if callbacks else {}

    # -----------------------------------------------------------------------
    # TENTATIVA 1 — Structured Output nativo
    # -----------------------------------------------------------------------
    try:
        structured_llm = llm.with_structured_output(BriefingExtracted)

        prompt = ChatPromptTemplate.from_messages([
            ("system", EXTRACTION_SYSTEM_PROMPT_SECURE),
            ("human", "Extraia o briefing da seguinte conversa:\n\n{conversation}"),
        ])

        chain = prompt | structured_llm
        briefing = await chain.ainvoke(
            {"conversation": conversation_text},
            config=config,
        )

        briefing_data = briefing.model_dump()
        completude = calculate_completude(briefing_data)
        logger.info(
            "briefing_extracted_structured",
            completude=completude,
            fields_filled=[k for k, v in briefing_data.items() if v not in (None, [], "")],
        )
        flush_langfuse()
        return briefing

    except Exception as exc_primary:
        logger.warning(
            "briefing_extraction_primary_failed",
            error=str(exc_primary),
            error_type=type(exc_primary).__name__,
        )

    # -----------------------------------------------------------------------
    # TENTATIVA 2 — Fallback: autocorreção com prompt explícito (Gemini)
    # -----------------------------------------------------------------------
    try:
        # Usa Gemini com temperatura 0 para máxima determinismo na correção
        fallback_llm = ChatGoogleGenerativeAI(
            model="gemini-2.0-flash",
            temperature=0.0,
            timeout=15,
            max_retries=1,
            google_api_key=SecretStr(settings.GEMINI_API_KEY) if settings.GEMINI_API_KEY else None,
        )

        autocorrect_prompt = ChatPromptTemplate.from_messages([
            ("system", """Você é um extrator de dados JSON de alta precisão. Sua tarefa é transformar a conversa fornecida em um objeto JSON válido.

REGRAS RÍGIDAS:
1. JSON PURO: Retorne APENAS o JSON. Sem explicações, sem markdown, sem texto antes ou depois.
2. ZERO INFERÊNCIA: Se a informação não estiver na conversa, use null.
3. FORMATO DE DATA: Use estritamente YYYY-MM-DD para datas.
4. PERFIL: Use apenas: casal, família, solo, grupo, amigos.
5. ORÇAMENTO: Use apenas: baixo, médio, alto, premium.

SCHEMA:
{{
  "destino": "string ou null",
  "data_ida": "YYYY-MM-DD ou null",
  "data_volta": "YYYY-MM-DD ou null",
  "qtd_pessoas": "int ou null",
  "perfil": "string ou null",
  "tipo_viagem": ["string"],
  "preferencias": ["string"],
  "orcamento": "string ou null",
  "tem_passaporte": "bool ou null",
  "observacoes": "string ou null"
}}"""),
            ("human", "Converta esta conversa em JSON seguindo as regras:\n{conversation}"),
        ])

        autocorrect_chain = autocorrect_prompt | fallback_llm
        response = await autocorrect_chain.ainvoke(
            {"conversation": conversation_text},
            config=config,
        )
        raw_json = str(response.content).strip()

        # Limpeza robusta de Markdown e ruídos
        # Remove blocos de código markdown se existirem
        if "```" in raw_json:
            match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", raw_json, re.DOTALL)
            if match:
                raw_json = match.group(1)
            else:
                # Fallback: remove apenas os delimitadores
                raw_json = re.sub(r"```(?:json)?", "", raw_json).strip()
                raw_json = re.sub(r"```$", "", raw_json).strip()

        parsed = json.loads(raw_json)
        briefing = BriefingExtracted.model_validate(parsed)

        briefing_data = briefing.model_dump()
        completude = calculate_completude(briefing_data)
        logger.info(
            "briefing_extracted_fallback_autocorrect",
            completude=completude,
            fields_filled=[k for k, v in briefing_data.items() if v not in (None, [], "")],
        )
        flush_langfuse()
        return briefing

    except Exception as exc_fallback:
        logger.error(
            "briefing_extraction_fallback_failed",
            error=str(exc_fallback),
            error_type=type(exc_fallback).__name__,
        )

    # -----------------------------------------------------------------------
    # TENTATIVA 3 — Último recurso: retorno seguro vazio
    # -----------------------------------------------------------------------
    logger.error("briefing_extraction_all_attempts_failed", returning_empty=True)
    flush_langfuse()
    return BriefingExtracted()
