"""
Cache Decorator — Infrastructure/Cache Layer
==============================================
Async decorator that caches function results in Redis with a configurable TTL.

Intended for idempotent read operations (e.g. GET /leads, GET /leads/{id}).
The cached value is stored as a JSON string; on cache hit the JSON is
parsed back into a plain dict/list so FastAPI can re-validate it against
the declared response_model.

Usage:
    @cached(ttl=300)
    async def list_leads(...) -> LeadListResponse:
        ...
"""
from __future__ import annotations

import functools
import hashlib
import json
from typing import Any, Callable, TypeVar

from fastapi.encoders import jsonable_encoder
from pydantic import BaseModel

from app.infrastructure.cache.redis_client import get_redis
from app.infrastructure.config.settings import get_settings

_settings = get_settings()

F = TypeVar("F", bound=Callable[..., Any])


def _make_cache_key(func_name: str, args: tuple, kwargs: dict) -> str:
    """Deterministic cache key from function name + arguments."""
    # Normalise kwargs order and stringify
    payload = json.dumps({
        "fn": func_name,
        "args": [str(a) for a in args],
        "kwargs": {k: str(v) for k, v in sorted(kwargs.items())},
    }, sort_keys=True, ensure_ascii=False)
    hash_part = hashlib.sha256(payload.encode()).hexdigest()[:32]
    prefix = _settings.REDIS_PREFIX or "CACHE"
    return f"{prefix}:cached:{func_name}:{hash_part}"


def _serialize(value: Any) -> str:
    """Serialize a return value to JSON string."""
    if isinstance(value, BaseModel):
        # Pydantic v2 — model_dump returns dict; we JSON-encode it
        data = value.model_dump(mode="json")
    else:
        data = jsonable_encoder(value)
    return json.dumps(data, ensure_ascii=False, default=str)


def _deserialize(raw: str) -> Any:
    """Deserialize JSON string back to Python object."""
    return json.loads(raw)


def cached(ttl: int | None = None) -> Callable[[F], F]:
    """
    Async decorator that caches the wrapped function's return value in Redis.

    Args:
        ttl: Time-to-live in seconds. Defaults to Settings.CACHE_TTL_SECONDS.
    """
    if ttl is None:
        ttl = _settings.CACHE_TTL_SECONDS

    def decorator(func: F) -> F:
        @functools.wraps(func)
        async def async_wrapper(*args: Any, **kwargs: Any) -> Any:
            if not _settings.CACHE_ENABLED:
                return await func(*args, **kwargs)

            redis = get_redis()
            key = _make_cache_key(func.__qualname__, args, kwargs)

            try:
                cached_raw = await redis.get(key)
                if cached_raw is not None:
                    return _deserialize(cached_raw)
            except Exception:
                # Redis down or error — degrade gracefully to direct execution
                pass

            result = await func(*args, **kwargs)

            try:
                await redis.setex(key, ttl, _serialize(result))
            except Exception:
                # Best-effort cache write
                pass

            return result

        # Expose cache helpers so callers can invalidate explicitly if needed
        async_wrapper.cache_invalidate = lambda **kw: _invalidate(func.__qualname__, **kw)  # type: ignore[attr-defined]
        async_wrapper.cache_key = lambda *a, **kw: _make_cache_key(func.__qualname__, a, kw)  # type: ignore[attr-defined]

        return async_wrapper  # type: ignore[return-value]

    return decorator


async def _invalidate(func_name: str, **kwargs: Any) -> None:
    """Invalidate a specific cache key for a decorated function."""
    redis = get_redis()
    key = _make_cache_key(func_name, (), kwargs)
    try:
        await redis.delete(key)
    except Exception:
        pass


async def invalidate_pattern(pattern: str) -> int:
    """
    Invalidate all cache keys matching a Redis pattern (e.g. CACHE:cached:list_leads:*).
    Returns the number of keys deleted.
    """
    redis = get_redis()
    prefix = _settings.REDIS_PREFIX or "CACHE"
    full_pattern = f"{prefix}:{pattern}"
    try:
        keys = []
        async for k in redis.scan_iter(match=full_pattern):
            keys.append(k)
        if keys:
            return await redis.delete(*keys)
    except Exception:
        pass
    return 0
