from typing import Optional

import structlog
from langchain_classic.memory import ConversationBufferWindowMemory
from langchain_core.output_parsers import PydanticOutputParser
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder, PromptTemplate
from langchain.memory import ConversationBufferWindowMemory
from langchain.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_openai import ChatOpenAI
from pydantic import SecretStr

from app.core.config import get_settings
from app.models.briefing import BriefingExtracted, calculate_completude
from app.services import rag_service
from app.services.metadata_tagger import DESTINO_KEYWORDS, PERFIL_KEYWORDS

logger = structlog.get_logger()
settings = get_settings()

# System prompt imutável — conforme .claude/rules/ai_langchain.md
AYA_SYSTEM_PROMPT = """Você é AYA, assistente virtual da Cadife Tour — agência especializada em curadoria personalizada de viagens.
Tom: consultivo e próximo, 80% consultor / 20% vendedor. Linguagem natural, clara, educada e não invasiva.

PROIBIÇÕES ABSOLUTAS — nunca viole estas regras:
- Nunca mencione preços, valores, estimativas financeiras ou condições de pagamento
- Nunca confirme disponibilidade de voos, hotéis ou passeios
- Nunca feche vendas, faça promessas comerciais ou comprometa a empresa
- Nunca tome decisões comerciais críticas de forma autônoma

COMPORTAMENTO OBRIGATÓRIO:
- Sempre indique que o consultor humano irá validar as informações
- Mantenha respostas abertas: "Vou repassar isso ao nosso consultor para ele te orientar melhor"
- Preserve tom humano e natural — o cliente não deve perceber que é automação
- Faça uma pergunta por vez para não sobrecarregar o cliente

OBJETIVO: Coletar o briefing completo da viagem de forma natural e amigável.

Contexto da Cadife Tour (base de conhecimento):
{context}"""

EXTRACTION_SYSTEM_PROMPT = """Com base na conversa abaixo, extraia os dados do briefing de viagem.
Preencha APENAS os campos que o cliente mencionou explicitamente.
NÃO infira dados que não foram ditos.

Conversa:
{conversation}"""

_memories: dict[str, ConversationBufferWindowMemory] = {}
_llm: Optional[ChatOpenAI] = None


def get_llm() -> ChatOpenAI:
    global _llm
    if _llm is None:
        _llm = ChatOpenAI(
            model="gpt-4o-mini",
            temperature=0.3,
            timeout=25,
            max_retries=2,
            api_key=SecretStr(settings.OPENAI_API_KEY),
        )
    return _llm


def get_memory(phone: str) -> ConversationBufferWindowMemory:
    if phone not in _memories:
        _memories[phone] = ConversationBufferWindowMemory(
            k=20,
            memory_key="chat_history",
            return_messages=True,
        )
    return _memories[phone]


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


FALLBACK_REPLY = (
    "Olá! Recebemos sua mensagem. "
    "Em breve um consultor da Cadife Tour irá te atender. 😊"
)

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
        context = _retrieve_context(message, briefing)

        system_prompt = AYA_SYSTEM_PROMPT

        # Se houver erros de validação, injeta instrução corretiva no prompt
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
            ("human", "{input}"),
        ])

        chain = prompt | llm
        history = memory.load_memory_variables({})
        response = await chain.ainvoke({
            "context": context,
            "chat_history": history.get("chat_history", []),
            "input": message,
        })

        memory.save_context({"input": message}, {"output": str(response.content)})
        logger.info("ai_message_processed", phone=phone)
        return str(response.content)

    except Exception as exc:
        logger.error("ai_chain_error", phone=phone, error=str(exc))
        return "Desculpe, estou com uma instabilidade momentânea. Nossa equipe entrará em contato em breve!"


async def extract_briefing(conversation: list[dict]) -> BriefingExtracted:
    if not settings.OPENAI_API_KEY:
        return BriefingExtracted()

    try:
        llm = get_llm()
        structured_llm = llm.with_structured_output(BriefingExtracted)

        conversation_text = "\n".join(
            f"{msg['role'].upper()}: {msg['content']}" for msg in conversation
        )

        prompt = ChatPromptTemplate.from_messages([
            ("system", EXTRACTION_SYSTEM_PROMPT),
        ])

        chain = prompt | structured_llm
        briefing = await chain.ainvoke({"conversation": conversation_text})

        briefing_data = briefing.model_dump()
        completude = calculate_completude(briefing_data)
        logger.info(
            "briefing_extracted_structured",
            completude=completude,
            fields_filled=[k for k, v in briefing_data.items() if v not in (None, [], "")],
        )
        return briefing

    except Exception as exc:
        logger.error("briefing_extraction_error", error=str(exc))
        return BriefingExtracted()
