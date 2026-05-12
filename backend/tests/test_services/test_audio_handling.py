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


# ── Use-case: audio triggers download and specific reply ──────────────────────


@pytest.mark.asyncio
async def test_audio_message_calls_download_media():
    """Audio message: download_media is called with the correct media_id."""
    db = AsyncMock()
    lead = _fake_lead()
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=80)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service"),
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_message_received_notification"),
    ):
        mock_ls.upsert_lead_with_resilience = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.get_recent_interacoes = AsyncMock(return_value=[])
        mock_ls.save_interacao = AsyncMock(return_value=interacao)
        mock_ls.update_interacao_send_result = AsyncMock()

        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": None,
            "type": "audio",
            "name": "Carlos",
            "message_id": "wamid.audio001",
            "media_id": "audio_media_id_001",
        })
        mock_ws.download_media = AsyncMock(return_value=b"fake_audio_bytes")
        mock_ws.send_message = AsyncMock(return_value=send_result)

        await process_whatsapp_message.execute(_audio_payload(), db)

    mock_ws.download_media.assert_awaited_once_with("audio_media_id_001")


@pytest.mark.asyncio
async def test_audio_message_sends_audio_fallback_reply():
    """Audio message: AUDIO_FALLBACK_REPLY is sent, NOT the generic media fallback."""
    db = AsyncMock()
    lead = _fake_lead()
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=80)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service"),
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_message_received_notification"),
    ):
        mock_ls.upsert_lead_with_resilience = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.get_recent_interacoes = AsyncMock(return_value=[])
        mock_ls.save_interacao = AsyncMock(return_value=interacao)
        mock_ls.update_interacao_send_result = AsyncMock()

        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": None,
            "type": "audio",
            "name": "Carlos",
            "message_id": "wamid.audio001",
            "media_id": "audio_media_id_001",
        })
        mock_ws.download_media = AsyncMock(return_value=b"bytes")
        mock_ws.send_message = AsyncMock(return_value=send_result)

        await process_whatsapp_message.execute(_audio_payload(), db)

    sent_text: str = mock_ws.send_message.call_args[0][1]
    assert sent_text == AUDIO_FALLBACK_REPLY
    assert "Áudio não suportado" in sent_text
    assert sent_text != MEDIA_FALLBACK_REPLY


@pytest.mark.asyncio
async def test_audio_message_no_media_id_skips_download():
    """Audio message without media_id: download is skipped, reply still sent."""
    db = AsyncMock()
    lead = _fake_lead()
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=80)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service"),
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_message_received_notification"),
    ):
        mock_ls.upsert_lead_with_resilience = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.get_recent_interacoes = AsyncMock(return_value=[])
        mock_ls.save_interacao = AsyncMock(return_value=interacao)
        mock_ls.update_interacao_send_result = AsyncMock()

        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": None,
            "type": "audio",
            "name": "Carlos",
            "message_id": "wamid.audio001",
            "media_id": None,  # missing media_id
        })
        mock_ws.download_media = AsyncMock(return_value=None)
        mock_ws.send_message = AsyncMock(return_value=send_result)

        await process_whatsapp_message.execute(_audio_payload(), db)

    mock_ws.download_media.assert_not_awaited()
    mock_ws.send_message.assert_awaited_once()
    assert mock_ws.send_message.call_args[0][1] == AUDIO_FALLBACK_REPLY


@pytest.mark.asyncio
async def test_audio_download_failure_reply_still_sent():
    """download_media returns None: reply must still be sent (best-effort download)."""
    db = AsyncMock()
    lead = _fake_lead()
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=80)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service"),
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_message_received_notification"),
    ):
        mock_ls.upsert_lead_with_resilience = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.get_recent_interacoes = AsyncMock(return_value=[])
        mock_ls.save_interacao = AsyncMock(return_value=interacao)
        mock_ls.update_interacao_send_result = AsyncMock()

        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": None,
            "type": "audio",
            "name": "Carlos",
            "message_id": "wamid.audio001",
            "media_id": "audio_fail_id",
        })
        mock_ws.download_media = AsyncMock(return_value=None)  # download failed
        mock_ws.send_message = AsyncMock(return_value=send_result)

        # Must not raise
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
        patch("app.application.use_cases.process_whatsapp_message.ai_service"),
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_message_received_notification"),
    ):
        mock_ls.upsert_lead_with_resilience = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.get_recent_interacoes = AsyncMock(return_value=[])
        mock_ls.save_interacao = AsyncMock(return_value=interacao)
        mock_ls.update_interacao_send_result = AsyncMock()

        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": None,
            "type": "image",
            "name": None,
            "message_id": "wamid.img001",
            "media_id": "img_001",
        })
        mock_ws.download_media = AsyncMock(return_value=None)
        mock_ws.send_message = AsyncMock(return_value=send_result)

        await process_whatsapp_message.execute(_image_payload(), db)

    sent_text: str = mock_ws.send_message.call_args[0][1]
    assert sent_text == MEDIA_FALLBACK_REPLY
    assert sent_text != AUDIO_FALLBACK_REPLY
    mock_ws.download_media.assert_not_awaited()


@pytest.mark.asyncio
async def test_text_message_unaffected_by_audio_changes():
    """Text messages still go through AI and are not affected by audio handling."""
    db = AsyncMock()
    lead = _fake_lead()
    interacao = _fake_interacao()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=80)
    ai_reply = "Olá! Conte mais sobre sua viagem."

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_message_received_notification"),
        patch("app.application.use_cases.process_whatsapp_message.curadoria_service") as mock_cs,
    ):
        mock_ls.upsert_lead_with_resilience = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.get_recent_interacoes = AsyncMock(return_value=[])
        mock_ls.update_briefing_from_extraction = AsyncMock(
            return_value=MagicMock(completude_pct=30, destino=None)
        )
        mock_ls.save_interacao = AsyncMock(return_value=interacao)
        mock_ls.update_interacao_send_result = AsyncMock()

        mock_ai.process_message = AsyncMock(return_value=ai_reply)
        mock_ai.extract_briefing = AsyncMock(return_value=MagicMock())
        mock_ai.preload_memory_from_db = MagicMock()

        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": "Quero viajar",
            "type": "text",
            "name": "Maria",
            "message_id": "wamid.text001",
            "media_id": None,
        })
        mock_ws.download_media = AsyncMock()
        mock_ws.send_message = AsyncMock(return_value=send_result)

        mock_cs.deve_oferecer_curadoria = MagicMock(return_value=False)

        await process_whatsapp_message.execute(_text_payload(), db)

    mock_ws.send_message.assert_awaited_once_with("5584999990001", ai_reply)
    mock_ws.download_media.assert_not_awaited()


# ── download_media unit tests ─────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_download_media_success(monkeypatch):
    """Two-step fetch succeeds → bytes returned."""
    monkeypatch.setattr("app.services.whatsapp_service.settings.WHATSAPP_TOKEN", "tok")

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
    monkeypatch.setattr("app.services.whatsapp_service.settings.WHATSAPP_TOKEN", "tok")

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
    monkeypatch.setattr("app.services.whatsapp_service.settings.WHATSAPP_TOKEN", "tok")

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
    monkeypatch.setattr("app.services.whatsapp_service.settings.WHATSAPP_TOKEN", "tok")

    async def mock_get(self, url, **kwargs):
        raise httpx.ConnectError("Connection refused")

    with patch("httpx.AsyncClient.get", new=mock_get):
        result = await download_media("media_offline")

    assert result is None


@pytest.mark.asyncio
async def test_download_media_missing_url_in_response_returns_none(monkeypatch):
    """Step-1 returns 200 but no `url` key → returns None."""
    monkeypatch.setattr("app.services.whatsapp_service.settings.WHATSAPP_TOKEN", "tok")

    async def mock_get(self, url, **kwargs):
        resp = MagicMock()
        resp.status_code = 200
        resp.json.return_value = {"id": "media_001"}  # missing "url"
        return resp

    with patch("httpx.AsyncClient.get", new=mock_get):
        result = await download_media("media_no_url")

    assert result is None
