"""
Infrastructure Layer — Rate Limiter Setup
Configuração do slowapi com backend Redis para rate limiting global por IP.

Thresholds ajustáveis via variáveis de ambiente (Settings):
  - RATE_LIMIT_WEBHOOK : padrão "100/minute"
  - RATE_LIMIT_IA      : padrão "30/minute"
  - RATE_LIMIT_DEFAULT : padrão "60/minute"

Uso nas rotas:
    from app.infrastructure.security.rate_limiter import limiter

    @router.post("/webhook/whatsapp")
    @limiter.limit(settings.RATE_LIMIT_WEBHOOK)
    async def webhook(request: Request): ...
"""

import structlog
from fastapi import Request
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.core.config import get_settings

logger = structlog.get_logger()
settings = get_settings()


def get_wa_id_from_webhook(request: Request) -> str:
    """
    Extrai wa_id (telefone) do payload WhatsApp para usar como chave de rate limit.
    Fallback para IP quando wa_id não estiver disponível (ex: verificação de challenge).

    O webhook da Meta sempre vem do mesmo IP — usar IP como chave faria com que
    todos os clientes da Cadife compartilhassem o mesmo bucket de rate limit.
    """
    try:
        # request._json é populado se o body já foi lido anteriormente
        body = getattr(request, "_json", None)
        if body:
            entry = body.get("entry", [{}])[0]
            changes = entry.get("changes", [{}])[0]
            value = changes.get("value", {})
            messages = value.get("messages", [])
            if messages:
                return messages[0].get("from", get_remote_address(request))
    except Exception:
        pass
    return get_remote_address(request)


try:
    limiter = Limiter(
        key_func=get_remote_address,
        storage_uri=settings.REDIS_URL,
        default_limits=[settings.RATE_LIMIT_DEFAULT],
        headers_enabled=True,
        swallow_errors=True,
        key_prefix=settings.REDIS_PREFIX if settings.REDIS_PREFIX else "LIMITER",
        # When Redis dies after startup, __evaluate_limits raises before setting
        # request.state.view_rate_limit; swallow_errors absorbs the exception but
        # SlowAPIMiddleware still expects the attribute → AttributeError crash.
        # in_memory_fallback triggers a retry with memory storage on the first Redis
        # failure, ensuring __evaluate_limits always completes and sets view_rate_limit.
        in_memory_fallback=[settings.RATE_LIMIT_DEFAULT],
    )
    logger.info("rate_limiter_ready", storage=settings.REDIS_URL)
except Exception as exc:
    # Redis indisponível no startup — usa memória local (não compartilhada entre workers)
    logger.warning(
        "rate_limiter_redis_unavailable", error=str(exc), fallback="memory://"
    )
    limiter = Limiter(
        key_func=get_remote_address,
        storage_uri="memory://",
        default_limits=[settings.RATE_LIMIT_DEFAULT],
        headers_enabled=True,
        swallow_errors=True,
    )
