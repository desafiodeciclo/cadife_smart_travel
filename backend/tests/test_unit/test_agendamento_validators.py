"""
Unit tests — Agendamento Pydantic model validators
====================================================
Validates business rules enforced by @model_validator without requiring
a database connection.
"""

import uuid
from datetime import date, time

import pytest
from pydantic import ValidationError

from app.domain.entities.enums import AgendamentoTipo, MotivoBloqueio
from app.presentation.schemas.agendamento_schema import AgendamentoCreate, AgendamentoPatch


class TestAgendamentoCreateValidator:

    def test_curadoria_online_with_lead_ok(self):
        payload = {
            "lead_id": str(uuid.uuid4()),
            "data": date(2026, 6, 8),
            "hora": time(10, 0),
            "tipo": "online",
        }
        obj = AgendamentoCreate(**payload)
        assert obj.tipo == AgendamentoTipo.online
        assert obj.lead_id is not None

    def test_curadoria_presencial_with_lead_ok(self):
        payload = {
            "lead_id": str(uuid.uuid4()),
            "data": date(2026, 6, 8),
            "hora": time(10, 0),
            "tipo": "presencial",
        }
        obj = AgendamentoCreate(**payload)
        assert obj.tipo == AgendamentoTipo.presencial

    def test_bloqueio_without_lead_ok(self):
        payload = {
            "data": date(2026, 6, 8),
            "hora": time(12, 0),
            "tipo": "bloqueio",
            "motivo_bloqueio": "pausa",
        }
        obj = AgendamentoCreate(**payload)
        assert obj.tipo == AgendamentoTipo.bloqueio
        assert obj.lead_id is None

    def test_bloqueio_with_lead_fails(self):
        payload = {
            "lead_id": str(uuid.uuid4()),
            "data": date(2026, 6, 8),
            "hora": time(12, 0),
            "tipo": "bloqueio",
            "motivo_bloqueio": "pausa",
        }
        with pytest.raises(ValidationError) as exc_info:
            AgendamentoCreate(**payload)
        assert "Bloqueio não pode ter lead_id" in str(exc_info.value)

    def test_bloqueio_without_motivo_fails(self):
        payload = {
            "data": date(2026, 6, 8),
            "hora": time(12, 0),
            "tipo": "bloqueio",
        }
        with pytest.raises(ValidationError) as exc_info:
            AgendamentoCreate(**payload)
        assert "Bloqueio exige motivo_bloqueio" in str(exc_info.value)

    def test_curadoria_without_lead_fails(self):
        payload = {
            "data": date(2026, 6, 8),
            "hora": time(10, 0),
            "tipo": "online",
        }
        with pytest.raises(ValidationError) as exc_info:
            AgendamentoCreate(**payload)
        assert "Curadoria (online/presencial) exige lead_id" in str(exc_info.value)


class TestAgendamentoPatchValidator:

    def test_patch_status_cancelado_fails(self):
        payload = {"status": "cancelado"}
        with pytest.raises(ValidationError) as exc_info:
            AgendamentoPatch(**payload)
        assert "Use DELETE para cancelar" in str(exc_info.value)

    def test_patch_status_confirmado_ok(self):
        payload = {"status": "confirmado"}
        obj = AgendamentoPatch(**payload)
        assert obj.status.value == "confirmado"
