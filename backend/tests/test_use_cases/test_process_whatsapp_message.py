"""
Tests — Use Case: process_whatsapp_message
==========================================
Tests the full orchestration defined in spec §9.1.
All external dependencies (DB, AI, FCM, WhatsApp) are mocked.

Coverage targets:
  - Text message: AI reply generated, interaction saved, send_message called, result persisted
  - Media message: fallback reply used, send_message called, result persisted
  - Empty payload (no message extracted): early return, no DB writes
  - Send failure: status_envio = 'failed', worker does not raise
  - Memory preload: conversation history hydrated before AI reply
  - Curation offer: triggered when lead freshly qualified (≥60%) without appointment
"""
import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.application.use_cases import process_whatsapp_message
from app.domain.entities.enums import LeadStatus, TipoMensagem
from app.services.whatsapp_service import SendResult


# ── Helpers ──────────────────────────────────────────────────────────────────

def _text_payload(phone: str = "5584999990001", text: str = "Quero ir a Paris") -> dict:
    return {
        "entry": [
            {
                "changes": [
                    {
                        "value": {
                            "messages": [
                                {
                                    "from": phone,
                                    "id": "wamid.test",
                                    "type": "text",
                                    "text": {"body": text},
                                }
                            ],
                            "contacts": [{"profile": {"name": "Maria"}}],
                        }
                    }
                ]
            }
        ]
    }


def _image_payload(phone: str = "5584999990001") -> dict:
    return {
        "entry": [
            {
                "changes": [
                    {
                        "value": {
                            "messages": [
                                {
                                    "from": phone,
                                    "id": "wamid.img",
                                    "type": "image",
                                    "image": {"id": "img001"},
                                }
                            ],
                            "contacts": [],
                        }
                    }
                ]
            }
        ]
    }


def _fake_lead(phone: str = "5584999990001"):
    lead = MagicMock()
    lead.id = uuid.uuid4()
    lead.telefone = phone
    lead.status = LeadStatus.novo
    lead.briefing = MagicMock(completude_pct=30)
    return lead


def _fake_interacao():
    interacao = MagicMock()
    interacao.id = uuid.uuid4()
    interacao.enviado_em = None
    interacao.status_envio = None
    interacao.erro_envio = None
    return interacao


# ── Tests ─────────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_text_message_full_flow():
    """Text message: AI reply, interaction saved, send called, result persisted."""
    db = AsyncMock()
    lead = _fake_lead()
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=120)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message.fcm_service"),
    ):
        mock_ls.get_or_create_by_phone = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.update_briefing_from_extraction = AsyncMock(
            return_value=MagicMock(completude_pct=30, destino=None)
        )
        mock_ls.save_interacao = AsyncMock(return_value=interacao)
        mock_ls.update_interacao_send_result = AsyncMock()
        mock_ls.get_recent_interacoes = AsyncMock(return_value=[])

        mock_ai.process_message = AsyncMock(return_value="Olá! Conte mais sobre sua viagem.")
        mock_ai.extract_briefing = AsyncMock(return_value=MagicMock())

        mock_ws.extract_message_from_payload = process_whatsapp_message.whatsapp_service.__class__  # use real
        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": "Quero ir a Paris",
            "type": "text",
            "name": "Maria",
            "message_id": "wamid.test",
        })
        mock_ws.send_message = AsyncMock(return_value=send_result)

        await process_whatsapp_message.execute(_text_payload(), db)

    mock_ls.save_interacao.assert_awaited_once()
    mock_ws.send_message.assert_awaited_once_with("5584999990001", "Olá! Conte mais sobre sua viagem.")
    mock_ls.update_interacao_send_result.assert_awaited_once_with(db, interacao, send_result)


@pytest.mark.asyncio
async def test_media_message_uses_fallback_and_persists_result():
    """Media message: fallback reply sent, result persisted."""
    db = AsyncMock()
    lead = _fake_lead()
    lead.status = LeadStatus.em_atendimento
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.media", retries_used=0, latency_ms=80)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service"),
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message.fcm_service"),
    ):
        mock_ls.get_or_create_by_phone = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.save_interacao = AsyncMock(return_value=interacao)
        mock_ls.update_interacao_send_result = AsyncMock()
        mock_ls.get_recent_interacoes = AsyncMock(return_value=[])

        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": None,
            "type": "image",
            "name": None,
            "message_id": "wamid.img",
        })
        mock_ws.send_message = AsyncMock(return_value=send_result)

        await process_whatsapp_message.execute(_image_payload(), db)

    sent_text = mock_ws.send_message.call_args[0][1]
    assert "consultor" in sent_text.lower() or "texto" in sent_text.lower()
    mock_ls.update_interacao_send_result.assert_awaited_once_with(db, interacao, send_result)


@pytest.mark.asyncio
async def test_empty_payload_early_return():
    """No message extracted — no DB writes, no WhatsApp calls."""
    db = AsyncMock()

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
    ):
        mock_ws.extract_message_from_payload = MagicMock(return_value=None)

        await process_whatsapp_message.execute({}, db)

    mock_ls.get_or_create_by_phone.assert_not_called()
    mock_ws.send_message.assert_not_called()


@pytest.mark.asyncio
async def test_send_failure_persisted_without_raising():
    """send_message fails — worker must NOT raise; failure persisted in DB."""
    db = AsyncMock()
    lead = _fake_lead()
    lead.status = LeadStatus.em_atendimento
    interacao = _fake_interacao()
    send_result = SendResult(
        success=False,
        error="HTTP 500: Internal Server Error",
        retries_used=3,
        latency_ms=3100,
    )

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message.fcm_service"),
    ):
        mock_ls.get_or_create_by_phone = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.update_briefing_from_extraction = AsyncMock(
            return_value=MagicMock(completude_pct=20, destino=None)
        )
        mock_ls.save_interacao = AsyncMock(return_value=interacao)
        mock_ls.update_interacao_send_result = AsyncMock()
        mock_ls.get_recent_interacoes = AsyncMock(return_value=[])

        mock_ai.process_message = AsyncMock(return_value="Resposta da IA")
        mock_ai.extract_briefing = AsyncMock(return_value=MagicMock())

        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": "Quero viajar",
            "type": "text",
            "name": "Carlos",
            "message_id": "wamid.x",
        })
        mock_ws.send_message = AsyncMock(return_value=send_result)

        # Must not raise
        await process_whatsapp_message.execute(_text_payload(), db)

    mock_ls.update_interacao_send_result.assert_awaited_once_with(db, interacao, send_result)
    call_args = mock_ls.update_interacao_send_result.call_args[0]
    persisted_result: SendResult = call_args[2]
    assert persisted_result.success is False
    assert persisted_result.error is not None


@pytest.mark.asyncio
async def test_lead_qualified_receives_curadoria_offer():
    """Lead freshly qualified (≥60%) without appointment receives curation offer."""
    db = AsyncMock()
    lead = _fake_lead()
    lead.status = LeadStatus.em_atendimento
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=120)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message.fcm_service"),
        patch("app.application.use_cases.process_whatsapp_message.curadoria_service") as mock_cs,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_qualified_notification", new=AsyncMock()),
    ):
        mock_ls.get_or_create_by_phone = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.get_recent_interacoes = AsyncMock(return_value=[])

        # Simulate qualification happening during briefing update
        briefing_mock = MagicMock(completude_pct=70, destino="Paris")

        async def _qualify_lead(db, lead, extracted):
            lead.status = LeadStatus.qualificado
            return briefing_mock

        mock_ls.update_briefing_from_extraction = _qualify_lead
        mock_ls.save_interacao = AsyncMock(return_value=interacao)
        mock_ls.update_interacao_send_result = AsyncMock()

        mock_ai.process_message = AsyncMock(return_value="Resposta normal da IA")
        mock_ai.extract_briefing = AsyncMock(return_value=MagicMock())

        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": "Quero ir a Paris com minha família em julho",
            "type": "text",
            "name": "Maria",
            "message_id": "wamid.test",
        })
        mock_ws.send_message = AsyncMock(return_value=send_result)

        # Curadoria mocks
        mock_cs.deve_oferecer_curadoria = MagicMock(return_value=True)
        mock_cs.lead_tem_agendamento_ativo = AsyncMock(return_value=False)
        mock_cs.get_proximos_slots_disponiveis = AsyncMock(return_value=[
            {"data": __import__("datetime").date(2026, 5, 5), "hora": "10:00"},
            {"data": __import__("datetime").date(2026, 5, 6), "hora": "14:00"},
        ])
        mock_cs.gerar_mensagem_oferta_curadoria = MagicMock(
            return_value="Mensagem de oferta de curadoria!"
        )

        await process_whatsapp_message.execute(_text_payload(), db)

    # The reply sent should be the curation offer, not the normal AI response
    mock_ws.send_message.assert_awaited_once_with("5584999990001", "Mensagem de oferta de curadoria!")
    mock_cs.deve_oferecer_curadoria.assert_called_once_with(
        LeadStatus.em_atendimento, LeadStatus.qualificado, 70
    )


@pytest.mark.asyncio
async def test_lead_already_scheduled_no_curadoria_offer():
    """Lead freshly qualified but already has appointment — no repeated offer."""
    db = AsyncMock()
    lead = _fake_lead()
    lead.status = LeadStatus.em_atendimento
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=120)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message.fcm_service"),
        patch("app.application.use_cases.process_whatsapp_message.curadoria_service") as mock_cs,
    ):
        mock_ls.get_or_create_by_phone = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.update_briefing_from_extraction = AsyncMock(
            return_value=MagicMock(completude_pct=75, destino="Paris")
        )
        mock_ls.save_interacao = AsyncMock(return_value=interacao)
        mock_ls.update_interacao_send_result = AsyncMock()
        mock_ls.get_recent_interacoes = AsyncMock(return_value=[])

        mock_ai.process_message = AsyncMock(return_value="Resposta normal da IA")
        mock_ai.extract_briefing = AsyncMock(return_value=MagicMock())

        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": "Quero ir a Paris",
            "type": "text",
            "name": "Maria",
            "message_id": "wamid.test",
        })
        mock_ws.send_message = AsyncMock(return_value=send_result)

        mock_cs.deve_oferecer_curadoria = MagicMock(return_value=True)
        mock_cs.lead_tem_agendamento_ativo = AsyncMock(return_value=True)

        await process_whatsapp_message.execute(_text_payload(), db)

    # Normal AI reply should be sent, not curation offer
    mock_ws.send_message.assert_awaited_once_with("5584999990001", "Resposta normal da IA")
    mock_cs.gerar_mensagem_oferta_curadoria.assert_not_called()


@pytest.mark.asyncio
async def test_lead_below_60_no_curadoria_offer():
    """Lead not yet qualified (<60%) — no curation offer."""
    db = AsyncMock()
    lead = _fake_lead()
    lead.status = LeadStatus.em_atendimento
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=120)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message.fcm_service"),
        patch("app.application.use_cases.process_whatsapp_message.curadoria_service") as mock_cs,
    ):
        mock_ls.get_or_create_by_phone = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.update_briefing_from_extraction = AsyncMock(
            return_value=MagicMock(completude_pct=40, destino=None)
        )
        mock_ls.save_interacao = AsyncMock(return_value=interacao)
        mock_ls.update_interacao_send_result = AsyncMock()
        mock_ls.get_recent_interacoes = AsyncMock(return_value=[])

        mock_ai.process_message = AsyncMock(return_value="Resposta normal da IA")
        mock_ai.extract_briefing = AsyncMock(return_value=MagicMock())

        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": "Oi",
            "type": "text",
            "name": "Maria",
            "message_id": "wamid.test",
        })
        mock_ws.send_message = AsyncMock(return_value=send_result)

        mock_cs.deve_oferecer_curadoria = MagicMock(return_value=False)

        await process_whatsapp_message.execute(_text_payload(), db)

    mock_ws.send_message.assert_awaited_once_with("5584999990001", "Resposta normal da IA")
    mock_cs.lead_tem_agendamento_ativo.assert_not_called()


@pytest.mark.asyncio
async def test_memory_preloaded_from_db():
    """Conversation memory must be hydrated from persisted interactions before AI reply."""
    db = AsyncMock()
    lead = _fake_lead()
    lead.status = LeadStatus.em_atendimento
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=120)

    recent_interacoes = [
        {"mensagem_cliente": "Oi", "mensagem_ia": "Olá! Como posso ajudar?"},
        {"mensagem_cliente": "Quero ir a Paris", "mensagem_ia": "Que destino incrível!"},
    ]

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message.fcm_service"),
    ):
        mock_ls.get_or_create_by_phone = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.get_recent_interacoes = AsyncMock(return_value=recent_interacoes)
        mock_ls.save_interacao = AsyncMock(return_value=interacao)
        mock_ls.update_interacao_send_result = AsyncMock()

        mock_ai.process_message = AsyncMock(return_value="Resposta com contexto")
        mock_ai.extract_briefing = AsyncMock(return_value=MagicMock())
        mock_ai.preload_memory_from_db = MagicMock()

        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": "Quero ir a Paris",
            "type": "text",
            "name": "Maria",
            "message_id": "wamid.test",
        })
        mock_ws.send_message = AsyncMock(return_value=send_result)

        await process_whatsapp_message.execute(_text_payload(), db)

    mock_ls.get_recent_interacoes.assert_awaited_once_with(db, lead.id, limit=20)
    mock_ai.preload_memory_from_db.assert_called_once_with("5584999990001", recent_interacoes)
    mock_ai.process_message.assert_awaited_once()
