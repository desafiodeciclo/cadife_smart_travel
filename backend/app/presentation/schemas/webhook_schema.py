"""
WhatsApp Webhook Payload Schemas — Presentation Layer
======================================================
Pydantic v2 models for parsing Meta WhatsApp Cloud API webhook payloads.

Uses `extra="allow"` on all models to stay resilient against new fields
introduced by Meta API updates — no ValidationError when Meta adds new keys.

Message content is typed per-media-type (TextContent, AudioContent, etc.)
so the use-case layer can access structured data without raw dict traversal.
"""
from __future__ import annotations

from typing import Any, Optional

from pydantic import BaseModel, Field


class _Resilient(BaseModel):
    """Base that silently ignores unknown fields (forward-compatible with Meta API changes)."""

    model_config = {"extra": "allow"}


# ── Per-type content models ───────────────────────────────────────────────────


class TextContent(_Resilient):
    body: str


class AudioContent(_Resilient):
    id: str
    mime_type: Optional[str] = None


class ImageContent(_Resilient):
    id: str
    mime_type: Optional[str] = None
    caption: Optional[str] = None


class DocumentContent(_Resilient):
    id: str
    mime_type: Optional[str] = None
    filename: Optional[str] = None
    caption: Optional[str] = None


class VideoContent(_Resilient):
    id: str
    mime_type: Optional[str] = None
    caption: Optional[str] = None


class StickerContent(_Resilient):
    id: str
    mime_type: Optional[str] = None


# ── Message ───────────────────────────────────────────────────────────────────


class WhatsAppMessage(_Resilient):
    """
    A single WhatsApp message extracted from the Meta webhook entry.

    All content fields are Optional; only the field matching `type` is
    populated by Meta. Unknown future types (reaction, location, etc.) are
    accepted without error thanks to `extra="allow"`.
    """

    model_config = {"extra": "allow", "populate_by_name": True}

    id: str
    from_: str = Field(alias="from")
    timestamp: Optional[str] = None
    type: str

    # ── Typed content (one will be set, rest None) ────────────────────────
    text: Optional[TextContent] = None
    audio: Optional[AudioContent] = None
    image: Optional[ImageContent] = None
    document: Optional[DocumentContent] = None
    video: Optional[VideoContent] = None
    sticker: Optional[StickerContent] = None

    @property
    def text_body(self) -> Optional[str]:
        return self.text.body if self.text else None

    @property
    def media_id(self) -> Optional[str]:
        """Returns the media ID for audio / image / video / document messages."""
        content = getattr(self, self.type, None)
        if content is not None and hasattr(content, "id"):
            return content.id
        return None


# ── Wrapper envelope models ───────────────────────────────────────────────────


class ContactProfile(_Resilient):
    name: Optional[str] = None


class Contact(_Resilient):
    profile: Optional[ContactProfile] = None
    wa_id: Optional[str] = None


class WebhookValue(_Resilient):
    messages: Optional[list[WhatsAppMessage]] = None
    contacts: Optional[list[Contact]] = None


class WebhookChange(_Resilient):
    value: WebhookValue
    field: Optional[str] = None


class WebhookEntry(_Resilient):
    id: Optional[str] = None
    changes: list[WebhookChange]


# ── Root payload ──────────────────────────────────────────────────────────────


class WhatsAppWebhookPayload(_Resilient):
    """
    Root Pydantic model for the Meta WhatsApp Cloud API webhook POST body.

    `.extract_message()` replaces raw dict traversal in whatsapp_service and
    returns the same normalized dict that the use-case layer already expects,
    now enriched with `media_id` for audio/image/video/document messages.
    """

    object: Optional[str] = None
    entry: list[WebhookEntry]

    def extract_message(self) -> Optional[dict[str, Any]]:
        """Return the first message as a normalized dict, or None if absent."""
        try:
            change = self.entry[0].changes[0]
            value = change.value
            if not value.messages:
                return None
            msg = value.messages[0]
            contact = (value.contacts or [None])[0]
            return {
                "phone": msg.from_,
                "message_id": msg.id,
                "type": msg.type,
                "text": msg.text_body,
                "name": contact.profile.name if contact and contact.profile else None,
                "media_id": msg.media_id,
            }
        except (IndexError, AttributeError):
            return None
