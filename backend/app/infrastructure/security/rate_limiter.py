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
        swallow_errors=False,
    )
    logger.info("rate_limiter_ready", storage=settings.REDIS_URL)
except Exception as exc:
    # Redis indisponível — usa memória local (não compartilhada entre workers)
    logger.warning("rate_limiter_redis_unavailable", error=str(exc), fallback="memory://")
    limiter = Limiter(
        key_func=get_remote_address,
        storage_uri="memory://",
        default_limits=[settings.RATE_LIMIT_DEFAULT],
        headers_enabled=True,
        swallow_errors=True,
    )
