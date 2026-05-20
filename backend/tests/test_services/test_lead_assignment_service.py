"""Tests for lead_assignment_service — round-robin auto-assignment."""

import pytest

from app.core.security import hash_password
from app.domain.entities.enums import LeadStatus, UserPerfil
from app.models.lead import Lead
from app.models.user import User
from app.infrastructure.security.pii_encryption import hmac_hash
from app.services import lead_assignment_service


async def _make_consultor(db, email: str, name: str, active: bool = True) -> User:
    user = User(
        email=email,
        nome=name,
        hashed_password=hash_password("Secret123!"),
        perfil=UserPerfil.consultor,
        is_active=active,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def _make_lead(db, phone: str, consultor_id=None, status=LeadStatus.novo) -> Lead:
    lead = Lead(
        nome=f"Lead {phone}",
        telefone=phone,
        telefone_hash=hmac_hash(phone),
        consultor_id=consultor_id,
        status=status,
    )
    db.add(lead)
    await db.commit()
    await db.refresh(lead)
    return lead


@pytest.mark.asyncio
async def test_pick_next_consultor_returns_none_when_no_active(db_session):
    user = await _make_consultor(db_session, "inactive@x.com", "Ana", active=False)
    picked = await lead_assignment_service.pick_next_consultor(db_session)
    assert picked is None


@pytest.mark.asyncio
async def test_pick_next_consultor_cycles_round_robin(db_session):
    a = await _make_consultor(db_session, "a@x.com", "Ana")
    b = await _make_consultor(db_session, "b@x.com", "Bia")
    c = await _make_consultor(db_session, "c@x.com", "Caio")

    # Order is by (nome, id) — Ana, Bia, Caio.
    picks = []
    for _ in range(6):
        picked = await lead_assignment_service.pick_next_consultor(db_session)
        await db_session.commit()
        picks.append(picked.id)

    # Cycles through all three consultores twice.
    assert picks[0] == a.id
    assert picks[1] == b.id
    assert picks[2] == c.id
    assert picks[3] == a.id
    assert picks[4] == b.id
    assert picks[5] == c.id


@pytest.mark.asyncio
async def test_pick_next_consultor_skips_inactive(db_session):
    a = await _make_consultor(db_session, "a@x.com", "Ana")
    _ = await _make_consultor(db_session, "b@x.com", "Bia", active=False)
    c = await _make_consultor(db_session, "c@x.com", "Caio")

    picks = []
    for _ in range(4):
        picked = await lead_assignment_service.pick_next_consultor(db_session)
        await db_session.commit()
        picks.append(picked.id)

    # Only Ana and Caio rotate.
    assert picks == [a.id, c.id, a.id, c.id]


@pytest.mark.asyncio
async def test_auto_assign_orphans_distributes(db_session):
    a = await _make_consultor(db_session, "a@x.com", "Ana")
    b = await _make_consultor(db_session, "b@x.com", "Bia")

    for i in range(5):
        await _make_lead(db_session, f"+55119999900{i}", consultor_id=None)

    result = await lead_assignment_service.auto_assign_orphans(db_session)
    assert result["assigned"] == 5
    assert result["skipped"] == 0
    assert result["no_consultor_available"] is False

    # Both consultores received leads; distribution is 3-2 or 2-3.
    from sqlalchemy import select, func
    counts = {}
    for u in (a, b):
        cnt = (
            await db_session.execute(
                select(func.count())
                .select_from(Lead)
                .where(Lead.consultor_id == u.id)
            )
        ).scalar_one()
        counts[u.id] = cnt
    assert sum(counts.values()) == 5
    assert min(counts.values()) >= 2


@pytest.mark.asyncio
async def test_auto_assign_orphans_no_consultor(db_session):
    await _make_lead(db_session, "+5511999998888")
    result = await lead_assignment_service.auto_assign_orphans(db_session)
    assert result["assigned"] == 0
    assert result["skipped"] == 1
    assert result["no_consultor_available"] is True


@pytest.mark.asyncio
async def test_get_or_create_by_phone_auto_assigns(db_session):
    """WhatsApp inbound flow must populate consultor_id automatically."""
    from app.services import lead_service

    a = await _make_consultor(db_session, "a@x.com", "Ana")
    lead = await lead_service.get_or_create_by_phone(
        db_session, "+5511999990001", name="Lead Web"
    )
    assert lead.consultor_id == a.id


@pytest.mark.asyncio
async def test_least_loaded_tiebreaker_on_imbalance(db_session):
    # Ana has many active leads; Bia is fresh. Rotation should prefer Bia.
    a = await _make_consultor(db_session, "a@x.com", "Ana")
    b = await _make_consultor(db_session, "b@x.com", "Bia")

    # Pre-load Ana well above the imbalance threshold.
    for i in range(
        lead_assignment_service.LOAD_IMBALANCE_THRESHOLD + 2
    ):
        await _make_lead(db_session, f"+5511900000{i:02d}", consultor_id=a.id)

    picked = await lead_assignment_service.pick_next_consultor(db_session)
    await db_session.commit()
    assert picked.id == b.id
