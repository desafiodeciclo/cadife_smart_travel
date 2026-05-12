"""
WhatsApp Cloud API — Services Layer
=====================================
Encapsulates all outbound/inbound Meta WhatsApp Cloud API operations.
Implements spec.md §9.1: after AI processing, send reply back to customer.

Retry policy (exponential backoff):
  Transient status codes: 429, 500, 502, 503, 504
  Max retries: 3  |  Base delay: 0.5 s  |  Max delay: 4 s
  Timeout per attempt: 3 s (spec requirement)
"""

from __future__ import annotations

import asyncio
import hashlib
import hmac
import time
from dataclasses import dataclass
from typing import Any, Optional

import httpx
import structlog

from app.core.config import get_settings

logger = structlog.get_logger()
settings = get_settings()

WHATSAPP_API_URL = "https://graph.facebook.com/v25.0"


_TRANSIENT_STATUS_CODES = frozenset({429, 500, 502, 503, 504})
_MAX_RETRIES = 3
_BASE_DELAY_S = 0.5
_MAX_DELAY_S = 4.0
_TIMEOUT_S = 3.0          # send_message / mark_as_read (Meta SLA ≤ 5s)
_MEDIA_TIMEOUT_S = 20.0   # download_media — áudio WhatsApp pode ter vários MB


# ── Exceptions ────────────────────────────────────────────────────────────────


class WhatsAppSendError(Exception):
    """Raised when the Meta API call fails after exhausting all retries."""

    def __init__(
        self,
        phone: str,
        reason: str,
        status_code: Optional[int] = None,
    ) -> None:
        self.phone = phone
        self.reason = reason
        self.status_code = status_code
        super().__init__(f"WhatsApp send failed for {_mask_phone(phone)}: {reason}")


# ── Result type ───────────────────────────────────────────────────────────────


@dataclass
class SendResult:
    """Outcome of a send_message call. Callers should persist this."""

    success: bool
    wamid: Optional[str] = None  # WhatsApp message ID returned by Meta
    error: Optional[str] = None  # human-readable failure reason
    retries_used: int = 0
    latency_ms: int = 0


# ── Helpers ───────────────────────────────────────────────────────────────────


def _mask_phone(phone: str) -> str:
    """Mask last 4 digits for PII-safe logging (spec.md §5.1)."""
    return phone[:-4] + "****" if len(phone) >= 4 else "****"


# ── Public API ────────────────────────────────────────────────────────────────


def verify_signature(body: bytes, signature_header: str) -> bool:
    """Valida X-Hub-Signature-256 usando META_APP_SECRET conforme spec Meta."""
    if not signature_header.startswith("sha256="):
        return False
    secret = settings.META_APP_SECRET.encode()
    expected = hmac.new(secret, body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(f"sha256={expected}", signature_header)


def extract_message_from_payload(payload: dict[str, Any]) -> Optional[dict[str, Any]]:
    """Extract the first message from a Meta webhook payload. Returns None if absent.

    The returned dict always includes `media_id` (None for text messages) so
    callers can dispatch on type without additional parsing.
    """
    try:
        entry = payload["entry"][0]
        change = entry["changes"][0]
        value = change["value"]
        messages = value.get("messages", [])
        if not messages:
            return None
        msg = messages[0]
        contact = value.get("contacts", [{}])[0]
        msg_type: str = msg.get("type", "text")

        # Extract media ID and mime_type from the type-specific sub-object (audio, image, etc.)
        media_id: Optional[str] = None
        mime_type: Optional[str] = None
        media_data = msg.get(msg_type)
        if isinstance(media_data, dict):
            media_id = media_data.get("id")
            mime_type = media_data.get("mime_type")  # e.g. "audio/ogg; codecs=opus"

        return {
            "phone": msg["from"],
            "message_id": msg["id"],
            "type": msg_type,
            "text": msg.get("text", {}).get("body"),
            "name": contact.get("profile", {}).get("name"),
            "media_id": media_id,
            "mime_type": mime_type,
        }
    except (KeyError, IndexError):
        return None


async def download_media(media_id: str) -> Optional[bytes]:
    """Download a media file from Meta's Media API by its ID.

    Two-step process required by Meta:
      1. GET /{media_id} → JSON with a short-lived `url`
      2. GET {url} (with Auth header) → raw media bytes

    Returns the raw bytes on success, or None on any failure so callers can
    treat this as best-effort (the fallback reply is always sent regardless).
    """
    headers = {"Authorization": f"Bearer {settings.WHATSAPP_TOKEN}"}

    async with httpx.AsyncClient(timeout=_MEDIA_TIMEOUT_S) as client:
        # Step 1: resolve the temporary download URL
        try:
            meta_resp = await client.get(
                f"{WHATSAPP_API_URL}/{media_id}", headers=headers
            )
        except httpx.RequestError as exc:
            logger.warning("media_url_fetch_failed", media_id=media_id, error=str(exc))
            return None

        if meta_resp.status_code != 200:
            logger.warning(
                "media_url_non_200",
                media_id=media_id,
                status_code=meta_resp.status_code,
            )
            return None

        download_url: Optional[str] = meta_resp.json().get("url")
        if not download_url:
            logger.warning("media_url_missing_in_response", media_id=media_id)
            return None

        # Step 2: download the raw media bytes
        try:
            media_resp = await client.get(download_url, headers=headers)
        except httpx.RequestError as exc:
            logger.warning("media_download_failed", media_id=media_id, error=str(exc))
            return None

        if media_resp.status_code != 200:
            logger.warning(
                "media_download_non_200",
                media_id=media_id,
                status_code=media_resp.status_code,
            )
            return None

        logger.info(
            "media_downloaded",
            media_id=media_id,
            bytes=len(media_resp.content),
        )
        return media_resp.content


async def mark_as_read(phone: str, message_id: str) -> None:
    """Mark an incoming WhatsApp message as read (shows blue double-ticks).

    Best-effort: failures are logged but never raised, so they never block
    the main processing pipeline.
    """
    url = f"{WHATSAPP_API_URL}/{settings.PHONE_NUMBER_ID}/messages"
    headers = {
        "Authorization": f"Bearer {settings.WHATSAPP_TOKEN}",
        "Content-Type": "application/json",
    }
    payload = {
        "messaging_product": "whatsapp",
        "status": "read",
        "message_id": message_id,
    }
    masked = _mask_phone(phone)
    try:
        async with httpx.AsyncClient(timeout=_TIMEOUT_S) as client:
            response = await client.post(url, json=payload, headers=headers)
            if response.status_code == 200:
                logger.debug("whatsapp_message_marked_read", phone=masked, message_id=message_id)
            else:
                logger.warning(
                    "whatsapp_mark_read_failed",
                    phone=masked,
                    message_id=message_id,
                    status_code=response.status_code,
                )
    except Exception as exc:
        logger.warning("whatsapp_mark_read_error", phone=masked, error=str(exc))


async def send_message(phone: str, text: str) -> SendResult:
    """
    Send a plain-text message to a WhatsApp number via Meta Cloud API.

    Retries on transient HTTP errors with exponential backoff.
    Returns SendResult — callers are responsible for persisting the outcome.

    Does NOT raise on failure; a failed SendResult is returned instead
    so the background worker can record it without crashing the queue.
    """
    url = f"{WHATSAPP_API_URL}/{settings.PHONE_NUMBER_ID}/messages"
    headers = {
        "Authorization": f"Bearer {settings.WHATSAPP_TOKEN}",
        "Content-Type": "application/json",
    }
    payload = {
        "messaging_product": "whatsapp",
        "to": phone,
        "type": "text",
        "text": {"body": text},
    }
    masked = _mask_phone(phone)
    t0 = time.monotonic()
    retries = 0
    last_error: Optional[str] = None
    last_status: Optional[int] = None

    async with httpx.AsyncClient(timeout=_TIMEOUT_S) as client:
        while retries <= _MAX_RETRIES:
            try:
                response = await client.post(url, json=payload, headers=headers)
                latency_ms = int((time.monotonic() - t0) * 1000)

                if response.status_code == 200:
                    body = response.json()
                    wamid = (body.get("messages") or [{}])[0].get("id")
                    logger.info(
                        "whatsapp_message_sent",
                        phone=masked,
                        wamid=wamid,
                        latency_ms=latency_ms,
                        retries=retries,
                    )
                    return SendResult(
                        success=True,
                        wamid=wamid,
                        retries_used=retries,
                        latency_ms=latency_ms,
                    )

                last_status = response.status_code
                last_error = f"HTTP {response.status_code}: {response.text[:200]}"

                if response.status_code not in _TRANSIENT_STATUS_CODES:
                    logger.error(
                        "whatsapp_send_non_retryable",
                        phone=masked,
                        status_code=last_status,
                        error=last_error,
                        latency_ms=latency_ms,
                    )
                    break

                logger.warning(
                    "whatsapp_send_transient_error",
                    phone=masked,
                    status_code=last_status,
                    attempt=retries + 1,
                    latency_ms=latency_ms,
                )

            except httpx.TimeoutException:
                last_error = f"timeout after {_TIMEOUT_S}s"
                logger.warning(
                    "whatsapp_send_timeout",
                    phone=masked,
                    attempt=retries + 1,
                    elapsed_ms=int((time.monotonic() - t0) * 1000),
                )

            except httpx.RequestError as exc:
                last_error = f"request error: {exc}"
                logger.warning(
                    "whatsapp_send_request_error",
                    phone=masked,
                    error=last_error,
                    attempt=retries + 1,
                )

            retries += 1
            if retries <= _MAX_RETRIES:
                delay = min(_BASE_DELAY_S * (2 ** (retries - 1)), _MAX_DELAY_S)
                logger.info(
                    "whatsapp_send_retry",
                    phone=masked,
                    attempt=retries,
                    delay_s=delay,
                    reason=last_error,
                )
                await asyncio.sleep(delay)

    latency_ms = int((time.monotonic() - t0) * 1000)
    logger.error(
        "whatsapp_send_failed",
        phone=masked,
        retries=retries,
        last_status=last_status,
        error=last_error,
        latency_ms=latency_ms,
    )
    return SendResult(
        success=False,
        error=last_error,
        retries_used=retries,
        latency_ms=latency_ms,
    )
