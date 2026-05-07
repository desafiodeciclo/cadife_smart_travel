"""
Tests — Services/NotificationQueueService
==========================================
Unit tests for enqueueing and managing FCM notification jobs.

Coverage targets:
  - enqueue creates job when debounce allows
  - enqueue returns None when debounce blocks
  - enqueue returns None when pending/processing job already exists for lead
  - move_to_dead_letter transfers job to DLQ and deletes from queue
"""
import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from sqlalchemy import select

from app.services.notification_queue_service import NotificationQueueService


@pytest.fixture
def fake_db() -> AsyncMock:
    db = AsyncMock()
    db.add = MagicMock()
    return db


@pytest.fixture
def fake_debounce() -> MagicMock:
    debounce = MagicMock()
    debounce.is_allowed = AsyncMock(return_value=True)
    debounce.touch = AsyncMock()
    return debounce


def _make_job(**kwargs):
    job = MagicMock()
    job.id = kwargs.get("id", uuid.uuid4())
    job.lead_id = kwargs.get("lead_id", uuid.uuid4())
    job.status = kwargs.get("status", "pending")
    job.retry_count = kwargs.get("retry_count", 0)
    job.max_retries = kwargs.get("max_retries", 3)
    job.retry_delay_seconds = kwargs.get("retry_delay_seconds", 60)
    job.next_retry_at = kwargs.get("next_retry_at")
    job.payload = kwargs.get("payload", {})
    job.error_log = kwargs.get("error_log")
    return job


@pytest.mark.asyncio
async def test_enqueue_creates_job_when_allowed(fake_db, fake_debounce):
    """Debounce permite → job deve ser criado na fila."""
    service = NotificationQueueService(debounce_service=fake_debounce)
    lead_id = uuid.uuid4()
    tokens = ["token_a", "token_b"]

    # simulate no existing pending job
    fake_db.execute = AsyncMock(return_value=MagicMock(scalar_one_or_none=MagicMock(return_value=None)))

    job = await service.enqueue_qualified_lead_notification(
        db=fake_db,
        lead_id=lead_id,
        lead_nome="Maria",
        destino="Paris",
        fcm_tokens=tokens,
    )

    assert job is not None
    assert job.lead_id == lead_id
    assert job.status == "pending"
    assert job.payload["title"] == "Novo lead qualificado"
    assert job.payload["fcm_tokens"] == tokens
    fake_db.commit.assert_awaited()
    fake_debounce.touch.assert_awaited_once_with(str(lead_id))


@pytest.mark.asyncio
async def test_enqueue_blocked_by_debounce(fake_db, fake_debounce):
    """Debounce ativo → enqueue deve retornar None."""
    fake_debounce.is_allowed = AsyncMock(return_value=False)
    service = NotificationQueueService(debounce_service=fake_debounce)

    job = await service.enqueue_qualified_lead_notification(
        db=fake_db,
        lead_id=uuid.uuid4(),
        lead_nome="João",
        destino=None,
        fcm_tokens=["token_x"],
    )

    assert job is None
    fake_db.execute.assert_not_called()
    fake_debounce.touch.assert_not_called()


@pytest.mark.asyncio
async def test_enqueue_blocked_by_existing_pending_job(fake_db, fake_debounce):
    """Job pending/processing já existe para o lead → deve retornar None."""
    service = NotificationQueueService(debounce_service=fake_debounce)
    existing_job = MagicMock()

    fake_db.execute = AsyncMock(
        return_value=MagicMock(scalar_one_or_none=MagicMock(return_value=existing_job))
    )

    job = await service.enqueue_qualified_lead_notification(
        db=fake_db,
        lead_id=uuid.uuid4(),
        lead_nome="Ana",
        destino="Lisboa",
        fcm_tokens=["token_y"],
    )

    assert job is None
    fake_debounce.touch.assert_not_called()


@pytest.mark.asyncio
async def test_enqueue_builds_body_with_and_without_destino(fake_db, fake_debounce):
    """Payload body deve incluir destino quando disponível."""
    service = NotificationQueueService(debounce_service=fake_debounce)
    fake_db.execute = AsyncMock(return_value=MagicMock(scalar_one_or_none=MagicMock(return_value=None)))

    job_with = await service.enqueue_qualified_lead_notification(
        db=fake_db,
        lead_id=uuid.uuid4(),
        lead_nome="Carlos",
        destino="Roma",
        fcm_tokens=["t1"],
    )
    assert "Roma" in job_with.payload["body"]

    job_without = await service.enqueue_qualified_lead_notification(
        db=fake_db,
        lead_id=uuid.uuid4(),
        lead_nome=None,
        destino=None,
        fcm_tokens=["t1"],
    )
    assert "Novo contato" in job_without.payload["body"]


@pytest.mark.asyncio
async def test_move_to_dead_letter(fake_db):
    """Job exaurido deve ser movido para DLQ e removido da fila ativa."""
    service = NotificationQueueService()
    lead_id = uuid.uuid4()
    job = _make_job(
        id=uuid.uuid4(),
        lead_id=lead_id,
        status="failed",
        retry_count=3,
        max_retries=3,
        retry_delay_seconds=60,
        payload={"title": "test"},
    )

    dlq = await service.move_to_dead_letter(fake_db, job, "FCM timeout after 3 retries")

    assert dlq.lead_id == lead_id
    assert dlq.original_payload == job.payload
    assert dlq.retry_count_exhausted == 3
    assert "FCM timeout" in dlq.error_trace
    fake_db.delete.assert_awaited_once_with(job)
    fake_db.commit.assert_awaited()
