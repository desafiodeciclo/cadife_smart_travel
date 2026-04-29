import hashlib
import hmac
from typing import Any, Optional

import httpx
import structlog

from app.core.config import get_settings

logger = structlog.get_logger()
settings = get_settings()

WHATSAPP_API_URL = "https://graph.facebook.com/v19.0"


def verify_signature(body: bytes, signature_header: str) -> bool:
    """Valida X-Hub-Signature-256 usando META_APP_SECRET conforme spec Meta."""
    if not signature_header.startswith("sha256="):
        return False
    secret = settings.META_APP_SECRET.encode()
    expected = hmac.new(secret, body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(f"sha256={expected}", signature_header)


def extract_message_from_payload(payload: dict[str, Any]) -> Optional[dict[str, Any]]:
    try:
        entry = payload["entry"][0]
        change = entry["changes"][0]
        value = change["value"]
        messages = value.get("messages", [])
        if not messages:
            return None
        msg = messages[0]
        contact = value.get("contacts", [{}])[0]
        return {
            "phone": msg["from"],
            "message_id": msg["id"],
            "type": msg.get("type", "text"),
            "text": msg.get("text", {}).get("body"),
            "name": contact.get("profile", {}).get("name"),
        }
    except (KeyError, IndexError):
        return None


async def send_message(phone: str, text: str) -> bool:
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
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(url, json=payload, headers=headers)
            response.raise_for_status()
            return True
    except Exception as exc:
        logger.error("whatsapp_send_error", phone=phone, error=str(exc))
        return False
