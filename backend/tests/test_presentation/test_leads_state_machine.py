"""
Tests — Presentation/Routes/LeadStateMachine Integration
=========================================================
Integration tests for PUT /leads/{id} enforcing the state machine.
Uses a test FastAPI app with dependency-overrides for auth and DB.

Coverage targets:
  - Valid status transition returns 200
  - Invalid status transition returns 422 with descriptive message
  - Update without status change still works
"""
import uuid
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

from app.domain.entities.enums import LeadStatus
from app.models.lead import LeadUpdate
from app.routes import leads as leads_router


# ── Test App with Dependency Overrides ─────────────────────────────────────

def _make_test_app() -> FastAPI:
    app = FastAPI()

    # Fake DB session
    fake_db = AsyncMock()

    # Fake authenticated user (admin scope to bypass RBAC restriction)
    fake_user = MagicMock()
    fake_user.perfil = "admin"
    fake_user.id = uuid.uuid4()

    # Override dependencies on the leads router
    from app.infrastructure.security.dependencies import get_current_user, get_db
    app.dependency_overrides[get_db] = lambda: fake_db
    app.dependency_overrides[get_current_user] = lambda: fake_user

    app.include_router(leads_router.router)
    return app


@pytest.fixture
def test_app() -> FastAPI:
    return _make_test_app()


# ── Helpers ────────────────────────────────────────────────────────────────

def fake_lead(status: LeadStatus) -> MagicMock:
    lead = MagicMock()
    lead.id = uuid.uuid4()
    lead.nome = "Test Lead"
    lead.telefone = "5584999990001"
    lead.origem = "whatsapp"
    lead.status = status
    lead.score = None
    lead.consultor_id = None
    lead.consultor = None
    lead.consultor_nome = None
    lead.consultor_avatar = None
    lead.is_archived = False
    lead.criado_em = datetime.now()
    lead.atualizado_em = datetime.now()
    return lead


# ── Tests ──────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
@pytest.mark.parametrize("current,target", [
    (LeadStatus.novo, LeadStatus.em_atendimento),
    (LeadStatus.em_atendimento, LeadStatus.qualificado),
    (LeadStatus.qualificado, LeadStatus.agendado),
    (LeadStatus.qualificado, LeadStatus.proposta),
    (LeadStatus.agendado, LeadStatus.proposta),
    (LeadStatus.proposta, LeadStatus.fechado),
    (LeadStatus.novo, LeadStatus.perdido),
])
async def test_valid_status_transition_returns_200(test_app: FastAPI, current: LeadStatus, target: LeadStatus) -> None:
    lead = fake_lead(current)

    with pytest.MonkeyPatch().context() as mp:
        mp.setattr(
            "app.routes.leads.lead_service.get_lead_by_id",
            AsyncMock(return_value=lead),
        )
        async with AsyncClient(transport=ASGITransport(app=test_app), base_url="http://test") as ac:
            response = await ac.put(f"/leads/{lead.id}", json={"status": target.value})

    assert response.status_code == 200
    assert response.json()["status"] == target.value


@pytest.mark.asyncio
@pytest.mark.parametrize("current,target", [
    (LeadStatus.fechado, LeadStatus.novo),
    (LeadStatus.perdido, LeadStatus.qualificado),
    (LeadStatus.novo, LeadStatus.proposta),
    (LeadStatus.em_atendimento, LeadStatus.agendado),
])
async def test_invalid_status_transition_returns_422(test_app: FastAPI, current: LeadStatus, target: LeadStatus) -> None:
    lead = fake_lead(current)

    with pytest.MonkeyPatch().context() as mp:
        mp.setattr(
            "app.routes.leads.lead_service.get_lead_by_id",
            AsyncMock(return_value=lead),
        )
        async with AsyncClient(transport=ASGITransport(app=test_app), base_url="http://test") as ac:
            response = await ac.put(f"/leads/{lead.id}", json={"status": target.value})

    assert response.status_code == 422
    detail = response.json()["detail"]
    assert current.value in detail
    assert target.value in detail


@pytest.mark.asyncio
async def test_update_without_status_change_returns_200(test_app: FastAPI) -> None:
    lead = fake_lead(LeadStatus.qualificado)

    with pytest.MonkeyPatch().context() as mp:
        mp.setattr(
            "app.routes.leads.lead_service.get_lead_by_id",
            AsyncMock(return_value=lead),
        )
        async with AsyncClient(transport=ASGITransport(app=test_app), base_url="http://test") as ac:
            response = await ac.put(f"/leads/{lead.id}", json={"nome": "Novo Nome"})

    assert response.status_code == 200
    assert response.json()["nome"] == "Novo Nome"
