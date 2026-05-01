"""
Observability — Integração Langfuse para rastreamento de chains LangChain.

Fornece callbacks condicionais: quando LANGFUSE_PUBLIC_KEY e
LANGFUSE_SECRET_KEY estão configurados, todas as invocações de chain
são rastreadas automaticamente com prompt, contexto, output e latência.

Quando não configurado, opera em modo silencioso (no-op) sem afetar
performance ou quebrar o fluxo.
"""

from typing import Optional

import structlog

from app.core.config import get_settings

logger = structlog.get_logger()
settings = get_settings()

# Lazy-import para evitar erro se langfuse não estiver instalado
_langfuse_handler: Optional[object] = None
_langfuse_available: Optional[bool] = None


def _is_langfuse_available() -> bool:
    """Verifica se o pacote langfuse está instalado."""
    global _langfuse_available
    if _langfuse_available is None:
        try:
            import langfuse  # noqa: F401
            _langfuse_available = True
        except ImportError:
            _langfuse_available = False
            logger.debug("langfuse_not_installed")
    return _langfuse_available


def _has_langfuse_credentials() -> bool:
    """Verifica se as credenciais estão configuradas no ambiente."""
    return bool(
        getattr(settings, "LANGFUSE_PUBLIC_KEY", "")
        and getattr(settings, "LANGFUSE_SECRET_KEY", "")
    )


def get_langfuse_callback() -> Optional[object]:
    """
    Retorna um Langfuse CallbackHandler configurado, ou None se:
      - langfuse não estiver instalado, OU
      - credenciais não estiverem configuradas.

    O handler pode ser passado diretamente para chain.invoke(..., config={"callbacks": [handler]})
    ou usado com o pattern de env var LANGFUSE_PUBLIC_KEY/LANGFUSE_SECRET_KEY.

    Returns:
        Instância de langfuse.callback.LangchainCallbackHandler ou None.
    """
    global _langfuse_handler

    if _langfuse_handler is not None:
        return _langfuse_handler

    if not _is_langfuse_available():
        return None

    if not _has_langfuse_credentials():
        logger.debug("langfuse_credentials_missing")
        return None

    try:
        from langfuse.langchain import CallbackHandler

        host = getattr(settings, "LANGFUSE_HOST", "https://cloud.langfuse.com")
        _langfuse_handler = CallbackHandler(
            public_key=settings.LANGFUSE_PUBLIC_KEY,
            secret_key=settings.LANGFUSE_SECRET_KEY,
            host=host,
        )
        logger.info(
            "langfuse_callback_initialized",
            host=host,
            public_key_prefix=settings.LANGFUSE_PUBLIC_KEY[:8],
        )
        return _langfuse_handler
    except Exception as exc:
        logger.warning("langfuse_callback_init_failed", error=str(exc))
        return None


def get_callbacks_for_chain() -> list[object]:
    """
    Retorna uma lista de callbacks para uso em chains LangChain.

    Example:
        callbacks = get_callbacks_for_chain()
        response = await chain.ainvoke(input_dict, config={"callbacks": callbacks})
    """
    handler = get_langfuse_callback()
    return [handler] if handler is not None else []


def flush_langfuse() -> None:
    """
    Força o flush de eventos pendentes para o servidor Langfuse.
    Útil chamar antes de encerrar o processo ou BackgroundTask.
    """
    global _langfuse_handler
    if _langfuse_handler is not None:
        try:
            _langfuse_handler.flush()
            logger.debug("langfuse_flushed")
        except Exception as exc:
            logger.warning("langfuse_flush_failed", error=str(exc))
