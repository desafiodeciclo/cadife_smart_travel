"""
Tests — Routes/Propostas
========================
Integration tests for the proposals API endpoints.
Covers:
  - POST /propostas   (role check, lead existence, scope check)
  - GET  /propostas/{id} (existence, scope check)
  - PUT  /propostas/{id} (existence, scope check, partial update)
Uses dependency_overrides to mock DB and JWT on an isolated FastAPI app.
"""
import uuid
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.core.dependencies import get_current_user, get_db
from app.domain.entities.enums import LeadStatus, PropostaStatus
from app.models.user import UserPerfil
from app.routes.leads import router as leads_router
from app.routes.propostas import router as propostas_router

# Pre-import all SQLAlchemy models so relationships resolve correctly
import app.models.agendamento  # noqa: F401
import app.models.briefing  # noqa: F401
import app.models.interacao  # noqa: F401
import app.models.lead  # noqa: F401
import app.models.proposta  # noqa: F401
import app.models.user  # noqa: F401

# Build isolated app to avoid importing broken langchain deps from main.py
app = FastAPI()
app.include_router(leads_router)
app.include_router(propostas_router)

client = TestClient(app)

# ── Helpers ─────────────────────────────────────────────────────────────────

def fake_user(perfil: UserPerfil = UserPerfil.consultor, user_id=None):
    user = MagicMock()
    user.id = user_id or uuid.uuid4()
    user.perfil = perfil.value
    user.is_active = True
    user.email = "test@cadife.com"
    user.nome = "Test User"
    return user


def fake_lead(lead_id=None, consultor_id=None, status=LeadStatus.qualificado.value):
    lead = MagicMock()
    lead.id = lead_id or uuid.uuid4()
    lead.consultor_id = consultor_id
    lead.telefone = "5584999990001"
    lead.nome = "Lead Teste"
    lead.is_archived = False
    lead.status = status
    lead.origem = "whatsapp"
    lead.score = "quente"
    lead.consultor = None
    lead.consultor_nome = None
    lead.consultor_avatar = None
    return lead


def fake_proposta(proposta_id=None, lead_id=None, consultor_id=None, status=PropostaStatus.rascunho):
    proposta = MagicMock()
    proposta.id = proposta_id or uuid.uuid4()
    proposta.lead_id = lead_id or uuid.uuid4()
    proposta.descricao = "Pacote teste"
    proposta.valor_estimado = Decimal("15000.00")
    proposta.status = status.value
    proposta.consultor_id = consultor_id or uuid.uuid4()
    proposta.criado_em = "2026-04-28T10:00:00"
    return proposta


def make_db_session(proposta=None):
    """Return an AsyncMock session wired for add/commit/refresh/execute."""
    session = AsyncMock()
    session.commit = AsyncMock()
    session.refresh = AsyncMock()

    def _add_side_effect(obj):
        # Simulate DB-generated defaults so model_validate succeeds
        if hasattr(obj, "id") and obj.id is None:
            obj.id = uuid.uuid4()
        if hasattr(obj, "status") and obj.status is None:
            from app.domain.entities.enums import PropostaStatus
            obj.status = PropostaStatus.rascunho.value
        if hasattr(obj, "criado_em") and obj.criado_em is None:
            from datetime import datetime, timezone
            obj.criado_em = datetime.now(timezone.utc)

    session.add = MagicMock(side_effect=_add_side_effect)

    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = proposta
    session.execute = AsyncMock(return_value=mock_result)
    return session


# ── Fixtures ────────────────────────────────────────────────────────────────

@pytest.fixture(autouse=True)
def clear_overrides():
    """Ensure dependency overrides are cleaned after each test."""
    app.dependency_overrides.clear()
    yield
    app.dependency_overrides.clear()


# ══════════════════════════════════════════════════════════════════════════════
# POST /propostas
# ══════════════════════════════════════════════════════════════════════════════

class TestCreateProposta:

    def test_consultor_creates_for_own_lead(self):
        consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        lead = fake_lead(lead_id, consultor_id)
        proposta = fake_proposta(lead_id=lead_id, consultor_id=consultor_id)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(proposta)

        with patch("app.routes.propostas.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = client.post("/propostas", json={
                "lead_id": str(lead_id),
                "descricao": "Pacote teste",
                "valor_estimado": "15000.00",
            })

        assert response.status_code == 201
        data = response.json()
        assert data["lead_id"] == str(lead_id)
        assert data["status"] == PropostaStatus.rascunho.value

    def test_consultor_creates_without_valor_estimado(self):
        consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        lead = fake_lead(lead_id, consultor_id)
        proposta = fake_proposta(lead_id=lead_id, consultor_id=consultor_id)
        proposta.valor_estimado = None

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(proposta)

        with patch("app.routes.propostas.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = client.post("/propostas", json={
                "lead_id": str(lead_id),
                "descricao": "Pacote teste",
            })

        assert response.status_code == 201
        data = response.json()
        assert data["valor_estimado"] is None

    def test_admin_creates_for_any_lead(self):
        admin_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.admin, admin_id)
        lead = fake_lead(lead_id, consultor_id=uuid.uuid4())  # lead de outro consultor
        proposta = fake_proposta(lead_id=lead_id, consultor_id=admin_id)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(proposta)

        with patch("app.routes.propostas.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = client.post("/propostas", json={
                "lead_id": str(lead_id),
                "descricao": "Pacote admin",
            })

        assert response.status_code == 201

    def test_consultor_forbidden_for_other_lead(self):
        consultor_id = uuid.uuid4()
        other_consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        lead = fake_lead(lead_id, other_consultor_id)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session()

        with patch("app.routes.propostas.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = client.post("/propostas", json={
                "lead_id": str(lead_id),
                "descricao": "Pacote teste",
            })

        assert response.status_code == 403
        assert "Acesso negado" in response.json()["detail"]

    def test_create_returns_404_when_lead_missing(self):
        consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session()

        with patch("app.routes.propostas.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=None):
            response = client.post("/propostas", json={
                "lead_id": str(lead_id),
                "descricao": "Pacote teste",
            })

        assert response.status_code == 404
        assert "Lead não encontrado" in response.json()["detail"]

    def test_cliente_forbidden_to_create(self):
        user = fake_user(UserPerfil.cliente)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session()

        response = client.post("/propostas", json={
            "lead_id": str(uuid.uuid4()),
            "descricao": "Pacote teste",
        })

        assert response.status_code == 403
        assert "permissão insuficiente" in response.json()["detail"]

    def test_create_fails_when_lead_not_qualified(self):
        consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        lead = fake_lead(lead_id, consultor_id, status=LeadStatus.novo.value)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session()

        with patch("app.routes.propostas.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = client.post("/propostas", json={
                "lead_id": str(lead_id),
                "descricao": "Pacote teste",
            })

        assert response.status_code == 400
        assert "qualificado, agendado ou proposta" in response.json()["detail"]

    def test_create_succeeds_when_lead_in_proposta(self):
        consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        lead = fake_lead(lead_id, consultor_id, status=LeadStatus.proposta.value)
        proposta = fake_proposta(lead_id=lead_id, consultor_id=consultor_id)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(proposta)

        with patch("app.routes.propostas.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = client.post("/propostas", json={
                "lead_id": str(lead_id),
                "descricao": "Nova tentativa",
            })

        assert response.status_code == 201


# ══════════════════════════════════════════════════════════════════════════════
# GET /propostas/{id}
# ══════════════════════════════════════════════════════════════════════════════

class TestGetProposta:

    def test_consultor_gets_own_proposta(self):
        consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        proposta_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        lead = fake_lead(lead_id, consultor_id)
        proposta = fake_proposta(proposta_id, lead_id, consultor_id)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(proposta)

        with patch("app.routes.propostas.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = client.get(f"/propostas/{proposta_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(proposta_id)

    def test_get_returns_404_when_missing(self):
        user = fake_user(UserPerfil.admin)
        app.dependency_overrides[get_current_user] = lambda: user

        session = make_db_session()
        session.execute.return_value.scalar_one_or_none.return_value = None
        app.dependency_overrides[get_db] = lambda: session

        response = client.get(f"/propostas/{uuid.uuid4()}")
        assert response.status_code == 404
        assert "Proposta não encontrada" in response.json()["detail"]

    def test_consultor_forbidden_for_other_proposta(self):
        consultor_id = uuid.uuid4()
        other_consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        proposta_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        lead = fake_lead(lead_id, other_consultor_id)
        proposta = fake_proposta(proposta_id, lead_id, other_consultor_id)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(proposta)

        with patch("app.routes.propostas.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = client.get(f"/propostas/{proposta_id}")

        assert response.status_code == 403
        assert "Acesso negado" in response.json()["detail"]


# ══════════════════════════════════════════════════════════════════════════════
# PUT /propostas/{id}
# ══════════════════════════════════════════════════════════════════════════════

class TestUpdateProposta:

    def test_consultor_updates_own_proposta(self):
        consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        proposta_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        lead = fake_lead(lead_id, consultor_id)
        proposta = fake_proposta(proposta_id, lead_id, consultor_id)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(proposta)

        with patch("app.routes.propostas.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = client.put(f"/propostas/{proposta_id}", json={
                "status": PropostaStatus.enviada.value,
                "descricao": "Descrição atualizada",
            })

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == PropostaStatus.enviada.value
        assert data["descricao"] == "Descrição atualizada"

    def test_update_returns_404_when_missing(self):
        user = fake_user(UserPerfil.admin)
        app.dependency_overrides[get_current_user] = lambda: user

        session = make_db_session()
        session.execute.return_value.scalar_one_or_none.return_value = None
        app.dependency_overrides[get_db] = lambda: session

        response = client.put(f"/propostas/{uuid.uuid4()}", json={
            "status": PropostaStatus.enviada.value,
        })
        assert response.status_code == 404
        assert "Proposta não encontrada" in response.json()["detail"]

    def test_consultor_forbidden_to_update_other_proposta(self):
        consultor_id = uuid.uuid4()
        other_consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        proposta_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        lead = fake_lead(lead_id, other_consultor_id)
        proposta = fake_proposta(proposta_id, lead_id, other_consultor_id)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(proposta)

        with patch("app.routes.propostas.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = client.put(f"/propostas/{proposta_id}", json={
                "status": PropostaStatus.enviada.value,
            })

        assert response.status_code == 403
        assert "Acesso negado" in response.json()["detail"]

    def test_update_with_valor_estimado(self):
        consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        proposta_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        lead = fake_lead(lead_id, consultor_id)
        proposta = fake_proposta(proposta_id, lead_id, consultor_id)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(proposta)

        with patch("app.routes.propostas.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = client.put(f"/propostas/{proposta_id}", json={
                "valor_estimado": "25000.50",
            })

        assert response.status_code == 200
        data = response.json()
        assert data["valor_estimado"] == "25000.50"

    def test_approve_proposta_closes_lead(self):
        consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        proposta_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        lead = fake_lead(lead_id, consultor_id, status=LeadStatus.proposta.value)
        proposta = fake_proposta(proposta_id, lead_id, consultor_id, status=PropostaStatus.enviada)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(proposta)

        with patch("app.routes.propostas.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = client.put(f"/propostas/{proposta_id}", json={
                "status": PropostaStatus.aprovada.value,
            })

        assert response.status_code == 200
        assert lead.status == LeadStatus.fechado.value

    def test_reject_proposta_keeps_lead_in_proposta(self):
        consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        proposta_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        lead = fake_lead(lead_id, consultor_id, status=LeadStatus.proposta.value)
        proposta = fake_proposta(proposta_id, lead_id, consultor_id, status=PropostaStatus.enviada)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(proposta)

        with patch("app.routes.propostas.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = client.put(f"/propostas/{proposta_id}", json={
                "status": PropostaStatus.recusada.value,
            })

        assert response.status_code == 200
        assert lead.status == LeadStatus.proposta.value


# ══════════════════════════════════════════════════════════════════════════════
# GET /leads/{id} — propostas relation
# ══════════════════════════════════════════════════════════════════════════════

class TestLeadPropostasRelation:

    def test_lead_response_includes_propostas(self):
        consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        lead = fake_lead(lead_id, consultor_id, status=LeadStatus.proposta.value)
        proposta1 = fake_proposta(uuid.uuid4(), lead_id, consultor_id, PropostaStatus.enviada)
        proposta2 = fake_proposta(uuid.uuid4(), lead_id, consultor_id, PropostaStatus.rascunho)
        lead.propostas = [proposta1, proposta2]

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session()

        with patch("app.routes.leads.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = client.get(f"/leads/{lead_id}")

        assert response.status_code == 200
        data = response.json()
        assert "propostas" in data
        assert len(data["propostas"]) == 2
        assert data["propostas"][0]["status"] == PropostaStatus.enviada.value
        assert data["propostas"][1]["status"] == PropostaStatus.rascunho.value
