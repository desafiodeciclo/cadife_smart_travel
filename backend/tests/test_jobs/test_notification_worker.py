"""
Tests — Jobs/NotificationWorker
================================
Unit tests for the background notification worker.

Coverage targets:
  - Worker fetches eligible jobs (pending + failed with next_retry_at <= now)
  - Successful dispatch marks job as completed
  - Failed dispatch increments retry and schedules next_retry_at with backoff
  - Max retries exhausted moves job to DLQ
  - No eligible jobs → worker exits silently
  - Exception during dispatch is caught and treated as failure
"""
import datetime as dt
import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.jobs.notification_worker import NotificationWorker
from app.services.notification_queue_service import NotificationQueueService


@pytest.fixture
def fake_db() -> AsyncMock:
    return AsyncMock()


@pytest.fixture
def fake_queue_service() -> MagicMock:
    qs = MagicMock(spec=NotificationQueueService)
    qs.move_to_dead_letter = AsyncMock()
    return qs


@pytest.fixture
def worker(fake_queue_service) -> NotificationWorker:
    return NotificationWorker(queue_service=fake_queue_service)


def _make_job(
    status: str = "pending",
    retry_count: int = 0,
    max_retries: int = 3,
    retry_delay_seconds: int = 60,
    next_retry_at=None,
) -> MagicMock:
    job = MagicMock()
    job.id = uuid.uuid4()
    job.lead_id = uuid.uuid4()
    job.status = status
    job.retry_count = retry_count
    job.max_retries = max_retries
    job.retry_delay_seconds = retry_delay_seconds
    job.next_retry_at = next_retry_at
    job.payload = {
        "title": "Novo lead",
        "body": "Lead: Teste",
        "data": {"type": "new_lead"},
        "fcm_tokens": ["token_1", "token_2"],
    }
    job.error_log = None
    job.compute_next_retry = MagicMock(return_value=dt.datetime.now(dt.timezone.utc) + dt.timedelta(seconds=120))
    return job


@pytest.mark.asyncio
async def test_worker_no_jobs_exits_silently(worker, fake_db):
    """Sem jobs elegíveis, worker não deve fazer nada."""
    with patch.object(worker, "_fetch_eligible_jobs", new=AsyncMock(return_value=[])):
        await worker.run()

    fake_db.commit.assert_not_called()


@pytest.mark.asyncio
async def test_worker_success_marks_completed(worker, fake_db):
    """Envio FCM bem-sucedido → job status = completed."""
    job = _make_job(status="pending")

    with (
        patch.object(worker, "_fetch_eligible_jobs", new=AsyncMock(return_value=[job])),
        patch.object(worker, "_dispatch_fcm", new=AsyncMock(return_value=True)),
    ):
        await worker.run()

    assert job.status == "completed"
    assert job.error_log is None


@pytest.mark.asyncio
async def test_worker_failure_schedules_retry_with_backoff(worker, fake_db):
    """Falha no envio → retry_count++ e next_retry_at com backoff exponencial."""
    job = _make_job(status="pending", retry_count=0, retry_delay_seconds=60)

    with (
        patch.object(worker, "_fetch_eligible_jobs", new=AsyncMock(return_value=[job])),
        patch.object(worker, "_dispatch_fcm", new=AsyncMock(return_value=False)),
    ):
        await worker.run()

    assert job.status == "failed"
    assert job.retry_count == 1
    assert job.next_retry_at is not None


@pytest.mark.asyncio
async def test_worker_backoff_exponential_growth(worker, fake_db):
    """Backoff deve crescer exponencialmente: delay * 2^retry_count."""
    job = _make_job(status="failed", retry_count=2, max_retries=5, retry_delay_seconds=30)
    job.next_retry_at = dt.datetime.now(dt.timezone.utc) - dt.timedelta(seconds=1)

    with (
        patch.object(worker, "_fetch_eligible_jobs", new=AsyncMock(return_value=[job])),
        patch.object(worker, "_dispatch_fcm", new=AsyncMock(return_value=False)),
    ):
        await worker.run()

    assert job.retry_count == 3
    job.compute_next_retry.assert_called_once()


@pytest.mark.asyncio
async def test_worker_max_retries_moves_to_dlq(worker, fake_db, fake_queue_service):
    """Ao atingir max_retries, job deve ser movido para DLQ."""
    job = _make_job(status="failed", retry_count=2, max_retries=3, retry_delay_seconds=10)
    job.next_retry_at = dt.datetime.now(dt.timezone.utc) - dt.timedelta(seconds=1)

    with (
        patch.object(worker, "_fetch_eligible_jobs", new=AsyncMock(return_value=[job])),
        patch.object(worker, "_dispatch_fcm", new=AsyncMock(return_value=False)),
    ):
        await worker.run()

    fake_queue_service.move_to_dead_letter.assert_awaited_once()
    call_args = fake_queue_service.move_to_dead_letter.call_args
    # move_to_dead_letter(db, job, error_trace) — positional args
    assert call_args.args[2] == "Max retries exceeded without explicit error log"


@pytest.mark.asyncio
async def test_worker_dispatch_exception_treated_as_failure(worker, fake_db):
    """Exceção durante dispatch deve ser capturada e tratada como falha."""
    job = _make_job(status="pending")

    with (
        patch.object(worker, "_fetch_eligible_jobs", new=AsyncMock(return_value=[job])),
        patch.object(
            worker, "_dispatch_fcm", new=AsyncMock(side_effect=Exception("FCM crash"))
        ),
    ):
        await worker.run()

    assert job.status == "failed"
    assert job.retry_count == 1


@pytest.mark.asyncio
async def test_worker_no_tokens_marks_failed(worker, fake_db):
    """Job sem tokens FCM deve falhar imediatamente."""
    job = _make_job(status="pending")
    job.payload["fcm_tokens"] = []

    with patch.object(worker, "_fetch_eligible_jobs", new=AsyncMock(return_value=[job])):
        await worker.run()

    assert job.status == "failed"
    assert job.retry_count == 1
    assert "No FCM tokens available" in (job.error_log or "")


@pytest.mark.asyncio
async def test_fetch_eligible_jobs_filters_correctly(worker, fake_db):
    """_fetch_eligible_jobs deve retornar apenas jobs elegíveis."""
    now = dt.datetime.now(dt.timezone.utc)

    job_pending = _make_job(status="pending", next_retry_at=None)
    job_failed_ready = _make_job(
        status="failed",
        retry_count=1,
        next_retry_at=now - dt.timedelta(seconds=10),
    )
    job_failed_future = _make_job(
        status="failed",
        retry_count=1,
        next_retry_at=now + dt.timedelta(minutes=5),
    )

    fake_result = MagicMock()
    fake_result.scalars.return_value.all.return_value = [job_pending, job_failed_ready]
    fake_db.execute = AsyncMock(return_value=fake_result)

    jobs = await worker._fetch_eligible_jobs(fake_db)

    assert len(jobs) == 2
    assert job_pending in jobs
    assert job_failed_ready in jobs
    assert job_failed_future not in jobs
