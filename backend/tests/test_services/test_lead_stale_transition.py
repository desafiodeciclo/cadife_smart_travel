"""
Tests — Services/LeadService — Stale Lead Auto-Transition
==========================================================
Unit tests for `mark_stale_leads_as_perdido` in lead_service.py.
Uses AsyncMock to simulate SQLAlchemy session — no real DB needed.

Coverage targets:
  - Lead with old interaction → transitioned to PERDIDO
  - Lead with recent interaction → NOT transitioned
  - Lead without interactions but old creation date → transitioned
  - Already PERDIDO or FECHADO leads are ignored
  - Returns correct count of transitioned leads
"""
import uuid
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.entities.enums import LeadStatus
from app.services.lead_service import mark_stale_leads_as_perdido


def make_async_result(rows: list) -> MagicMock:
    """Helper to build a mock Result that returns `rows` from scalars().all()."""
    mock_result = MagicMock()
    mock_scalars = MagicMock()
    mock_scalars.all.return_value = rows
    mock_result.scalars.return_value = mock_scalars
    return mock_result


def fake_lead(status: LeadStatus = LeadStatus.em_atendimento) -> MagicMock:
    """Return a plain MagicMock representing a Lead row."""
    lead = MagicMock()
    lead.id = uuid.uuid4()
    lead.telefone = "5584999990001"
    lead.status = status
    lead.is_archived = False
    lead.criado_em = datetime.now(timezone.utc) - timedelta(days=40)
    return lead


@pytest.mark.asyncio
async def test_old_interaction_lead_transitions_to_perdido():
    """Lead with last interaction > 30 days ago must become PERDIDO."""
    lead = fake_lead(LeadStatus.qualificado)
    db = AsyncMock()
    db.execute = AsyncMock(return_value=make_async_result([lead]))

    count = await mark_stale_leads_as_perdido(db, inactivity_days=30)

    assert count == 1
    assert lead.status == LeadStatus.perdido
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_recent_interaction_lead_not_transitioned():
    """Lead with recent interaction must stay in current status."""
    db = AsyncMock()
    db.execute = AsyncMock(return_value=make_async_result([]))

    count = await mark_stale_leads_as_perdido(db, inactivity_days=30)

    assert count == 0
    db.commit.assert_not_awaited()


@pytest.mark.asyncio
async def test_no_interactions_old_creation_date_transitions():
    """Lead with no interactions but creation > 30 days ago must become PERDIDO."""
    lead = fake_lead(LeadStatus.em_atendimento)
    db = AsyncMock()
    db.execute = AsyncMock(return_value=make_async_result([lead]))

    count = await mark_stale_leads_as_perdido(db, inactivity_days=30)

    assert count == 1
    assert lead.status == LeadStatus.perdido


@pytest.mark.asyncio
async def test_perdido_lead_ignored():
    """Already PERDIDO leads must never be selected for transition."""
    db = AsyncMock()
    db.execute = AsyncMock(return_value=make_async_result([]))

    count = await mark_stale_leads_as_perdido(db, inactivity_days=30)

    assert count == 0


@pytest.mark.asyncio
async def test_fechado_lead_ignored():
    """FECHADO leads must never be selected for transition."""
    db = AsyncMock()
    db.execute = AsyncMock(return_value=make_async_result([]))

    count = await mark_stale_leads_as_perdido(db, inactivity_days=30)

    assert count == 0


@pytest.mark.asyncio
async def test_archived_lead_ignored():
    """Archived leads must never be selected for transition."""
    db = AsyncMock()
    db.execute = AsyncMock(return_value=make_async_result([]))

    count = await mark_stale_leads_as_perdido(db, inactivity_days=30)

    assert count == 0
