"""
Tests — Infrastructure/Cache/Redis
====================================
Unit tests for the @cached decorator and invalidation helpers.
Redis itself is mocked so the suite runs without a live Redis server.
"""
from __future__ import annotations

import json
from typing import Any
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from pydantic import BaseModel

from app.infrastructure.cache.decorator import (
    _deserialize,
    _make_cache_key,
    _serialize,
    cached,
    invalidate_pattern,
)


# ── Fixtures ───────────────────────────────────────────────────────────────

@pytest.fixture
def fake_redis() -> AsyncMock:
    return AsyncMock()


@pytest.fixture(autouse=True)
def patch_get_redis(fake_redis: AsyncMock):
    with patch("app.infrastructure.cache.decorator.get_redis", return_value=fake_redis):
        yield


# ── Helpers ────────────────────────────────────────────────────────────────

class DummyDTO(BaseModel):
    id: int
    nome: str


def test_make_cache_key_is_deterministic():
    key1 = _make_cache_key("fn", (1, "a"), {"b": 2})
    key2 = _make_cache_key("fn", (1, "a"), {"b": 2})
    assert key1 == key2
    assert key1.startswith("CACHE:cached:fn:")


def test_serialize_pydantic_model():
    dto = DummyDTO(id=1, nome="test")
    raw = _serialize(dto)
    data = json.loads(raw)
    assert data["id"] == 1
    assert data["nome"] == "test"


def test_serialize_plain_dict():
    raw = _serialize({"a": 1, "b": [2, 3]})
    assert json.loads(raw) == {"a": 1, "b": [2, 3]}


def test_deserialize():
    obj = _deserialize('{"x": 42}')
    assert obj == {"x": 42}


# ── Decorator ──────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_cache_hit_returns_cached_value(fake_redis: AsyncMock):
    cached_value = _serialize(DummyDTO(id=99, nome="cached"))
    fake_redis.get.return_value = cached_value

    @cached(ttl=60)
    async def fetch(x: int) -> DummyDTO:
        return DummyDTO(id=x, nome="live")

    result = await fetch(1)
    assert result == {"id": 99, "nome": "cached"}
    fake_redis.get.assert_awaited_once()
    fake_redis.setex.assert_not_awaited()


@pytest.mark.asyncio
async def test_cache_miss_executes_and_stores(fake_redis: AsyncMock):
    fake_redis.get.return_value = None

    @cached(ttl=120)
    async def fetch(x: int) -> DummyDTO:
        return DummyDTO(id=x, nome="live")

    result = await fetch(42)
    # Decorator stores serialized dict in Redis but returns original model when miss
    assert isinstance(result, DummyDTO)
    assert result.id == 42
    assert result.nome == "live"
    fake_redis.get.assert_awaited_once()
    fake_redis.setex.assert_awaited_once()
    # Verify TTL passed to Redis
    _, ttl, payload = fake_redis.setex.await_args[0]
    assert ttl == 120
    assert json.loads(payload)["nome"] == "live"


@pytest.mark.asyncio
async def test_cache_disabled_bypasses_redis(fake_redis: AsyncMock):
    with patch("app.infrastructure.cache.decorator._settings.CACHE_ENABLED", False):
        @cached(ttl=60)
        async def fetch(x: int) -> DummyDTO:
            return DummyDTO(id=x, nome="live")

        result = await fetch(1)
        assert isinstance(result, DummyDTO)
        assert result.id == 1
        fake_redis.get.assert_not_awaited()
        fake_redis.setex.assert_not_awaited()


@pytest.mark.asyncio
async def test_cache_graceful_degradation_on_redis_error(fake_redis: AsyncMock):
    fake_redis.get.side_effect = Exception("Redis down")
    fake_redis.setex.side_effect = Exception("Redis down")

    @cached(ttl=60)
    async def fetch(x: int) -> DummyDTO:
        return DummyDTO(id=x, nome="live")

    result = await fetch(1)
    assert isinstance(result, DummyDTO)
    assert result.id == 1


# ── Invalidation ───────────────────────────────────────────────────────────

async def _async_iter(items):
    for item in items:
        yield item


@pytest.mark.asyncio
async def test_invalidate_pattern_deletes_matching_keys(fake_redis: AsyncMock):
    fake_redis.scan_iter = lambda **kw: _async_iter(["CACHE:cached:fn:aaa", "CACHE:cached:fn:bbb"])
    fake_redis.delete.return_value = 2

    deleted = await invalidate_pattern("cached:fn:*")
    assert deleted == 2
    fake_redis.delete.assert_awaited_once_with("CACHE:cached:fn:aaa", "CACHE:cached:fn:bbb")


@pytest.mark.asyncio
async def test_invalidate_pattern_returns_zero_when_no_match(fake_redis: AsyncMock):
    fake_redis.scan_iter = lambda **kw: _async_iter([])

    deleted = await invalidate_pattern("cached:nope:*")
    assert deleted == 0
    fake_redis.delete.assert_not_awaited()
