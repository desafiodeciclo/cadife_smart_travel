"""
Tests — Jobs — Lead Expiration Scheduled Job
=============================================
Unit tests for `expire_stale_leads()` in app/jobs/lead_expiration_job.py.
Uses mocks throughout — no real DB or scheduler needed.

Coverage targets:
  - Job uses LEAD_EXPIRATION_DAYS from settings
  - Job passes the value to mark_stale_leads_as_perdido
  - Job handles DB exceptions without re-raising (scheduler safety)
  - Job handles zero expired leads gracefully
"""
from unittest.mock import AsyncMock, MagicMock, patch

import pytest


@pytest.mark.asyncio
async def test_job_calls_mark_stale_with_configured_days():
    """expire_stale_leads must forward LEAD_EXPIRATION_DAYS to mark_stale_leads_as_perdido."""
    mock_db = AsyncMock()
    mock_session_ctx = MagicMock()
    mock_session_ctx.__aenter__ = AsyncMock(return_value=mock_db)
    mock_session_ctx.__aexit__ = AsyncMock(return_value=False)

    mock_settings = MagicMock()
    mock_settings.LEAD_EXPIRATION_DAYS = 45

    with (
        patch("app.jobs.lead_expiration_job.get_settings", return_value=mock_settings),
        patch("app.jobs.lead_expiration_job.AsyncSessionLocal", return_value=mock_session_ctx),
        patch(
            "app.jobs.lead_expiration_job.mark_stale_leads_as_perdido",
            new_callable=AsyncMock,
            return_value=3,
        ) as mock_mark,
    ):
        from app.jobs.lead_expiration_job import expire_stale_leads

        await expire_stale_leads()

        mock_mark.assert_awaited_once_with(mock_db, inactivity_days=45)


@pytest.mark.asyncio
async def test_job_handles_db_exception_without_raising():
    """A DB failure must be logged and swallowed — never crash the scheduler."""
    mock_db = AsyncMock()
    mock_session_ctx = MagicMock()
    mock_session_ctx.__aenter__ = AsyncMock(return_value=mock_db)
    mock_session_ctx.__aexit__ = AsyncMock(return_value=False)

    mock_settings = MagicMock()
    mock_settings.LEAD_EXPIRATION_DAYS = 30

    with (
        patch("app.jobs.lead_expiration_job.get_settings", return_value=mock_settings),
        patch("app.jobs.lead_expiration_job.AsyncSessionLocal", return_value=mock_session_ctx),
        patch(
            "app.jobs.lead_expiration_job.mark_stale_leads_as_perdido",
            new_callable=AsyncMock,
            side_effect=Exception("connection refused"),
        ),
    ):
        from app.jobs.lead_expiration_job import expire_stale_leads

        # Must not propagate the exception
        await expire_stale_leads()


@pytest.mark.asyncio
async def test_job_with_zero_expired_leads_completes_normally():
    """When no stale leads exist, job must complete without error."""
    mock_db = AsyncMock()
    mock_session_ctx = MagicMock()
    mock_session_ctx.__aenter__ = AsyncMock(return_value=mock_db)
    mock_session_ctx.__aexit__ = AsyncMock(return_value=False)

    mock_settings = MagicMock()
    mock_settings.LEAD_EXPIRATION_DAYS = 30

    with (
        patch("app.jobs.lead_expiration_job.get_settings", return_value=mock_settings),
        patch("app.jobs.lead_expiration_job.AsyncSessionLocal", return_value=mock_session_ctx),
        patch(
            "app.jobs.lead_expiration_job.mark_stale_leads_as_perdido",
            new_callable=AsyncMock,
            return_value=0,
        ) as mock_mark,
    ):
        from app.jobs.lead_expiration_job import expire_stale_leads

        await expire_stale_leads()

        mock_mark.assert_awaited_once()
