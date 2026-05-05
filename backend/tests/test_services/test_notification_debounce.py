"""
Tests — Services/NotificationDebounceService
=============================================
Unit tests for Redis-backed debounce of FCM push notifications.

Coverage targets:
  - is_allowed returns True when no debounce key exists
  - is_allowed returns False when debounce key is active
  - touch creates a key with TTL 60s
  - clear removes the key
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch

from app.services.notification_debounce_service import NotificationDebounceService


@pytest.fixture
def fake_redis() -> MagicMock:
    redis = MagicMock()
    redis.exists = AsyncMock(return_value=0)
    redis.setex = AsyncMock()
    redis.delete = AsyncMock()
    return redis


@pytest.mark.asyncio
async def test_is_allowed_when_no_key_exists(fake_redis):
    """Debounce deve permitir notificação quando chave não existe no Redis."""
    fake_redis.exists = AsyncMock(return_value=0)
    service = NotificationDebounceService(redis=fake_redis)

    allowed = await service.is_allowed("lead-123")

    assert allowed is True
    fake_redis.exists.assert_awaited_once_with("cadife:notification:debounce:lead-123")


@pytest.mark.asyncio
async def test_is_allowed_blocked_when_key_exists(fake_redis):
    """Debounce deve bloquear notificação quando chave existe no Redis."""
    fake_redis.exists = AsyncMock(return_value=1)
    service = NotificationDebounceService(redis=fake_redis)

    allowed = await service.is_allowed("lead-123")

    assert allowed is False


@pytest.mark.asyncio
async def test_touch_sets_key_with_ttl_60s(fake_redis):
    """touch deve criar chave no Redis com TTL de 60 segundos."""
    service = NotificationDebounceService(redis=fake_redis)

    await service.touch("lead-456")

    fake_redis.setex.assert_awaited_once_with(
        "cadife:notification:debounce:lead-456", 60, "1"
    )


@pytest.mark.asyncio
async def test_clear_removes_key(fake_redis):
    """clear deve remover a chave de debounce do Redis."""
    service = NotificationDebounceService(redis=fake_redis)

    await service.clear("lead-789")

    fake_redis.delete.assert_awaited_once_with(
        "cadife:notification:debounce:lead-789"
    )


@pytest.mark.asyncio
async def test_lazy_redis_initialization():
    """Service deve inicializar Redis from_url quando não fornecido."""
    with patch(
        "app.services.notification_debounce_service.Redis.from_url",
        return_value=MagicMock(exists=AsyncMock(return_value=0)),
    ) as mock_from_url:
        service = NotificationDebounceService(redis=None)
        await service.is_allowed("lead-abc")

        mock_from_url.assert_called_once()
