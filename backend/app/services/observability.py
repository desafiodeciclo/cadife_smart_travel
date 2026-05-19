"""
Observability — Integração LangSmith para rastreamento de chains LangChain.

Quando LANGCHAIN_TRACING_V2=true e LANGCHAIN_API_KEY estão configurados,
todas as invocações de chain são rastreadas automaticamente no LangSmith
com prompt, contexto, output e latência.

O LangSmith opera via variáveis de ambiente nativas do LangChain — não requer
callbacks explícitos. Este módulo garante que as variáveis sejam propagadas
para o os.environ antes do primeiro uso.

Quando não configurado, opera em modo silencioso (no-op) sem afetar
performance ou quebrar o fluxo.
"""

import os

import structlog

from app.core.config import get_settings

logger = structlog.get_logger()
settings = get_settings()


def _setup_langsmith_env() -> bool:
    """
    Propaga as configurações LangSmith do Settings para os.environ.
    Retorna True se o tracing está ativo.
    """
    api_key = getattr(settings, "LANGCHAIN_API_KEY", "")
    tracing = getattr(settings, "LANGCHAIN_TRACING_V2", "false")
    project = getattr(settings, "LANGCHAIN_PROJECT", "cadife-smart-travel")
    endpoint = getattr(settings, "LANGCHAIN_ENDPOINT", "https://api.smith.langchain.com")

    if not api_key or str(tracing).lower() != "true":
        return False

    os.environ.setdefault("LANGCHAIN_API_KEY", api_key)
    os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
    os.environ.setdefault("LANGCHAIN_PROJECT", project)
    os.environ.setdefault("LANGCHAIN_ENDPOINT", endpoint)

    return True


# Inicializa ao importar o módulo
_tracing_active = _setup_langsmith_env()
if _tracing_active:
    logger.info(
        "langsmith_tracing_enabled",
        project=os.environ.get("LANGCHAIN_PROJECT"),
        endpoint=os.environ.get("LANGCHAIN_ENDPOINT"),
    )
else:
    logger.debug("langsmith_tracing_disabled")


def get_callbacks_for_chain() -> list[object]:
    """
    Retorna lista de callbacks para uso em chains LangChain.

    Com LangSmith, o tracing é automático via variáveis de ambiente —
    callbacks explícitos não são necessários. Retorna lista vazia.

    Example:
        callbacks = get_callbacks_for_chain()
        response = await chain.ainvoke(input_dict, config={"callbacks": callbacks})
    """
    return []


def flush_langsmith() -> None:
    """
    No-op: LangSmith envia traces de forma assíncrona automaticamente.
    Mantido para compatibilidade de chamada nos pontos críticos do fluxo.
    """
    if _tracing_active:
        logger.debug("langsmith_flush_noop")
