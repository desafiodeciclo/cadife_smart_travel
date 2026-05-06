"""
Redis Cache Client — Infrastructure/Cache Layer
==================================================
Async Redis client singleton with health-check helper.
Used by the @cached decorator and explicit invalidation calls.
"""
from __future__ import annotations

import structlog
from redis.asyncio import Redis, from_url

from app.infrastructure.config.settings import get_settings

logger = structlog.get_logger()
_settings = get_settings()


class _RedisClient:
    """Lazy-initialized async Redis client."""

    _instance: Redis | None = None

    @classmethod
    def get(cls) -> Redis:
        if cls._instance is None:
            cls._instance = from_url(
                _settings.REDIS_URL,
                decode_responses=True,
            )
            logger.info("redis_client_initialized", url=_settings.REDIS_URL)
        return cls._instance

    @classmethod
    async def close(cls) -> None:
        if cls._instance is not None:
            await cls._instance.close()
            cls._instance = None
            logger.info("redis_client_closed")

    @classmethod
    async def health(cls) -> bool:
        try:
            client = cls.get()
            await client.ping()
            return True
        except Exception as exc:
            logger.warning("redis_health_check_failed", error=str(exc))
            return False


def get_redis() -> Redis:
    """Return the shared async Redis client."""
    return _RedisClient.get()
