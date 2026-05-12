"""
Tests — GET /leads/{id}/conversation-summary and GET /leads/{id}/conversation-summaries
"""

import uuid
from datetime import datetime, timezone

import pytest


# ── Helpers ───────────────────────────────────────────────────────────────

async def _create_lead(db_session):
    from app.infrastructure.persistence.models.lead_model import LeadModel

    lead = LeadModel(
        id=uuid.uuid4(),
        telefone=f"+5511{uuid.uuid4().int % 900000000 + 100000000:09d}",
        origem="whatsapp",
        status="novo",
    )
    db_session.add(lead)
    await db_session.flush()
    return lead


async def _create_summary(db_session, lead_id: uuid.UUID, *, pending: bool = False, topics: dict | None = None):
    from app.infrastructure.persistence.models.conversation_summary_model import ConversationSummaryModel

    row = ConversationSummaryModel(
        id=uuid.uuid4(),
        lead_id=lead_id,
        sessao_id=f"{str(lead_id)[:8]}:20260510_1000",
        resumo_json=topics or (None if pending else {"intencao_principal": "Paris"}),
        resumo_pendente=pending,
        gerado_em=datetime(2026, 5, 10, 10, 0, tzinfo=timezone.utc),
        tokens_utilizados=100 if not pending else None,
    )
    db_session.add(row)
    await db_session.flush()
    return row


# ── GET /leads/{id}/conversation-summary ─────────────────────────────────


@pytest.mark.asyncio
async def test_get_summary_not_found(async_client, db_session):
    lead = await _create_lead(db_session)
    await db_session.commit()

    response = await async_client.get(f"/leads/{lead.id}/conversation-summary")
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_get_summary_returns_latest(async_client, db_session):
    lead = await _create_lead(db_session)
    await _create_summary(db_session, lead.id, topics={"intencao_principal": "Paris"})
    await db_session.commit()

    response = await async_client.get(f"/leads/{lead.id}/conversation-summary")
    assert response.status_code == 200
    data = response.json()
    assert data["lead_id"] == str(lead.id)
    assert data["resumo_pendente"] is False
    assert data["resumo_json"]["intencao_principal"] == "Paris"
    assert data["tokens_utilizados"] == 100


@pytest.mark.asyncio
async def test_get_summary_lead_not_found(async_client):
    response = await async_client.get(f"/leads/{uuid.uuid4()}/conversation-summary")
    assert response.status_code == 404
    assert "Lead" in response.json()["detail"]


# ── GET /leads/{id}/conversation-summaries ────────────────────────────────


@pytest.mark.asyncio
async def test_list_summaries_empty(async_client, db_session):
    lead = await _create_lead(db_session)
    await db_session.commit()

    response = await async_client.get(f"/leads/{lead.id}/conversation-summaries")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 0
    assert data["items"] == []


@pytest.mark.asyncio
async def test_list_summaries_pagination(async_client, db_session):
    lead = await _create_lead(db_session)
    for i in range(3):
        from app.infrastructure.persistence.models.conversation_summary_model import ConversationSummaryModel
        from datetime import timedelta

        row = ConversationSummaryModel(
            id=uuid.uuid4(),
            lead_id=lead.id,
            sessao_id=f"{str(lead.id)[:8]}:2026051{i}_1000",
            resumo_json={"intencao_principal": f"Destino {i}"},
            resumo_pendente=False,
            gerado_em=datetime(2026, 5, 10, 10 + i, 0, tzinfo=timezone.utc),
            tokens_utilizados=50,
        )
        db_session.add(row)
    await db_session.commit()

    response = await async_client.get(
        f"/leads/{lead.id}/conversation-summaries",
        params={"page": 1, "limit": 2},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 3
    assert len(data["items"]) == 2
    assert data["pages"] == 2
    assert data["limit"] == 2


@pytest.mark.asyncio
async def test_list_summaries_lead_not_found(async_client):
    response = await async_client.get(f"/leads/{uuid.uuid4()}/conversation-summaries")
    assert response.status_code == 404
