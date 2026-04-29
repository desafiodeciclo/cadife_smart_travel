"""
Tests — Presentation/Routes/Lead Auto-Score on QUALIFIED
=========================================================
Integration tests for PUT /leads/{id} automatically calculating score
when transitioning to QUALIFICADO (spec.md §8.3).

Coverage targets:
  - QUENTE: destino + data_ida + qtd_pessoas + orcamento all filled
  - MORNO: destino filled, hot fields missing
  - FRIO: destino not filled
  - Score persisted and returned in LeadResponse
"""
import uuid
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

from app.domain.entities.enums import LeadScore, LeadStatus
from app.models.briefing import Briefing
from app.routes import leads as leads_router


# ── Test App with Dependency Overrides ─────────────────────────────────────

def _make_test_app() -> FastAPI:
    app = FastAPI()

    fake_db = AsyncMock()

    fake_user = MagicMock()
    fake_user.perfil = "admin"
    fake_user.id = uuid.uuid4()

    from app.infrastructure.security.dependencies import get_current_user, get_db
    app.dependency_overrides[get_db] = lambda: fake_db
    app.dependency_overrides[get_current_user] = lambda: fake_user

    app.include_router(leads_router.router)
    return app


@pytest.fixture
def test_app() -> FastAPI:
    return _make_test_app()


# ── Helpers ────────────────────────────────────────────────────────────────

def fake_lead(status: LeadStatus, score: LeadScore | None = None) -> MagicMock:
    lead = MagicMock()
    lead.id = uuid.uuid4()
    lead.nome = "Test Lead"
    lead.telefone = "5584999990001"
    lead.origem = "whatsapp"
    lead.status = status
    lead.score = score
    lead.consultor_id = None
    lead.is_archived = False
    lead.criado_em = datetime.now()
    lead.atualizado_em = datetime.now()
    return lead


def fake_briefing(
    destino: str | None = None,
    data_ida=None,
    qtd_pessoas: int | None = None,
    orcamento: str | None = None,
) -> MagicMock:
    b = MagicMock()
    b.destino = destino
    b.data_ida = data_ida
    b.qtd_pessoas = qtd_pessoas
    b.orcamento = orcamento
    return b


# ── Tests ──────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_transition_to_qualificado_score_quente(test_app: FastAPI) -> None:
    """All hot fields filled → score QUENTE."""
    lead = fake_lead(LeadStatus.em_atendimento)
    lead.briefing = fake_briefing(
        destino="Portugal",
        data_ida="2026-06-01",
        qtd_pessoas=3,
        orcamento="médio",
    )

    with pytest.MonkeyPatch().context() as mp:
        mp.setattr(
            "app.routes.leads.lead_service.get_lead_by_id",
            AsyncMock(return_value=lead),
        )
        async with AsyncClient(transport=ASGITransport(app=test_app), base_url="http://test") as ac:
            response = await ac.put(
                f"/leads/{lead.id}",
                json={"status": LeadStatus.qualificado.value},
            )

    assert response.status_code == 200
    assert response.json()["status"] == LeadStatus.qualificado.value
    assert response.json()["score"] == LeadScore.quente.value


@pytest.mark.asyncio
async def test_transition_to_qualificado_score_morno(test_app: FastAPI) -> None:
    """Only destino filled → score MORNO."""
    lead = fake_lead(LeadStatus.em_atendimento)
    lead.briefing = fake_briefing(destino="Portugal")

    with pytest.MonkeyPatch().context() as mp:
        mp.setattr(
            "app.routes.leads.lead_service.get_lead_by_id",
            AsyncMock(return_value=lead),
        )
        async with AsyncClient(transport=ASGITransport(app=test_app), base_url="http://test") as ac:
            response = await ac.put(
                f"/leads/{lead.id}",
                json={"status": LeadStatus.qualificado.value},
            )

    assert response.status_code == 200
    assert response.json()["score"] == LeadScore.morno.value


@pytest.mark.asyncio
async def test_transition_to_qualificado_score_frio(test_app: FastAPI) -> None:
    """No destino → score FRIO."""
    lead = fake_lead(LeadStatus.em_atendimento)
    lead.briefing = fake_briefing()

    with pytest.MonkeyPatch().context() as mp:
        mp.setattr(
            "app.routes.leads.lead_service.get_lead_by_id",
            AsyncMock(return_value=lead),
        )
        async with AsyncClient(transport=ASGITransport(app=test_app), base_url="http://test") as ac:
            response = await ac.put(
                f"/leads/{lead.id}",
                json={"status": LeadStatus.qualificado.value},
            )

    assert response.status_code == 200
    assert response.json()["score"] == LeadScore.frio.value


@pytest.mark.asyncio
async def test_transition_to_qualificado_without_briefing_score_none(test_app: FastAPI) -> None:
    """No briefing attached → score remains None."""
    lead = fake_lead(LeadStatus.em_atendimento)
    lead.briefing = None

    with pytest.MonkeyPatch().context() as mp:
        mp.setattr(
            "app.routes.leads.lead_service.get_lead_by_id",
            AsyncMock(return_value=lead),
        )
        async with AsyncClient(transport=ASGITransport(app=test_app), base_url="http://test") as ac:
            response = await ac.put(
                f"/leads/{lead.id}",
                json={"status": LeadStatus.qualificado.value},
            )

    assert response.status_code == 200
    assert response.json()["score"] is None
