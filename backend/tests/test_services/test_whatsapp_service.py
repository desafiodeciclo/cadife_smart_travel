"""
Tests — WhatsApp Service Layer
==============================
Unit tests for whatsapp_service.py.
Uses httpx.MockTransport / pytest-httpx for outbound HTTP mocking.
No real Meta API calls — fully offline.

Coverage targets:
  - send_message: success (200), retry on transient (429/503), failure after exhaustion
  - extract_message_from_payload: text message, media message, empty/malformed payload
  - verify_signature: valid, invalid, missing prefix
"""
import hashlib
import hmac
from unittest.mock import AsyncMock, MagicMock, patch

import httpx
import pytest

from app.services.whatsapp_service import (
    extract_message_from_payload,
    send_message,
    verify_signature,
)


# ── Fixtures ─────────────────────────────────────────────────────────────────

PHONE = "5584999990001"
TEXT = "Olá AYA, quero viajar para Paris"


def _make_text_payload(phone: str = PHONE, text: str = TEXT) -> dict:
    return {
        "entry": [
            {
                "changes": [
                    {
                        "value": {
                            "messages": [
                                {
                                    "from": phone,
                                    "id": "wamid.test123",
                                    "type": "text",
                                    "text": {"body": text},
                                }
                            ],
                            "contacts": [{"profile": {"name": "João"}}],
                        }
                    }
                ]
            }
        ]
    }


def _make_media_payload(phone: str = PHONE, media_type: str = "image") -> dict:
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
                                    "type": media_type,
                                    media_type: {"id": "img_id_123"},
                                }
                            ],
                            "contacts": [{}],  # empty contact is valid; contacts:[] raises IndexError
                        }
                    }
                ]
            }
        ]
    }


# ── extract_message_from_payload ─────────────────────────────────────────────

def test_extract_text_message():
    result = extract_message_from_payload(_make_text_payload())
    assert result is not None
    assert result["phone"] == PHONE
    assert result["text"] == TEXT
    assert result["type"] == "text"
    assert result["name"] == "João"


def test_extract_media_message():
    result = extract_message_from_payload(_make_media_payload(media_type="image"))
    assert result is not None
    assert result["phone"] == PHONE
    assert result["type"] == "image"
    assert result["text"] is None


def test_extract_empty_messages_returns_none():
    payload = {"entry": [{"changes": [{"value": {"messages": []}}]}]}
    assert extract_message_from_payload(payload) is None


def test_extract_malformed_payload_returns_none():
    assert extract_message_from_payload({}) is None
    assert extract_message_from_payload({"entry": []}) is None


# ── verify_signature ─────────────────────────────────────────────────────────

def test_verify_signature_valid(monkeypatch):
    secret = "test_token"
    monkeypatch.setattr("app.services.whatsapp_service.settings.META_APP_SECRET", secret)
    body = b'{"test": "payload"}'
    sig = "sha256=" + hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    assert verify_signature(body, sig) is True


def test_verify_signature_invalid(monkeypatch):
    monkeypatch.setattr("app.services.whatsapp_service.settings.META_APP_SECRET", "test_token")
    body = b'{"test": "payload"}'
    assert verify_signature(body, "sha256=badhash") is False


def test_verify_signature_missing_prefix(monkeypatch):
    monkeypatch.setattr("app.services.whatsapp_service.settings.META_APP_SECRET", "test_token")
    assert verify_signature(b"body", "noprefixhash") is False


# ── send_message ─────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_send_message_success(monkeypatch):
    monkeypatch.setattr("app.services.whatsapp_service.settings.WHATSAPP_TOKEN", "tok")
    monkeypatch.setattr("app.services.whatsapp_service.settings.PHONE_NUMBER_ID", "pid")

    response_body = {"messages": [{"id": "wamid.ok123"}]}

    async def mock_post(*args, **kwargs):
        resp = MagicMock()
        resp.status_code = 200
        resp.json.return_value = response_body
        return resp

    with patch("httpx.AsyncClient.post", new=mock_post):
        result = await send_message(PHONE, TEXT)

    assert result.success is True
    assert result.wamid == "wamid.ok123"
    assert result.retries_used == 0
    assert result.error is None


@pytest.mark.asyncio
async def test_send_message_retries_on_transient_then_succeeds(monkeypatch):
    monkeypatch.setattr("app.services.whatsapp_service.settings.WHATSAPP_TOKEN", "tok")
    monkeypatch.setattr("app.services.whatsapp_service.settings.PHONE_NUMBER_ID", "pid")
    monkeypatch.setattr("asyncio.sleep", AsyncMock())

    call_count = 0

    async def mock_post(*args, **kwargs):
        nonlocal call_count
        call_count += 1
        resp = MagicMock()
        if call_count < 2:
            resp.status_code = 503
            resp.text = "Service Unavailable"
            resp.json.return_value = {}
        else:
            resp.status_code = 200
            resp.json.return_value = {"messages": [{"id": "wamid.retry"}]}
        return resp

    with patch("httpx.AsyncClient.post", new=mock_post):
        result = await send_message(PHONE, TEXT)

    assert result.success is True
    assert result.wamid == "wamid.retry"
    assert result.retries_used == 1


@pytest.mark.asyncio
async def test_send_message_fails_after_exhausting_retries(monkeypatch):
    monkeypatch.setattr("app.services.whatsapp_service.settings.WHATSAPP_TOKEN", "tok")
    monkeypatch.setattr("app.services.whatsapp_service.settings.PHONE_NUMBER_ID", "pid")
    monkeypatch.setattr("asyncio.sleep", AsyncMock())

    async def mock_post(*args, **kwargs):
        resp = MagicMock()
        resp.status_code = 500
        resp.text = "Internal Server Error"
        resp.json.return_value = {}
        return resp

    with patch("httpx.AsyncClient.post", new=mock_post):
        result = await send_message(PHONE, TEXT)

    assert result.success is False
    assert result.error is not None
    assert "500" in result.error


@pytest.mark.asyncio
async def test_send_message_non_retryable_error(monkeypatch):
    monkeypatch.setattr("app.services.whatsapp_service.settings.WHATSAPP_TOKEN", "tok")
    monkeypatch.setattr("app.services.whatsapp_service.settings.PHONE_NUMBER_ID", "pid")

    async def mock_post(*args, **kwargs):
        resp = MagicMock()
        resp.status_code = 400
        resp.text = "Bad Request"
        resp.json.return_value = {}
        return resp

    with patch("httpx.AsyncClient.post", new=mock_post):
        result = await send_message(PHONE, TEXT)

    assert result.success is False
    assert result.retries_used == 0


@pytest.mark.asyncio
async def test_send_message_timeout_then_success(monkeypatch):
    monkeypatch.setattr("app.services.whatsapp_service.settings.WHATSAPP_TOKEN", "tok")
    monkeypatch.setattr("app.services.whatsapp_service.settings.PHONE_NUMBER_ID", "pid")
    monkeypatch.setattr("asyncio.sleep", AsyncMock())

    call_count = 0

    async def mock_post(*args, **kwargs):
        nonlocal call_count
        call_count += 1
        if call_count == 1:
            raise httpx.TimeoutException("timed out")
        resp = MagicMock()
        resp.status_code = 200
        resp.json.return_value = {"messages": [{"id": "wamid.aftertimeout"}]}
        return resp

    with patch("httpx.AsyncClient.post", new=mock_post):
        result = await send_message(PHONE, TEXT)

    assert result.success is True
    assert result.retries_used == 1
