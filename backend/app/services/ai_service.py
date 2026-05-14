import time
from typing import Optional, Any
from datetime import datetime

from langchain_core.messages import HumanMessage, SystemMessage, BaseMessage
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.output_parsers import JsonOutputParser
from pydantic import BaseModel, Field

from app.infrastructure.config.settings import get_settings
settings = get_settings()
from app.services.memory_service import SimpleWindowMemory
from app.services.rag_service import retrieve_context
from app.services.briefing_service import extract_briefing_structured
from app.core.logging import get_logger
from app.core.langfuse_config import langfuse_context

logger = get_logger(__name__)

# --- Configurações de Memória ---
_memories: dict[str, SimpleWindowMemory] = {}
_memory_last_access: dict[str, float] = {}
_MEMORY_TTL_SECONDS = 3600 * 4  # 4 horas de inatividade
_MEMORY_WINDOW_K = 20

def _evict_stale_memories() -> None:
    """Remove memórias que não são acessadas há mais de 4 horas."""
    now = time.time()
    stale = [k for k, t in _memory_last_access.items() if now - t > _MEMORY_TTL_SECONDS]
    for k in stale:
        _memories.pop(k, None)
        _memory_last_access.pop(k, None)
    if stale:
        logger.info("memory_evicted", count=len(stale))

def get_memory(phone: str) -> SimpleWindowMemory:
    """Recupera ou cria a memória para um usuário específico."""
    _evict_stale_memories()
    if phone not in _memories:
        _memories[phone] = SimpleWindowMemory(
            k=_MEMORY_WINDOW_K,
            memory_key="chat_history",
            return_messages=True,
        )
    _memory_last_access[phone] = time.time()
    return _memories[phone]

# --- Modelos de Dados ---
class BriefingSchema(BaseModel):
    destinos: list[str] = Field(default_factory=list)
    orcamento: Optional[str] = None
    data_viagem: Optional[str] = None
    num_passageiros: Optional[int] = None
    interesses: list[str] = Field(default_factory=list)

# --- Classe Principal do Serviço ---
class AyaService:
    def __init__(self):
        # Inicializa o modelo via OpenRouter/OpenAI
        self.llm = ChatOpenAI(
            model=settings.OPENROUTER_MODEL,
            openai_api_key=settings.OPENROUTER_API_KEY,
            openai_api_base="https://openrouter.ai/api/v1",
            temperature=0.7
        )

    async def process_message(self, phone: str, message_text: str) -> str:
        """
        Processa a mensagem do usuário: Busca contexto, atualiza memória e gera resposta.
        """
        memory = get_memory(phone)
        chat_history = memory.load_memory_variables({})["chat_history"]

        # 1. Recuperar Contexto Relevante (RAG)
        context = await retrieve_context(message_text)

        # 2. Preparar o Prompt
        prompt = ChatPromptTemplate.from_messages([
            ("system", settings.AYA_SYSTEM_PROMPT),
            MessagesPlaceholder(variable_name="chat_history"),
            ("system", f"CONTEXTO RELEVANTE:\n{context}"),
            ("human", "{input}")
        ])

        chain = prompt | self.llm

        try:
            # 3. Gerar Resposta com Trace do Langfuse
            response = await chain.ainvoke(
                {"input": message_text, "chat_history": chat_history},
                config={"callbacks": [langfuse_context.get_callback_handler()]}
            )
            
            response_content = response.content

            # 4. Salvar na Memória
            memory.save_context({"input": message_text}, {"output": response_content})

            return response_content

        except Exception as e:
            logger.error("error_generating_response", phone=phone, error=str(e))
            return "Desculpe, tive um probleminha técnico. Pode repetir?"

    async def extract_briefing(self, phone: str) -> BriefingSchema:
        """
        Analisa o histórico e extrai os dados estruturados da viagem.
        """
        memory = get_memory(phone)
        chat_history = memory.load_memory_variables({})["chat_history"]
        
        if not chat_history:
            return BriefingSchema()

        # Chama o serviço especializado em extração
        return await extract_briefing_structured(chat_history, self.llm)

    def detect_hallucinations(self, text: str) -> bool:
        """
        Verifica se a IA mencionou preços fixos ou informações sensíveis proibidas.
        """
        import re
        # Exemplo simples: bloquear menção a valores em R$ se não houver contexto real
        price_pattern = r"R\$\s?\d+"
        if re.search(price_pattern, text):
            # Lógica personalizada aqui
            return True
        return False

# NOTE: Não instanciar AyaService no import para evitar erro sem OPENAI_API_KEY.
# Quem precisar, cria a instância manualmente: aya = AyaService()