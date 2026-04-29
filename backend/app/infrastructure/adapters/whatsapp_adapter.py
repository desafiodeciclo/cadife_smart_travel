"""
WhatsApp Adapter — Infrastructure/Adapters Layer
=================================================
Thin adapter wrapping whatsapp_service for dependency injection.
Follows the Ports & Adapters pattern: the application layer depends
on the abstract interface; this class wires it to the concrete service.
"""
from __future__ import annotations

from app.services.whatsapp_service import (
    SendResult,
    extract_message_from_payload,
    send_message,
    send_template_message,
    verify_signature,
)


class WhatsAppAdapter:
    """Infrastructure adapter for the Meta WhatsApp Cloud API."""

    async def send(self, phone: str, message: str) -> SendResult:
        return await send_message(phone, message)

    async def send_template(
        self,
        phone: str,
        template_name: str,
        language: str = "pt_BR",
        components: list | None = None,
    ) -> SendResult:
        return await send_template_message(phone, template_name, language, components or [])

    def extract_message(self, payload: dict) -> dict | None:
        return extract_message_from_payload(payload)

    def verify_signature(self, body: bytes, signature: str) -> bool:
        return verify_signature(body, signature)
