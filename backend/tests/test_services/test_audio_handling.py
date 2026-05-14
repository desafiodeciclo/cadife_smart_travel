"""
Tests — Audio Message Handling
================================
Validates the full audio flow end-to-end (use-case layer):
  - Audio payload triggers download_media call
  - AUDIO_FALLBACK_REPLY ("Áudio não suportado nestes momentos...") is sent
  - Download failure is handled gracefully (reply still sent)
  - Non-audio media still uses the generic MEDIA_FALLBACK_REPLY
  - Text messages are unaffected by audio-handling changes

Also validates download_media() in whatsapp_service:
  - Success: two-step fetch → bytes returned
  - Step-1 HTTP error → None returned (no raise)
  - Step-2 HTTP error → None returned (no raise)
  - Network error → None returned (no raise)
"""
import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import httpx
import pytest

from app.application.use_cases import process_whatsapp_message
from app.application.use_cases.process_whatsapp_message import (
    AUDIO_FALLBACK_REPLY,
    MEDIA_FALLBACK_REPLY,
)
from app.domain.entities.enums import LeadStatus
from app.services.whatsapp_service import SendResult, download_media


# ── Payload builders ──────────────────────────────────────────────────────────


def _audio_payload(
    phone: str = "5584999990001",
    media_id: str = "audio_media_id_001",
) -> dict:
    return {
        "entry": [
            {
                "changes": [
                    {
                        "value": {
                            "messages": [
                                {
                                    "from": phone,
                                    "id": "wamid.audio001",
                                    "type": "audio",
                                    "audio": {"id": media_id, "mime_type": "audio/ogg"},
                                }
                            ],
                            "contacts": [{"profile": {"name": "Carlos"}}],
                        }
                    }
                ]
            }
        ]
    }


def _text_payload(phone: str = "5584999990001", text: str = "Quero viajar") -> dict:
    return {
        "entry": [
            {
                "changes": [
                    {
                        "value": {
                            "messages": [
                                {
                                    "from": phone,
                                    "id": "wamid.text001",
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
                                    "id": "wamid.img001",
                                    "type": "image",
                                    "image": {"id": "img_001", "mime_type": "image/jpeg"},
                                }
                            ],
                            "contacts": [],
                        }
                    }
                ]
            }
        ]
    }


# ── Shared mock helpers ───────────────────────────────────────────────────────


def _fake_lead(phone: str = "5584999990001", status: LeadStatus = LeadStatus.em_atendimento):
    lead = MagicMock()
    lead.id = uuid.uuid4()
    lead.telefone = phone
    lead.status = status
    lead.nome = "Carlos"
    lead.briefing = MagicMock(completude_pct=30)
    return lead


def _fake_interacao():
    interacao = MagicMock()
    interacao.id = uuid.uuid4()
    interacao.enviado_em = None
    interacao.status_envio = None
    interacao.erro_envio = None
    return interacao


# ── Use-case: audio triggers transcription attempt and specific reply ─────────


def _fake_memory() -> MagicMock:
    m = MagicMock()
    m._summary = ""
    m.load_memory_variables.return_value = {"chat_history": []}
    m.has_pending_summary.return_value = False
    m.compress_pending = AsyncMock()
    return m


def _common_ls_setup(mock_ls, lead, interacao):
    mock_ls.upsert_lead_with_resilience = AsyncMock(return_value=lead)
    mock_ls.update_lead_status = AsyncMock(return_value=lead)
    mock_ls.get_recent_interacoes = AsyncMock(return_value=[])
    mock_ls.save_interacao = AsyncMock(return_value=interacao)
    mock_ls.update_interacao_send_result = AsyncMock()


def _common_ai_setup(mock_ai):
    mock_ai.preload_memory_from_db = AsyncMock()
    mock_ai.get_memory.return_value = _fake_memory()
    mock_ai.get_llm = MagicMock()


@pytest.mark.asyncio
async def test_audio_message_calls_route_media_message():
    """Audio message: model_router.route_media_message is called with correct args."""
    db = AsyncMock()
    lead = _fake_lead()
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=80)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message.model_router") as mock_mr,
        patch("app.infrastructure.persistence.repositories.briefing_repository.BriefingRepository") as mock_br,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_qualified_notification", new=AsyncMock()),
    ):
        mock_ws.mark_as_read = AsyncMock()
        mock_ws.send_message = AsyncMock(return_value=send_result)
        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": None,
            "type": "audio",
            "name": "Carlos",
            "message_id": "wamid.audio001",
            "media_id": "audio_media_id_001",
        })

        _common_ls_setup(mock_ls, lead, interacao)
        _common_ai_setup(mock_ai)
        mock_br.return_value.get_by_lead = AsyncMock(return_value=None)
        mock_br.return_value.get_by_lead_id = AsyncMock(return_value=None)

        mock_mr.route_media_message = AsyncMock(return_value=None)  # no transcription

        await process_whatsapp_message.execute(_audio_payload(), db)

    mock_mr.route_media_message.assert_awaited_once_with("audio", "audio_media_id_001", "audio/ogg")


@pytest.mark.asyncio
async def test_audio_message_sends_audio_fallback_reply():
    """Audio without transcription → AUDIO_FALLBACK_REPLY sent, NOT generic media fallback."""
    db = AsyncMock()
    lead = _fake_lead()
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=80)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message.model_router") as mock_mr,
        patch("app.infrastructure.persistence.repositories.briefing_repository.BriefingRepository") as mock_br,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_qualified_notification", new=AsyncMock()),
    ):
        mock_ws.mark_as_read = AsyncMock()
        mock_ws.send_message = AsyncMock(return_value=send_result)
        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": None,
            "type": "audio",
            "name": "Carlos",
            "message_id": "wamid.audio001",
            "media_id": "audio_media_id_001",
        })

        _common_ls_setup(mock_ls, lead, interacao)
        _common_ai_setup(mock_ai)
        mock_br.return_value.get_by_lead = AsyncMock(return_value=None)
        mock_br.return_value.get_by_lead_id = AsyncMock(return_value=None)
        mock_mr.route_media_message = AsyncMock(return_value=None)  # transcription failed

        await process_whatsapp_message.execute(_audio_payload(), db)

    sent_text: str = mock_ws.send_message.call_args[0][1]
    assert sent_text == AUDIO_FALLBACK_REPLY
    assert sent_text != MEDIA_FALLBACK_REPLY


@pytest.mark.asyncio
async def test_audio_message_no_media_id_skips_transcription():
    """Audio message without media_id: transcription skipped, fallback reply still sent."""
    db = AsyncMock()
    lead = _fake_lead()
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=80)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message.model_router") as mock_mr,
        patch("app.infrastructure.persistence.repositories.briefing_repository.BriefingRepository") as mock_br,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_qualified_notification", new=AsyncMock()),
    ):
        mock_ws.mark_as_read = AsyncMock()
        mock_ws.send_message = AsyncMock(return_value=send_result)
        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": None,
            "type": "audio",
            "name": "Carlos",
            "message_id": "wamid.audio001",
            "media_id": None,
        })

        _common_ls_setup(mock_ls, lead, interacao)
        _common_ai_setup(mock_ai)
        mock_br.return_value.get_by_lead = AsyncMock(return_value=None)
        mock_br.return_value.get_by_lead_id = AsyncMock(return_value=None)

        await process_whatsapp_message.execute(_audio_payload(), db)

    mock_mr.route_media_message.assert_not_called()
    mock_ws.send_message.assert_awaited_once()
    assert mock_ws.send_message.call_args[0][1] == AUDIO_FALLBACK_REPLY


@pytest.mark.asyncio
async def test_audio_transcription_failure_reply_still_sent():
    """route_media_message returns None: reply must still be sent (best-effort)."""
    db = AsyncMock()
    lead = _fake_lead()
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=80)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message.model_router") as mock_mr,
        patch("app.infrastructure.persistence.repositories.briefing_repository.BriefingRepository") as mock_br,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_qualified_notification", new=AsyncMock()),
    ):
        mock_ws.mark_as_read = AsyncMock()
        mock_ws.send_message = AsyncMock(return_value=send_result)
        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": None,
            "type": "audio",
            "name": "Carlos",
            "message_id": "wamid.audio001",
            "media_id": "audio_fail_id",
        })

        _common_ls_setup(mock_ls, lead, interacao)
        _common_ai_setup(mock_ai)
        mock_br.return_value.get_by_lead = AsyncMock(return_value=None)
        mock_br.return_value.get_by_lead_id = AsyncMock(return_value=None)
        mock_mr.route_media_message = AsyncMock(return_value=None)

        await process_whatsapp_message.execute(_audio_payload(), db)

    mock_ws.send_message.assert_awaited_once_with("5584999990001", AUDIO_FALLBACK_REPLY)


@pytest.mark.asyncio
async def test_image_message_uses_generic_fallback_not_audio_reply():
    """Image messages use MEDIA_FALLBACK_REPLY, not AUDIO_FALLBACK_REPLY."""
    db = AsyncMock()
    lead = _fake_lead()
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=80)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.infrastructure.persistence.repositories.briefing_repository.BriefingRepository") as mock_br,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_qualified_notification", new=AsyncMock()),
    ):
        mock_ws.mark_as_read = AsyncMock()
        mock_ws.send_message = AsyncMock(return_value=send_result)
        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": None,
            "type": "image",
            "name": None,
            "message_id": "wamid.img001",
            "media_id": "img_001",
        })

        _common_ls_setup(mock_ls, lead, interacao)
        _common_ai_setup(mock_ai)
        mock_br.return_value.get_by_lead = AsyncMock(return_value=None)
        mock_br.return_value.get_by_lead_id = AsyncMock(return_value=None)

        await process_whatsapp_message.execute(_image_payload(), db)

    sent_text: str = mock_ws.send_message.call_args[0][1]
    assert sent_text == MEDIA_FALLBACK_REPLY
    assert sent_text != AUDIO_FALLBACK_REPLY


@pytest.mark.asyncio
async def test_text_message_unaffected_by_audio_changes():
    """Text messages go through orchestrator; audio handling code is not triggered."""
    db = AsyncMock()
    lead = _fake_lead()
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=80)
    ai_reply = "Olá! Conte mais sobre sua viagem."

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message.multi_agent_orchestrator") as mock_orc,
        patch("app.application.use_cases.process_whatsapp_message.model_router") as mock_mr,
        patch("app.infrastructure.persistence.repositories.briefing_repository.BriefingRepository") as mock_br,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_qualified_notification", new=AsyncMock()),
    ):
        mock_ws.mark_as_read = AsyncMock()
        mock_ws.send_message = AsyncMock(return_value=send_result)
        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": "Quero viajar",
            "type": "text",
            "name": "Maria",
            "message_id": "wamid.text001",
            "media_id": None,
        })

        _common_ls_setup(mock_ls, lead, interacao)
        _common_ai_setup(mock_ai)
        mock_br.return_value.get_by_lead = AsyncMock(return_value=None)
        mock_br.return_value.get_by_lead_id = AsyncMock(return_value=None)
        mock_orc.orchestrate = AsyncMock(return_value=ai_reply)

        await process_whatsapp_message.execute(_text_payload(), db)

    mock_ws.send_message.assert_awaited_once_with("5584999990001", ai_reply)
    mock_mr.route_media_message.assert_not_called()


# ── download_media unit tests ─────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_download_media_success(monkeypatch):
    """Two-step fetch succeeds → bytes returned."""
    mock_settings = MagicMock()
    mock_settings.WHATSAPP_TOKEN = "tok"
    monkeypatch.setattr("app.services.whatsapp_service.get_settings", lambda: mock_settings)

    audio_bytes = b"FAKE_AUDIO_DATA"

    async def mock_get(self, url, **kwargs):
        resp = MagicMock()
        if "graph.facebook" in url:
            resp.status_code = 200
            resp.json.return_value = {"url": "https://cdn.meta.example/audio.ogg"}
        else:
            resp.status_code = 200
            resp.content = audio_bytes
        return resp

    with patch("httpx.AsyncClient.get", new=mock_get):
        result = await download_media("media_001")

    assert result == audio_bytes


@pytest.mark.asyncio
async def test_download_media_step1_http_error_returns_none(monkeypatch):
    """Step-1 (URL resolution) HTTP error → returns None without raising."""
    mock_settings = MagicMock()
    mock_settings.WHATSAPP_TOKEN = "tok"
    monkeypatch.setattr("app.services.whatsapp_service.get_settings", lambda: mock_settings)

    async def mock_get(self, url, **kwargs):
        resp = MagicMock()
        resp.status_code = 404
        resp.json.return_value = {}
        return resp

    with patch("httpx.AsyncClient.get", new=mock_get):
        result = await download_media("media_404")

    assert result is None


@pytest.mark.asyncio
async def test_download_media_step2_http_error_returns_none(monkeypatch):
    """Step-2 (actual download) HTTP error → returns None without raising."""
    mock_settings = MagicMock()
    mock_settings.WHATSAPP_TOKEN = "tok"
    monkeypatch.setattr("app.services.whatsapp_service.get_settings", lambda: mock_settings)

    call_count = 0

    async def mock_get(self, url, **kwargs):
        nonlocal call_count
        call_count += 1
        resp = MagicMock()
        if call_count == 1:
            resp.status_code = 200
            resp.json.return_value = {"url": "https://cdn.meta.example/audio.ogg"}
        else:
            resp.status_code = 500
            resp.content = b""
        return resp

    with patch("httpx.AsyncClient.get", new=mock_get):
        result = await download_media("media_cdn_fail")

    assert result is None


@pytest.mark.asyncio
async def test_download_media_network_error_returns_none(monkeypatch):
    """Network/connection error during step-1 → returns None without raising."""
    mock_settings = MagicMock()
    mock_settings.WHATSAPP_TOKEN = "tok"
    monkeypatch.setattr("app.services.whatsapp_service.get_settings", lambda: mock_settings)

    async def mock_get(self, url, **kwargs):
        raise httpx.ConnectError("Connection refused")

    with patch("httpx.AsyncClient.get", new=mock_get):
        result = await download_media("media_offline")

    assert result is None


@pytest.mark.asyncio
async def test_download_media_missing_url_in_response_returns_none(monkeypatch):
    """Step-1 returns 200 but no `url` key → returns None."""
    mock_settings = MagicMock()
    mock_settings.WHATSAPP_TOKEN = "tok"
    monkeypatch.setattr("app.services.whatsapp_service.get_settings", lambda: mock_settings)

    async def mock_get(self, url, **kwargs):
        resp = MagicMock()
        resp.status_code = 200
        resp.json.return_value = {"id": "media_001"}  # missing "url"
        return resp

    with patch("httpx.AsyncClient.get", new=mock_get):
        result = await download_media("media_no_url")

    assert result is None
