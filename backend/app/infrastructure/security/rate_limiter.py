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
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.core.config import get_settings

logger = structlog.get_logger()
settings = get_settings()

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
