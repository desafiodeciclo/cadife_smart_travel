from typing import Optional

import structlog
from langchain.memory import ConversationBufferWindowMemory
from langchain.output_parsers import PydanticOutputParser
from langchain.prompts import ChatPromptTemplate, MessagesPlaceholder, PromptTemplate
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


async def process_message(phone: str, message: str) -> str:
    try:
        llm = get_llm()
        memory = get_memory(phone)
        context = _retrieve_context(message)

        prompt = ChatPromptTemplate.from_messages([
            ("system", AYA_SYSTEM_PROMPT),
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
    parser = PydanticOutputParser(pydantic_object=BriefingExtracted)

    extraction_prompt = PromptTemplate(
        template="""Com base na conversa abaixo, extraia os dados do briefing de viagem.
Preencha APENAS os campos que o cliente mencionou explicitamente.
NÃO infira dados que não foram ditos.

Conversa:
{conversation}

{format_instructions}""",
        input_variables=["conversation"],
        partial_variables={"format_instructions": parser.get_format_instructions()},
    )

    try:
        llm = get_llm()
        conversation_text = "\n".join(
            f"{msg['role'].upper()}: {msg['content']}" for msg in conversation
        )
        prompt_value = extraction_prompt.format(conversation=conversation_text)
        response = await llm.ainvoke(prompt_value)
        briefing = parser.parse(response.content)
        briefing.completude_pct = calculate_completude(briefing.model_dump())
        return briefing
    except Exception as exc:
        logger.error("briefing_extraction_error", error=str(exc))
        return BriefingExtracted()
