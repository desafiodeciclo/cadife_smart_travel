"""
Process WhatsApp Message — Application/Use Cases Layer
=======================================================
Orchestrates the full message-processing flow defined in spec.md §9.1:
  1. Extract message from payload
  2. Get or create lead
  3. Update lead status
  4. Process text with AI / handle media fallback
  5. Extract briefing data
  6. Validate domain rules
  7. Update briefing & compute score (only if validation passes)
  8. Trigger FCM notification if lead qualifies
  9. Save interaction record
  10. Reply via WhatsApp
"""
from __future__ import annotations

import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import LeadStatus, TipoMensagem
from app.models.lead import Lead
from app.models.user import User
from app.services import ai_service, fcm_service, lead_service, whatsapp_service
from app.services.domain_validator import BriefingValidator

logger = structlog.get_logger()

# Message for unsupported media types (spec.md §12.3)
MEDIA_FALLBACK_REPLY = (
    "Recebi sua mensagem! No momento aceito apenas textos. "
    "Um consultor irá te atender em breve. 😊"
)

_validator = BriefingValidator()


async def execute(payload: dict, db: AsyncSession) -> None:
    """
    Main use-case entry point. Called as a BackgroundTask from the webhook
    so the HTTP 200 is returned to Meta immediately (spec.md §13 — timeout risk mitigation).
    """
    msg = whatsapp_service.extract_message_from_payload(payload)
    if not msg:
        logger.debug("webhook_payload_ignored", reason="no_message_extracted")
        return

    phone: str = msg["phone"]
    text: str | None = msg.get("text")
    msg_type: str = msg.get("type", "text")

    logger.info("processing_whatsapp_message", phone=phone, msg_type=msg_type)

    # ── Step 1: Get or create lead ────────────────────────────────────────
    lead: Lead = await lead_service.get_or_create_by_phone(db, phone, msg.get("name"))

    # ── Step 2: Advance status NOVO → EM_ATENDIMENTO ─────────────────────
    if lead.status == LeadStatus.novo:
        await lead_service.update_lead_status(db, lead, LeadStatus.em_atendimento)
        logger.info("lead_status_updated", lead_id=str(lead.id), new_status=LeadStatus.em_atendimento)

    # ── Step 3: Generate AI reply or media fallback ────────────────────────
    if msg_type != "text" or not text:
        reply = MEDIA_FALLBACK_REPLY
        tipo = (
            TipoMensagem(msg_type)
            if msg_type in TipoMensagem.__members__
            else TipoMensagem.texto
        )
    else:
        # ── Step 4: Extract briefing ────────────────────────────────────
        extracted = await ai_service.extract_briefing([{"role": "user", "content": text}])

        # ── Step 5: Validate domain rules ───────────────────────────────
        validation = _validator.validate(extracted)

        if not validation.is_valid:
            # Domain validation failed → corrective feedback via AI
            reply = await ai_service.process_message(
                phone, text, validation_errors=validation.errors
            )
            logger.info(
                "validation_corrective_response",
                phone=phone,
                errors=validation.errors,
            )
            tipo = TipoMensagem.texto
        else:
            # Domain validation passed → normal response + persist briefing
            reply = await ai_service.process_message(phone, text, briefing=extracted)
            briefing = await lead_service.update_briefing_from_extraction(db, lead, extracted)
            tipo = TipoMensagem.texto

            # ── Step 6: FCM notification when lead qualifies ──────────
            # spec.md §8.1: notify consultant in < 2 seconds
            if briefing.completude_pct >= 60 and lead.status == LeadStatus.qualificado:
                await _notify_consultants(db, lead, briefing)

    # ── Step 7: Persist interaction record ────────────────────────────────
    await lead_service.save_interacao(
        db, lead.id,
        msg_cliente=text,
        msg_ia=reply if msg_type == "text" else None,
        tipo=tipo,
    )

    # ── Step 8: Reply to client via WhatsApp ──────────────────────────────
    await whatsapp_service.send_message(phone, reply)


async def _notify_consultants(db: AsyncSession, lead: Lead, briefing) -> None:
    """Send FCM push to all agency consultants with an active device token."""
    from sqlalchemy import select

    result = await db.execute(
        select(User).where(User.perfil == "agencia", User.fcm_token.isnot(None))
    )
    consultores = result.scalars().all()

    for consultor in consultores:
        try:
            if consultor.fcm_token:
                await fcm_service.notify_new_lead(
                    consultor.fcm_token,
                    lead.nome or lead.telefone,
                    briefing.destino,
                )
        except Exception as exc:
            logger.error("fcm_notification_failed", consultor_id=str(consultor.id), error=str(exc))
