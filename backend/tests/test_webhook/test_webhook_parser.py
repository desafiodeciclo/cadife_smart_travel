"""
Tests — WhatsApp Webhook Payload Parser (Pydantic Models)
==========================================================
Validates that WhatsAppWebhookPayload:
  - Parses text payloads correctly
  - Parses audio payloads and exposes media_id
  - Parses image payloads and exposes media_id
  - Never raises ValidationError on unknown/extra fields
  - Returns None from extract_message() on malformed/empty payloads
  - Exposes correct normalized dict from extract_message()
"""
import pytest
from pydantic import ValidationError

from app.presentation.schemas.webhook_schema import (
    WhatsAppWebhookPayload,
    WhatsAppMessage,
)


# ── Payload builders ──────────────────────────────────────────────────────────


def _text_payload(phone: str = "5584999990001", text: str = "Quero viajar") -> dict:
    return {
        "object": "whatsapp_business_account",
        "entry": [
            {
                "id": "123",
                "changes": [
                    {
                        "field": "messages",
                        "value": {
                            "messaging_product": "whatsapp",
                            "messages": [
                                {
                                    "from": phone,
                                    "id": "wamid.text001",
                                    "timestamp": "1700000000",
                                    "type": "text",
                                    "text": {"body": text},
                                }
                            ],
                            "contacts": [{"profile": {"name": "Maria"}, "wa_id": phone}],
                        },
                    }
                ],
            }
        ],
    }


def _audio_payload(
    phone: str = "5584999990001",
    media_id: str = "audio_media_id_001",
    mime_type: str = "audio/ogg; codecs=opus",
) -> dict:
    return {
        "object": "whatsapp_business_account",
        "entry": [
            {
                "id": "123",
                "changes": [
                    {
                        "field": "messages",
                        "value": {
                            "messaging_product": "whatsapp",
                            "messages": [
                                {
                                    "from": phone,
                                    "id": "wamid.audio001",
                                    "timestamp": "1700000001",
                                    "type": "audio",
                                    "audio": {"id": media_id, "mime_type": mime_type},
                                }
                            ],
                            "contacts": [{"profile": {"name": "João"}, "wa_id": phone}],
                        },
                    }
                ],
            }
        ],
    }


def _image_payload(
    phone: str = "5584999990001",
    media_id: str = "image_media_id_001",
) -> dict:
    return {
        "object": "whatsapp_business_account",
        "entry": [
            {
                "id": "123",
                "changes": [
                    {
                        "field": "messages",
                        "value": {
                            "messaging_product": "whatsapp",
                            "messages": [
                                {
                                    "from": phone,
                                    "id": "wamid.img001",
                                    "timestamp": "1700000002",
                                    "type": "image",
                                    "image": {
                                        "id": media_id,
                                        "mime_type": "image/jpeg",
                                        "caption": "olha essa foto",
                                    },
                                }
                            ],
                            "contacts": [{"profile": {"name": "Ana"}, "wa_id": phone}],
                        },
                    }
                ],
            }
        ],
    }


# ── Text message tests ────────────────────────────────────────────────────────


def test_text_payload_parsed_successfully():
    parsed = WhatsAppWebhookPayload.model_validate(_text_payload())
    assert parsed.object == "whatsapp_business_account"
    assert len(parsed.entry) == 1


def test_text_extract_message_returns_expected_dict():
    payload = WhatsAppWebhookPayload.model_validate(_text_payload())
    msg = payload.extract_message()

    assert msg is not None
    assert msg["phone"] == "5584999990001"
    assert msg["type"] == "text"
    assert msg["text"] == "Quero viajar"
    assert msg["name"] == "Maria"
    assert msg["media_id"] is None  # text messages have no media


def test_text_message_object_text_body():
    payload = WhatsAppWebhookPayload.model_validate(_text_payload(text="Olá AYA"))
    msg_obj = payload.entry[0].changes[0].value.messages[0]
    assert msg_obj.text_body == "Olá AYA"
    assert msg_obj.media_id is None


# ── Audio message tests ───────────────────────────────────────────────────────


def test_audio_payload_parsed_successfully():
    parsed = WhatsAppWebhookPayload.model_validate(_audio_payload())
    msg_obj = parsed.entry[0].changes[0].value.messages[0]
    assert msg_obj.type == "audio"
    assert msg_obj.audio is not None
    assert msg_obj.audio.id == "audio_media_id_001"


def test_audio_extract_message_returns_media_id():
    payload = WhatsAppWebhookPayload.model_validate(
        _audio_payload(media_id="audio_abc123")
    )
    msg = payload.extract_message()

    assert msg is not None
    assert msg["type"] == "audio"
    assert msg["media_id"] == "audio_abc123"
    assert msg["text"] is None


def test_audio_message_object_media_id_property():
    payload = WhatsAppWebhookPayload.model_validate(_audio_payload())
    msg_obj = payload.entry[0].changes[0].value.messages[0]
    assert msg_obj.media_id == "audio_media_id_001"
    assert msg_obj.text_body is None


# ── Image message tests ───────────────────────────────────────────────────────


def test_image_payload_parsed_successfully():
    parsed = WhatsAppWebhookPayload.model_validate(_image_payload())
    msg_obj = parsed.entry[0].changes[0].value.messages[0]
    assert msg_obj.type == "image"
    assert msg_obj.image is not None


def test_image_extract_message_returns_media_id():
    payload = WhatsAppWebhookPayload.model_validate(
        _image_payload(media_id="img_xyz789")
    )
    msg = payload.extract_message()

    assert msg is not None
    assert msg["type"] == "image"
    assert msg["media_id"] == "img_xyz789"


# ── Resilience against extra / unknown fields ─────────────────────────────────


def test_extra_fields_in_message_do_not_raise():
    """Meta can add new fields; Pydantic must not raise ValidationError."""
    raw = _text_payload()
    raw["entry"][0]["changes"][0]["value"]["messages"][0]["context"] = {
        "from": "5511999990002",
        "id": "wamid.quoted",
    }
    raw["entry"][0]["changes"][0]["value"]["messages"][0]["referral"] = {
        "source_url": "https://example.com",
        "source_type": "ad",
    }

    try:
        WhatsAppWebhookPayload.model_validate(raw)
    except ValidationError as exc:
        pytest.fail(f"ValidationError raised on extra fields: {exc}")


def test_extra_fields_in_root_payload_do_not_raise():
    raw = _audio_payload()
    raw["future_meta_field"] = {"version": "3.0", "experimental": True}

    try:
        WhatsAppWebhookPayload.model_validate(raw)
    except ValidationError as exc:
        pytest.fail(f"ValidationError raised on extra root fields: {exc}")


def test_unknown_message_type_does_not_raise():
    """An unknown type (e.g. 'reaction') should parse without error."""
    raw = _text_payload()
    raw["entry"][0]["changes"][0]["value"]["messages"][0]["type"] = "reaction"
    raw["entry"][0]["changes"][0]["value"]["messages"][0]["reaction"] = {
        "message_id": "wamid.ref",
        "emoji": "👍",
    }
    raw["entry"][0]["changes"][0]["value"]["messages"][0].pop("text", None)

    try:
        parsed = WhatsAppWebhookPayload.model_validate(raw)
        msg = parsed.extract_message()
        assert msg is not None
        assert msg["type"] == "reaction"
        assert msg["media_id"] is None  # no known media field
    except ValidationError as exc:
        pytest.fail(f"ValidationError raised on unknown message type: {exc}")


# ── Empty / malformed payload handling ───────────────────────────────────────


def test_empty_messages_list_returns_none():
    raw = _text_payload()
    raw["entry"][0]["changes"][0]["value"]["messages"] = []
    payload = WhatsAppWebhookPayload.model_validate(raw)
    assert payload.extract_message() is None


def test_no_contacts_field_returns_name_none():
    raw = _text_payload()
    raw["entry"][0]["changes"][0]["value"]["contacts"] = []
    payload = WhatsAppWebhookPayload.model_validate(raw)
    msg = payload.extract_message()
    assert msg is not None
    assert msg["name"] is None


def test_malformed_payload_missing_entry_raises_validation_error():
    with pytest.raises(ValidationError):
        WhatsAppWebhookPayload.model_validate({"object": "whatsapp_business_account"})


def test_whatsapp_message_requires_id_and_from():
    with pytest.raises(ValidationError):
        WhatsAppMessage.model_validate({"type": "text"})
