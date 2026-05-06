"""
Tests — Curadoria Service
==========================
Tests the curation trigger logic: slot discovery, active appointment check,
messaging, and qualification gate.
"""
from datetime import date, time
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.domain.entities.enums import LeadStatus
from app.services.curadoria_service import (
    deve_oferecer_curadoria,
    gerar_mensagem_oferta_curadoria,
    get_proximos_slots_disponiveis,
    lead_tem_agendamento_ativo,
)


# ── deve_oferecer_curadoria ──────────────────────────────────────────────────

@pytest.mark.parametrize(
    "status_antes,status_depois,completude,expected",
    [
        (LeadStatus.em_atendimento, LeadStatus.qualificado, 60, True),
        (LeadStatus.em_atendimento, LeadStatus.qualificado, 70, True),
        (LeadStatus.em_atendimento, LeadStatus.em_atendimento, 60, False),
        (LeadStatus.novo, LeadStatus.qualificado, 70, False),
        (LeadStatus.qualificado, LeadStatus.qualificado, 70, False),
        (LeadStatus.em_atendimento, LeadStatus.qualificado, 50, False),
    ],
)
def test_deve_oferecer_curadoria(status_antes, status_depois, completude, expected):
    assert deve_oferecer_curadoria(status_antes, status_depois, completude) is expected


# ── gerar_mensagem_oferta_curadoria ──────────────────────────────────────────

def test_gerar_mensagem_com_slots():
    slots = [
        {"data": date(2026, 5, 5), "hora": "10:00"},
        {"data": date(2026, 5, 6), "hora": "14:00"},
    ]
    msg = gerar_mensagem_oferta_curadoria(slots, nome_cliente="Maria")

    assert "Maria" in msg
    assert "curadoria" in msg.lower()
    assert "05/05 às 10:00" in msg
    assert "06/05 às 14:00" in msg
    assert "1." in msg and "2." in msg


def test_gerar_mensagem_sem_slots():
    msg = gerar_mensagem_oferta_curadoria([], nome_cliente="João")

    assert "agenda cheia" in msg.lower() or "consultores" in msg.lower()


def test_gerar_mensagem_sem_nome():
    slots = [{"data": date(2026, 5, 5), "hora": "09:00"}]
    msg = gerar_mensagem_oferta_curadoria(slots)

    assert "Oi!" in msg
    assert "09:00" in msg


# ── lead_tem_agendamento_ativo ───────────────────────────────────────────────

@pytest.mark.asyncio
async def test_lead_tem_agendamento_ativo_true():
    db = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = MagicMock()
    db.execute.return_value = mock_result

    result = await lead_tem_agendamento_ativo(db, "lead-uuid")
    assert result is True


@pytest.mark.asyncio
async def test_lead_tem_agendamento_ativo_false():
    db = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    db.execute.return_value = mock_result

    result = await lead_tem_agendamento_ativo(db, "lead-uuid")
    assert result is False


# ── get_proximos_slots_disponiveis ───────────────────────────────────────────

@pytest.mark.asyncio
async def test_get_proximos_slots_retorna_disponiveis():
    db = AsyncMock()
    # Simulate empty agenda — all slots free
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = []
    db.execute.return_value = mock_result

    slots = await get_proximos_slots_disponiveis(db, quantidade=3)

    assert len(slots) == 3
    assert all("data" in s and "hora" in s for s in slots)
    # Should be weekdays only
    assert all(s["data"].weekday() < 5 for s in slots)


@pytest.mark.asyncio
async def test_get_proximos_slots_respeita_max_por_dia():
    db = AsyncMock()
    from app.models.agendamento import Agendamento

    # Full day of bookings only for the first queried date
    agendamentos_full = [
        MagicMock(hora=time(9, 0)),
        MagicMock(hora=time(10, 0)),
        MagicMock(hora=time(11, 0)),
        MagicMock(hora=time(13, 0)),
        MagicMock(hora=time(14, 0)),
        MagicMock(hora=time(15, 0)),
    ]

    call_counter = {"count": 0}
    def _fake_execute(stmt):
        call_counter["count"] += 1
        mock_result = MagicMock()
        if call_counter["count"] == 1:
            mock_result.scalars.return_value.all.return_value = agendamentos_full
        else:
            mock_result.scalars.return_value.all.return_value = []
        return mock_result

    db.execute.side_effect = _fake_execute

    slots = await get_proximos_slots_disponiveis(db, quantidade=3)

    # Should skip the full day and return slots from subsequent days
    assert len(slots) == 3
    # All returned slots must be from days after the full one (today)
    from datetime import date
    assert all(s["data"] > date.today() for s in slots)
