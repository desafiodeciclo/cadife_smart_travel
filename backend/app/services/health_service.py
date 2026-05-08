"""
Health Service — Readiness/Liveness Check Logic
==============================================
Provides functions to verify connectivity with critical infrastructure
(PostgreSQL and Redis) as required by K8S probes.
"""
import structlog
from redis import asyncio as aioredis
from sqlalchemy import text
from app.infrastructure.persistence.database import engine
from app.infrastructure.config.settings import get_settings

logger = structlog.get_logger()
settings = get_settings()


async def check_database() -> bool:
    """Verifica se a conexão com o banco de dados está ativa."""
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        return True
    except Exception as exc:
        logger.error("health_check_database_failed", error=str(exc))
        return False


async def check_redis() -> bool:
    """Verifica se a conexão com o Redis está ativa."""
    try:
        redis = await aioredis.from_url(settings.REDIS_URL, socket_timeout=2)
        await redis.ping()
        await redis.close()
        return True
    except Exception as exc:
        logger.error("health_check_redis_failed", error=str(exc))
        return False
