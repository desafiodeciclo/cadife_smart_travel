import structlog
from typing import Optional
from langchain_openai import ChatOpenAI
from app.infrastructure.config.settings import get_settings

logger = structlog.get_logger()
settings = get_settings()

_llm: Optional[ChatOpenAI] = None

def get_llm() -> ChatOpenAI:
    """Return LLM instance via OpenRouter."""
    global _llm
    if _llm is None:
        if not settings.OPENROUTER_API_KEY:
            raise RuntimeError(
                "Nenhuma OPENROUTER_API_KEY configurada. Defina OPENROUTER_API_KEY no .env"
            )
        _llm = ChatOpenAI(
            model=settings.OPENROUTER_MODEL,
            temperature=0.3,
            timeout=25,
            max_retries=2,
            openai_api_key=settings.OPENROUTER_API_KEY,
            openai_api_base="https://openrouter.ai/api/v1",
            default_headers={
                "HTTP-Referer": "https://cadifetour.com",
                "X-Title": "Cadife Smart Travel",
            },
        )
        logger.info(
            "llm_initialized", provider="openrouter", model=settings.OPENROUTER_MODEL
        )
    return _llm
