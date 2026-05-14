"""
Tests — Routes/Agenda
=====================
Integration tests for the extended agenda API (gap §3.5).

Covers:
  - GET    /agenda?data=YYYY-MM-DD          (NEW)
  - GET    /agenda/disponibilidade?data=
  - GET    /agenda/slots?data=              (deprecated alias)
  - POST   /agenda                          (curadoria + bloqueio)
  - GET    /agenda/{id}
  - PATCH  /agenda/{id}                     (NEW)
  - PUT    /agenda/{id}                     (legacy alias)
  - DELETE /agenda/{id}                     (NEW soft-cancel)

  + query param ?data vs ?date deprecation
  + bloqueio constraints (no lead_id, motivo required)
  + role-based scope (consultor vs admin)
"""

import uuid
from datetime import date, datetime, time, timedelta, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.core.dependencies import get_current_user, get_db
from app.domain.entities.enums import (
    AgendamentoStatus,
    AgendamentoTipo,
    LeadStatus,
    MotivoBloqueio,
)
from app.models.user import UserPerfil
from app.routes.agenda import router as agenda_router

# Pre-import all SQLAlchemy models so relationships resolve correctly
import app.models.agendamento  # noqa: F401
import app.models.briefing  # noqa: F401
import app.models.interacao  # noqa: F401
import app.models.lead  # noqa: F401
import app.models.proposta  # noqa: F401
import app.models.user  # noqa: F401

app = FastAPI()
app.include_router(agenda_router)
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
    return lead


def fake_agendamento(
    *,
    ag_id=None,
    lead_id=None,
    consultor_id=None,
    data_=None,
    hora_=None,
    status_=AgendamentoStatus.pendente,
    tipo=AgendamentoTipo.online,
    motivo_bloqueio=None,
    notas=None,
):
    ag = MagicMock()
    ag.id = ag_id or uuid.uuid4()
    ag.lead_id = lead_id
    ag.consultor_id = consultor_id or uuid.uuid4()
    ag.data = data_ or _next_business_day()
    ag.hora = hora_ or time(10, 0)
    ag.status = status_
    ag.tipo = tipo
    ag.motivo_bloqueio = motivo_bloqueio
    ag.notas = notas
    ag.cancelado_em = None
    ag.motivo_cancelamento = None
    ag.criado_em = datetime.now(timezone.utc)
    return ag


def _next_business_day(reference: date | None = None) -> date:
    """Return a date that is guaranteed to be a weekday (Mon-Fri)."""
    d = reference or date(2026, 6, 8)  # Monday
    while d.weekday() >= 5:
        d = d + timedelta(days=1)
    return d


def make_db_session(scalar_one_value=None, scalars_all=None, *, capture_added=None):
    """Build an AsyncMock session covering execute().scalars() and scalar_one_or_none()."""
    session = AsyncMock()
    session.commit = AsyncMock()
    session.refresh = AsyncMock()
    session.rollback = AsyncMock()

    def _add_side_effect(obj):
        if capture_added is not None:
            capture_added.append(obj)
        if hasattr(obj, "id") and obj.id is None:
            obj.id = uuid.uuid4()
        if hasattr(obj, "criado_em") and obj.criado_em is None:
            obj.criado_em = datetime.now(timezone.utc)
        if hasattr(obj, "status") and obj.status is None:
            obj.status = AgendamentoStatus.pendente

    session.add = MagicMock(side_effect=_add_side_effect)

    mock_scalars = MagicMock()
    mock_scalars.all.return_value = scalars_all or []
    mock_result = MagicMock()
    mock_result.scalars.return_value = mock_scalars
    mock_result.scalar_one_or_none.return_value = scalar_one_value
    session.execute = AsyncMock(return_value=mock_result)
    return session


@pytest.fixture(autouse=True)
def clear_overrides():
    app.dependency_overrides.clear()
    yield
    app.dependency_overrides.clear()


# ══════════════════════════════════════════════════════════════════════════════
# GET /agenda?data=
# ══════════════════════════════════════════════════════════════════════════════


class TestListAgendamentosByDate:

    def test_consultor_lists_own_for_data(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(consultor_id=consultor_id, hora_=time(10, 0))
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalars_all=[ag])

        response = client.get(f"/agenda?data={ag.data.isoformat()}")

        assert response.status_code == 200
        body = response.json()
        assert body["total"] == 1
        assert body["data"] == ag.data.isoformat()
        assert len(body["items"]) == 1

    def test_admin_can_filter_by_consultor_id(self):
        admin = fake_user(UserPerfil.admin)
        target_consultor = uuid.uuid4()
        ag = fake_agendamento(consultor_id=target_consultor, hora_=time(11, 0))
        app.dependency_overrides[get_current_user] = lambda: admin
        app.dependency_overrides[get_db] = lambda: make_db_session(scalars_all=[ag])

        response = client.get(
            f"/agenda?data={ag.data.isoformat()}&consultor_id={target_consultor}"
        )
        assert response.status_code == 200
        assert response.json()["total"] == 1

    def test_data_required(self):
        user = fake_user(UserPerfil.consultor)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session()

        response = client.get("/agenda")
        assert response.status_code == 422

    def test_legacy_date_param_still_works(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(consultor_id=consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalars_all=[ag])

        # Use the deprecated ?date= param — should still return 200
        response = client.get(f"/agenda?date={ag.data.isoformat()}")
        assert response.status_code == 200
        assert response.json()["data"] == ag.data.isoformat()

    def test_returns_empty_list_when_no_appointments(self):
        user = fake_user(UserPerfil.consultor)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalars_all=[])

        response = client.get(f"/agenda?data={_next_business_day().isoformat()}")
        assert response.status_code == 200
        assert response.json()["total"] == 0
        assert response.json()["items"] == []


# ══════════════════════════════════════════════════════════════════════════════
# GET /agenda/disponibilidade
# ══════════════════════════════════════════════════════════════════════════════


class TestDisponibilidade:

    def test_returns_six_slots_on_business_day_when_empty(self):
        user = fake_user(UserPerfil.consultor)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalars_all=[])

        response = client.get(
            f"/agenda/disponibilidade?data={_next_business_day().isoformat()}"
        )
        assert response.status_code == 200
        slots = response.json()["slots"]
        # 09, 10, 11, 12, 13, 14, 15 = 7 slots between 09:00..15:00 step 1h
        # Actually range stops at 15:00 since slot start must be < 16:00 ⇒ 09..15 inclusive = 7
        assert len(slots) == 7
        assert all(s["disponivel"] for s in slots)

    def test_weekend_returns_empty(self):
        user = fake_user(UserPerfil.consultor)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session()

        # 2026-06-13 is a Saturday
        response = client.get("/agenda/disponibilidade?data=2026-06-13")
        assert response.status_code == 200
        assert response.json()["slots"] == []

    def test_blocked_slot_marks_unavailable(self):
        """A bloqueio at 14:00 should make the 14:00 slot unavailable."""
        user = fake_user(UserPerfil.consultor)
        bloqueio = fake_agendamento(
            tipo=AgendamentoTipo.bloqueio,
            lead_id=None,
            motivo_bloqueio=MotivoBloqueio.pausa,
            hora_=time(14, 0),
        )
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalars_all=[bloqueio])

        response = client.get(
            f"/agenda/disponibilidade?data={bloqueio.data.isoformat()}"
        )
        assert response.status_code == 200
        slots = response.json()["slots"]
        slot_14 = next(s for s in slots if s["hora"] == "14:00")
        assert slot_14["disponivel"] is False


# ══════════════════════════════════════════════════════════════════════════════
# GET /agenda/slots (deprecated alias)
# ══════════════════════════════════════════════════════════════════════════════


class TestSlotsAlias:

    def test_slots_alias_returns_same_payload_as_disponibilidade(self):
        user = fake_user(UserPerfil.consultor)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalars_all=[])

        d = _next_business_day().isoformat()
        a = client.get(f"/agenda/slots?data={d}")
        b = client.get(f"/agenda/disponibilidade?data={d}")
        assert a.status_code == 200
        assert b.status_code == 200
        assert a.json() == b.json()

    def test_openapi_marks_slots_deprecated(self):
        spec = client.get("/openapi.json").json()
        slots_path = spec["paths"]["/agenda/slots"]["get"]
        assert slots_path.get("deprecated") is True


# ══════════════════════════════════════════════════════════════════════════════
# POST /agenda — curadoria
# ══════════════════════════════════════════════════════════════════════════════


class TestCreateCuradoria:

    def test_create_curadoria_ok(self):
        consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        lead = fake_lead(lead_id, consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalars_all=[])

        with patch(
            "app.routes.agenda.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
            return_value=lead,
        ):
            response = client.post(
                "/agenda",
                json={
                    "lead_id": str(lead_id),
                    "data": _next_business_day().isoformat(),
                    "hora": "10:00:00",
                    "tipo": "online",
                },
            )

        assert response.status_code == 201
        body = response.json()
        assert body["lead_id"] == str(lead_id)
        assert body["tipo"] == "online"

    def test_create_weekend_rejected(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session()

        response = client.post(
            "/agenda",
            json={
                "lead_id": str(uuid.uuid4()),
                "data": "2026-06-13",  # Saturday
                "hora": "10:00:00",
                "tipo": "online",
            },
        )
        assert response.status_code == 422

    def test_create_off_hour_rejected(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session()

        response = client.post(
            "/agenda",
            json={
                "lead_id": str(uuid.uuid4()),
                "data": _next_business_day().isoformat(),
                "hora": "08:30:00",  # Before 09:00, not aligned
                "tipo": "online",
            },
        )
        assert response.status_code == 422

    def test_create_curadoria_without_lead_id_rejected(self):
        user = fake_user(UserPerfil.consultor)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session()

        response = client.post(
            "/agenda",
            json={
                "data": _next_business_day().isoformat(),
                "hora": "10:00:00",
                "tipo": "online",
                # no lead_id
            },
        )
        assert response.status_code == 422

    def test_create_curadoria_lead_not_found(self):
        consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session()

        with patch(
            "app.routes.agenda.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
            return_value=None,
        ):
            response = client.post(
                "/agenda",
                json={
                    "lead_id": str(lead_id),
                    "data": _next_business_day().isoformat(),
                    "hora": "10:00:00",
                    "tipo": "online",
                },
            )
        assert response.status_code == 404

    def test_create_curadoria_slot_conflict_returns_409(self):
        consultor_id = uuid.uuid4()
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        lead = fake_lead(lead_id, consultor_id)
        existing = fake_agendamento(
            consultor_id=consultor_id, hora_=time(10, 0)
        )
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalars_all=[existing])

        with patch(
            "app.routes.agenda.lead_service.get_lead_by_id",
            new_callable=AsyncMock,
            return_value=lead,
        ):
            response = client.post(
                "/agenda",
                json={
                    "lead_id": str(lead_id),
                    "data": existing.data.isoformat(),
                    "hora": "10:00:00",
                    "tipo": "online",
                },
            )
        assert response.status_code == 409


# ══════════════════════════════════════════════════════════════════════════════
# POST /agenda — bloqueio
# ══════════════════════════════════════════════════════════════════════════════


class TestCreateBloqueio:

    def test_create_bloqueio_without_lead_ok(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalars_all=[])

        response = client.post(
            "/agenda",
            json={
                "data": _next_business_day().isoformat(),
                "hora": "12:00:00",
                "tipo": "bloqueio",
                "motivo_bloqueio": "pausa",
            },
        )
        assert response.status_code == 201
        body = response.json()
        assert body["tipo"] == "bloqueio"
        assert body["motivo_bloqueio"] == "pausa"
        assert body["lead_id"] is None

    def test_create_bloqueio_with_lead_id_rejected(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session()

        response = client.post(
            "/agenda",
            json={
                "lead_id": str(uuid.uuid4()),
                "data": _next_business_day().isoformat(),
                "hora": "12:00:00",
                "tipo": "bloqueio",
                "motivo_bloqueio": "outro",
            },
        )
        assert response.status_code == 422

    def test_create_bloqueio_without_motivo_rejected(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session()

        response = client.post(
            "/agenda",
            json={
                "data": _next_business_day().isoformat(),
                "hora": "12:00:00",
                "tipo": "bloqueio",
                # no motivo_bloqueio
            },
        )
        assert response.status_code == 422


# ══════════════════════════════════════════════════════════════════════════════
# PATCH /agenda/{id}
# ══════════════════════════════════════════════════════════════════════════════


class TestPatchAgendamento:

    def test_patch_notas_only_no_slot_revalidation(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(consultor_id=consultor_id, hora_=time(10, 0))
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=ag)

        response = client.patch(
            f"/agenda/{ag.id}", json={"notas": "Nota interna do consultor"}
        )
        assert response.status_code == 200

    def test_patch_change_hora_to_free_slot_ok(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(consultor_id=consultor_id, hora_=time(10, 0))

        # `_load_agendamento_or_404` does scalar_one_or_none on first execute(),
        # then `_buscar_agendamentos_do_dia` does scalars().all() on later execute().
        # Our mock returns the same MagicMock for both — scalars().all() returns []
        # so no conflict.
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(
            scalar_one_value=ag, scalars_all=[]
        )

        response = client.patch(
            f"/agenda/{ag.id}", json={"hora": "11:00:00"}
        )
        assert response.status_code == 200

    def test_patch_status_cancelado_rejected(self):
        """PATCH must NOT allow status=cancelado — use DELETE."""
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(consultor_id=consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=ag)

        response = client.patch(
            f"/agenda/{ag.id}", json={"status": "cancelado"}
        )
        assert response.status_code == 422

    def test_patch_already_cancelled_returns_409(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(
            consultor_id=consultor_id, status_=AgendamentoStatus.cancelado
        )
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=ag)

        response = client.patch(f"/agenda/{ag.id}", json={"notas": "tarde demais"})
        assert response.status_code == 409

    def test_patch_already_realized_returns_409(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(
            consultor_id=consultor_id, status_=AgendamentoStatus.realizado
        )
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=ag)

        response = client.patch(f"/agenda/{ag.id}", json={"notas": "atrasado"})
        assert response.status_code == 409

    def test_patch_other_consultor_forbidden(self):
        consultor_id = uuid.uuid4()
        other = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(consultor_id=other)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=ag)

        response = client.patch(f"/agenda/{ag.id}", json={"notas": "..."})
        assert response.status_code == 403

    def test_patch_404_when_not_found(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=None)

        response = client.patch(
            f"/agenda/{uuid.uuid4()}", json={"notas": "x"}
        )
        assert response.status_code == 404


# ══════════════════════════════════════════════════════════════════════════════
# DELETE /agenda/{id}
# ══════════════════════════════════════════════════════════════════════════════


class TestDeleteAgendamento:

    def test_cancel_pendente_ok(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(consultor_id=consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=ag)

        response = client.delete(f"/agenda/{ag.id}")
        assert response.status_code == 204
        assert ag.status == AgendamentoStatus.cancelado
        assert ag.cancelado_em is not None

    def test_cancel_with_motivo_persists(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(consultor_id=consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=ag)

        response = client.request(
            "DELETE",
            f"/agenda/{ag.id}",
            json={"motivo": "cliente desmarcou"},
        )
        assert response.status_code == 204
        assert ag.motivo_cancelamento == "cliente desmarcou"

    def test_cancel_realizado_returns_409(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(
            consultor_id=consultor_id, status_=AgendamentoStatus.realizado
        )
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=ag)

        response = client.delete(f"/agenda/{ag.id}")
        assert response.status_code == 409

    def test_cancel_idempotent_already_cancelled(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(
            consultor_id=consultor_id, status_=AgendamentoStatus.cancelado
        )
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=ag)

        response = client.delete(f"/agenda/{ag.id}")
        assert response.status_code == 204

    def test_cancel_other_consultor_forbidden(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(consultor_id=uuid.uuid4())
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=ag)

        response = client.delete(f"/agenda/{ag.id}")
        assert response.status_code == 403

    def test_cancel_404_when_not_found(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=None)

        response = client.delete(f"/agenda/{uuid.uuid4()}")
        assert response.status_code == 404


# ══════════════════════════════════════════════════════════════════════════════
# PUT /agenda/{id} (deprecated)
# ══════════════════════════════════════════════════════════════════════════════


class TestPutDeprecated:

    def test_put_status_still_works(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(consultor_id=consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=ag)

        response = client.put(f"/agenda/{ag.id}", json={"status": "confirmado"})
        assert response.status_code == 200
        assert ag.status == AgendamentoStatus.confirmado

    def test_put_status_cancelado_redirects_to_delete_semantics(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(consultor_id=consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=ag)

        response = client.put(f"/agenda/{ag.id}", json={"status": "cancelado"})
        # PUT cancelado is now equivalent to DELETE → 204
        assert response.status_code == 204

    def test_openapi_marks_put_deprecated(self):
        spec = client.get("/openapi.json").json()
        put_op = spec["paths"]["/agenda/{agendamento_id}"]["put"]
        assert put_op.get("deprecated") is True


# ══════════════════════════════════════════════════════════════════════════════
# GET /agenda/{id}
# ══════════════════════════════════════════════════════════════════════════════


class TestGetAgendamentoDetail:

    def test_detail_ok(self):
        consultor_id = uuid.uuid4()
        user = fake_user(UserPerfil.consultor, consultor_id)
        ag = fake_agendamento(consultor_id=consultor_id)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=ag)

        response = client.get(f"/agenda/{ag.id}")
        assert response.status_code == 200
        assert response.json()["id"] == str(ag.id)

    def test_detail_404(self):
        user = fake_user(UserPerfil.consultor)
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: make_db_session(scalar_one_value=None)

        response = client.get(f"/agenda/{uuid.uuid4()}")
        assert response.status_code == 404
