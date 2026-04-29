from typing import Optional

import structlog
from langchain.memory import ConversationBufferWindowMemory
from langchain.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_openai import ChatOpenAI

from app.core.config import get_settings
from app.models.briefing import BriefingExtracted, calculate_completude
from app.services.rag_service import get_vectorstore

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
            request_timeout=25,
            max_retries=2,
            openai_api_key=settings.OPENAI_API_KEY,
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


def _retrieve_context(query: str) -> str:
    try:
        vs = get_vectorstore()
        docs = vs.similarity_search(query, k=3)
        return "\n\n".join(d.page_content for d in docs)
    except Exception as exc:
        logger.warning("rag_retrieval_failed", error=str(exc))
        return ""


async def process_message(
    phone: str,
    message: str,
    validation_errors: Optional[list[str]] = None,
) -> str:
    """Processa mensagem do cliente com a AYA.

    Args:
        phone: Telefone do cliente.
        message: Mensagem enviada pelo cliente.
        validation_errors: Lista opcional de erros de validação de domínio.
            Quando presente, a AYA é instruída a informar o cliente que
            a proposta contém inconsistências e pedir novos dados.
    """
    try:
        llm = get_llm()
        memory = get_memory(phone)
        context = _retrieve_context(message)

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

        memory.save_context({"input": message}, {"output": response.content})
        logger.info("ai_message_processed", phone=phone)
        return response.content

    except Exception as exc:
        logger.error("ai_chain_error", phone=phone, error=str(exc))
        return "Desculpe, estou com uma instabilidade momentânea. Nossa equipe entrará em contato em breve!"


async def extract_briefing(conversation: list[dict]) -> BriefingExtracted:
    """Extrai dados do briefing usando Structured Outputs API.

    Utiliza llm.with_structured_output() para garantir que a resposta
    da IA sempre respeite o schema Pydantic definido em BriefingExtracted.
    """
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
