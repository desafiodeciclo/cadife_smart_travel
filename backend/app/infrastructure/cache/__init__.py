"""
Cache Layer — Public API
========================
Re-export Redis client and caching utilities for consumption by
other infrastructure modules and route handlers.
"""
from app.infrastructure.cache.decorator import cached, invalidate_pattern
from app.infrastructure.cache.redis_client import get_redis, _RedisClient

__all__ = ["cached", "get_redis", "invalidate_pattern", "_RedisClient"]
