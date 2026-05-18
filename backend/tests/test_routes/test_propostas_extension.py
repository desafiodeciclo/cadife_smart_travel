"""
Tests — Routes/Propostas Extension (gap §3.4)
==============================================
Covers PATCH, DELETE, POST /enviar, GET /versoes added in this delivery.

Pattern follows test_propostas.py (TestClient + dependency_overrides + AsyncMock).
"""

import uuid
from decimal import Decimal
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.core.dependencies import get_current_user, get_db
from app.domain.entities.enums import LeadStatus, PropostaStatus, UserPerfil
from app.routes.propostas import router as propostas_router

# Pre-import all SQLAlchemy models so relationships resolve correctly
import app.models.agendamento  # noqa: F401
import app.models.briefing  # noqa: F401
import app.models.interacao  # noqa: F401
import app.models.lead  # noqa: F401
import app.models.proposta  # noqa: F401
import app.models.user  # noqa: F401

app = FastAPI()
app.include_router(propostas_router)
client = TestClient(app)


class _FakeAsyncSessionLocal:
    """Dummy async_sessionmaker for background task tests."""

    async def __aenter__(self):
        session = AsyncMock()
        session.commit = AsyncMock()
        session.refresh = AsyncMock()
        session.rollback = AsyncMock()
        session.add = MagicMock()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        session.execute = AsyncMock(return_value=mock_result)
        return session

    async def __aexit__(self, exc_type, exc, tb):
        pass


# ── Helpers ────────────────────────────────────────────────────────────────


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
    return lead


def fake_proposta(
    *,
    proposta_id=None,
    lead_id=None,
    consultor_id=None,
    status=PropostaStatus.rascunho,
    deletado_em=None,
    enviado_em=None,
    notificacao_enviada_em=None,
):
    proposta = MagicMock()
    proposta.id = proposta_id or uuid.uuid4()
    proposta.lead_id = lead_id or uuid.uuid4()
    proposta.descricao = "Pacote teste"
    proposta.valor_estimado = Decimal("15000.00")
    proposta.status = status
    proposta.consultor_id = consultor_id or uuid.uuid4()
    proposta.expiration_hours = 48
    proposta.criado_em = datetime.now(timezone.utc)
    proposta.deletado_em = deletado_em
    proposta.deletado_por = None
    proposta.enviado_em = enviado_em
    proposta.notificacao_enviada_em = notificacao_enviada_em
    return proposta


def make_db_session(scalar_one_value=None, scalars_all=None):
    """AsyncMock session that returns scalar_one_value for execute().scalar_one_or_none()."""
    session = AsyncMock()
    session.commit = AsyncMock()
    session.flush = AsyncMock()
    session.refresh = AsyncMock()
    session.rollback = AsyncMock()
    session.add = MagicMock()
    session.scalar = AsyncMock(return_value=0)  # for next_numero_versao queries

    mock_scalars = MagicMock()
    mock_scalars.all.return_value = scalars_all or []
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = scalar_one_value
    mock_result.scalars.return_value = mock_scalars
    session.execute = AsyncMock(return_value=mock_result)
    return session


@pytest.fixture(autouse=True)
def clear_overrides():
    app.dependency_overrides.clear()
    yield
    app.dependency_overrides.clear()


# ══════════════════════════════════════════════════════════════════════════════
# PATCH /propostas/{id}
# ══════════════════════════════════════════════════════════════════════════════


class TestPatchProposta:

    def test_patch_descricao_only_ok(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        proposta = fake_proposta(consultor_id=consultor_id)
        lead = fake_lead(lead_id=proposta.lead_id, consultor_id=consultor_id)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        with patch(
            "app.routes.propostas.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
            return_value=lead,
        ), patch(
            "app.routes.propostas.proposta_versao_service.snapshot",
            new_callable=AsyncMock,
        ) as mock_snap:
            response = client.patch(
                f"/propostas/{proposta.id}", json={"descricao": "Nova descrição"}
            )
        assert response.status_code == 200
        mock_snap.assert_called_once()
        # snapshot motivo deve ser 'edicao'
        assert mock_snap.call_args.kwargs.get("motivo") == "edicao"

    def test_patch_with_no_fields_returns_422(self):
        user = fake_user(UserPerfil.consultor)
        proposta = fake_proposta(consultor_id=user.id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        response = client.patch(f"/propostas/{proposta.id}", json={})
        assert response.status_code == 422

    def test_patch_status_field_rejected_by_schema(self):
        """Schema PropostaPatchRequest does NOT have status field."""
        user = fake_user(UserPerfil.consultor)
        proposta = fake_proposta(consultor_id=user.id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        # Pydantic ignores unknown fields by default (extra="ignore"), so status is silently dropped
        # but at least one of the known fields must be set.
        with patch(
            "app.routes.propostas.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
            return_value=fake_lead(lead_id=proposta.lead_id, consultor_id=user.id),
        ), patch(
            "app.routes.propostas.proposta_versao_service.snapshot",
            new_callable=AsyncMock,
        ):
            response = client.patch(
                f"/propostas/{proposta.id}",
                json={"status": "enviada", "descricao": "x"},
            )
        # descricao is set so 200; status is ignored (proposta.status unchanged)
        assert response.status_code == 200
        assert proposta.status == PropostaStatus.rascunho  # unchanged

    def test_patch_already_sent_returns_409(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        proposta = fake_proposta(
            consultor_id=consultor_id, status=PropostaStatus.enviada
        )
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        with patch(
            "app.routes.propostas.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
            return_value=fake_lead(lead_id=proposta.lead_id, consultor_id=consultor_id),
        ):
            response = client.patch(
                f"/propostas/{proposta.id}", json={"descricao": "x"}
            )
        assert response.status_code == 409

    def test_patch_other_consultor_403(self):
        user = fake_user(UserPerfil.consultor, uuid.uuid4())
        proposta = fake_proposta(consultor_id=uuid.uuid4())  # different consultor
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        response = client.patch(f"/propostas/{proposta.id}", json={"descricao": "x"})
        assert response.status_code == 403

    def test_patch_404_when_not_found(self):
        user = fake_user(UserPerfil.consultor)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=None)

        response = client.patch(f"/propostas/{uuid.uuid4()}", json={"descricao": "x"})
        assert response.status_code == 404


# ══════════════════════════════════════════════════════════════════════════════
# DELETE /propostas/{id}
# ══════════════════════════════════════════════════════════════════════════════


class TestDeleteProposta:

    def test_delete_rascunho_ok(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        proposta = fake_proposta(consultor_id=consultor_id, status=PropostaStatus.rascunho)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        with patch(
            "app.routes.propostas.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
            return_value=fake_lead(lead_id=proposta.lead_id, consultor_id=consultor_id),
        ), patch(
            "app.routes.propostas.proposta_versao_service.snapshot",
            new_callable=AsyncMock,
        ) as mock_snap:
            response = client.delete(f"/propostas/{proposta.id}")
        assert response.status_code == 204
        assert proposta.deletado_em is not None
        mock_snap.assert_called_once()
        assert mock_snap.call_args.kwargs.get("motivo") == "cancelamento"

    def test_delete_aprovada_returns_409(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        proposta = fake_proposta(
            consultor_id=consultor_id, status=PropostaStatus.aprovada
        )
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        with patch(
            "app.routes.propostas.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
            return_value=fake_lead(lead_id=proposta.lead_id, consultor_id=consultor_id),
        ):
            response = client.delete(f"/propostas/{proposta.id}")
        assert response.status_code == 409

    def test_delete_already_deleted_idempotent(self):
        user = fake_user(UserPerfil.consultor)
        proposta = fake_proposta(
            consultor_id=user.id, deletado_em=datetime.now(timezone.utc)
        )
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        response = client.delete(f"/propostas/{proposta.id}")
        assert response.status_code == 204

    def test_delete_other_consultor_403(self):
        user = fake_user(UserPerfil.consultor, uuid.uuid4())
        proposta = fake_proposta(consultor_id=uuid.uuid4())
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        response = client.delete(f"/propostas/{proposta.id}")
        assert response.status_code == 403

    def test_delete_404_when_not_found(self):
        user = fake_user(UserPerfil.consultor)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=None)

        response = client.delete(f"/propostas/{uuid.uuid4()}")
        assert response.status_code == 404


# ══════════════════════════════════════════════════════════════════════════════
# POST /propostas/{id}/enviar
# ══════════════════════════════════════════════════════════════════════════════


class TestEnviarProposta:

    def test_enviar_rascunho_ok(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        proposta = fake_proposta(consultor_id=consultor_id, status=PropostaStatus.rascunho)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        with patch(
            "app.routes.propostas.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
            return_value=fake_lead(lead_id=proposta.lead_id, consultor_id=consultor_id),
        ), patch(
            "app.routes.propostas.proposta_versao_service.snapshot",
            new_callable=AsyncMock,
        ) as mock_snap, patch(
            "app.infrastructure.persistence.database.AsyncSessionLocal", _FakeAsyncSessionLocal
        ):
            response = client.post(f"/propostas/{proposta.id}/enviar")
        assert response.status_code == 200
        assert proposta.status == PropostaStatus.enviada
        assert proposta.enviado_em is not None
        mock_snap.assert_called_once()
        assert mock_snap.call_args.kwargs.get("motivo") == "envio"

    def test_enviar_idempotente_already_sent(self):
        """Second call to /enviar must NOT trigger a new snapshot or notification."""
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        already_sent_at = datetime.now(timezone.utc)
        proposta = fake_proposta(
            consultor_id=consultor_id,
            status=PropostaStatus.enviada,
            enviado_em=already_sent_at,
        )
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        with patch(
            "app.routes.propostas.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
            return_value=fake_lead(lead_id=proposta.lead_id, consultor_id=consultor_id),
        ), patch(
            "app.routes.propostas.proposta_versao_service.snapshot",
            new_callable=AsyncMock,
        ) as mock_snap:
            response = client.post(f"/propostas/{proposta.id}/enviar")
        assert response.status_code == 200
        # No new snapshot on idempotent call
        mock_snap.assert_not_called()

    def test_enviar_aprovada_returns_409(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        proposta = fake_proposta(
            consultor_id=consultor_id, status=PropostaStatus.aprovada
        )
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        with patch(
            "app.routes.propostas.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
            return_value=fake_lead(lead_id=proposta.lead_id, consultor_id=consultor_id),
        ):
            response = client.post(f"/propostas/{proposta.id}/enviar")
        assert response.status_code == 409

    def test_enviar_recusada_returns_409(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        proposta = fake_proposta(
            consultor_id=consultor_id, status=PropostaStatus.recusada
        )
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        with patch(
            "app.routes.propostas.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
            return_value=fake_lead(lead_id=proposta.lead_id, consultor_id=consultor_id),
        ):
            response = client.post(f"/propostas/{proposta.id}/enviar")
        assert response.status_code == 409

    def test_enviar_other_consultor_403(self):
        user = fake_user(UserPerfil.consultor, uuid.uuid4())
        proposta = fake_proposta(consultor_id=uuid.uuid4())
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        response = client.post(f"/propostas/{proposta.id}/enviar")
        assert response.status_code == 403


# ══════════════════════════════════════════════════════════════════════════════
# GET /propostas/{id}/versoes
# ══════════════════════════════════════════════════════════════════════════════


class TestListVersoes:

    def test_versoes_returns_list_for_owner(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        proposta = fake_proposta(consultor_id=consultor_id)

        v1 = MagicMock()
        v1.id = uuid.uuid4()
        v1.proposta_id = proposta.id
        v1.numero_versao = 2
        v1.motivo = "edicao"
        v1.snapshot_json = {"descricao": "v2"}
        v1.created_by = consultor_id
        v1.created_at = datetime.now(timezone.utc)

        v2 = MagicMock()
        v2.id = uuid.uuid4()
        v2.proposta_id = proposta.id
        v2.numero_versao = 1
        v2.motivo = "criacao"
        v2.snapshot_json = {"descricao": "v1"}
        v2.created_by = consultor_id
        v2.created_at = datetime.now(timezone.utc)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        with patch(
            "app.routes.propostas.proposta_versao_service.list_by_proposta",
            new_callable=AsyncMock,
            return_value=[v1, v2],
        ):
            response = client.get(f"/propostas/{proposta.id}/versoes")
        assert response.status_code == 200
        body = response.json()
        assert body["total"] == 2
        assert body["items"][0]["numero_versao"] == 2  # DESC
        assert body["items"][0]["motivo"] == "edicao"
        assert body["items"][1]["numero_versao"] == 1
        assert body["items"][1]["motivo"] == "criacao"

    def test_versoes_404(self):
        user = fake_user(UserPerfil.consultor)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=None)

        response = client.get(f"/propostas/{uuid.uuid4()}/versoes")
        assert response.status_code == 404

    def test_versoes_admin_can_see(self):
        admin = fake_user(UserPerfil.admin)
        proposta = fake_proposta(consultor_id=uuid.uuid4())  # not admin's
        app.dependency_overrides[get_current_user] = lambda: admin
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=proposta)

        with patch(
            "app.routes.propostas.proposta_versao_service.list_by_proposta",
            new_callable=AsyncMock,
            return_value=[],
        ):
            response = client.get(f"/propostas/{proposta.id}/versoes")
        assert response.status_code == 200


# ══════════════════════════════════════════════════════════════════════════════
# OpenAPI deprecation flags
# ══════════════════════════════════════════════════════════════════════════════


class TestOpenAPIDeprecation:

    def test_put_marked_deprecated(self):
        spec = client.get("/openapi.json").json()
        put_op = spec["paths"]["/propostas/{proposta_id}"]["put"]
        assert put_op.get("deprecated") is True

    def test_patch_not_deprecated(self):
        spec = client.get("/openapi.json").json()
        patch_op = spec["paths"]["/propostas/{proposta_id}"]["patch"]
        assert patch_op.get("deprecated") is not True

    def test_enviar_endpoint_exists(self):
        spec = client.get("/openapi.json").json()
        assert "/propostas/{proposta_id}/enviar" in spec["paths"]
        assert "post" in spec["paths"]["/propostas/{proposta_id}/enviar"]

    def test_versoes_endpoint_exists(self):
        spec = client.get("/openapi.json").json()
        assert "/propostas/{proposta_id}/versoes" in spec["paths"]
        assert "get" in spec["paths"]["/propostas/{proposta_id}/versoes"]
