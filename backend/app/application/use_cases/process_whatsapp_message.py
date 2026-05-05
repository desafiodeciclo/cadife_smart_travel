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
  11. Update interaction with send outcome
"""
from __future__ import annotations

import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import LeadStatus, TipoMensagem
from app.models.lead import Lead
from app.models.user import User
from app.services import ai_service, curadoria_service, fcm_service, lead_service, whatsapp_service
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

    # ── Step 1: Get or create lead (Upsert) ───────────────────────────────
    lead_data = {
        "telefone": phone,
        "nome": msg.get("name"),
        "status": LeadStatus.novo,
    }
    lead: Lead = await lead_service.upsert_lead_with_resilience(db, lead_data)

    # ── Step 2: Advance status NOVO → EM_ATENDIMENTO ─────────────────────
    if lead.status == LeadStatus.novo:
        await lead_service.update_lead_status(db, lead, LeadStatus.em_atendimento)
        logger.info("lead_status_updated", lead_id=str(lead.id), new_status=LeadStatus.em_atendimento)

    # ── Step 2.5: Ensure conversation memory is loaded (restart-resilient) ─
    interacoes_list = await lead_service.get_recent_interacoes(db, lead.id, limit=20)
    ai_service.preload_memory_from_db(phone, interacoes_list)

    # ── Step 3: Generate AI reply or media fallback ────────────────────────
    reply: str
    tipo: TipoMensagem

    if msg_type != "text" or not text:
        reply = MEDIA_FALLBACK_REPLY
        tipo = (
            TipoMensagem(msg_type)
            if msg_type in TipoMensagem.__members__
            else TipoMensagem.texto
        )
    else:
        reply = await ai_service.process_message(phone, text)
        tipo = TipoMensagem.texto

        try:
            # ── Step 4: Extract briefing & update score ───────────────────
            status_antes = lead.status
            extracted = await ai_service.extract_briefing([{"role": "user", "content": text}])
            briefing = await lead_service.update_briefing_from_extraction(db, lead, extracted)

            # ── Step 5: FCM notification when lead qualifies ──────────────
            if briefing.completude_pct >= 60 and lead.status == LeadStatus.qualificado:
                await _notify_consultants(db, lead, briefing)

            # ── Step 5b: Offer curation appointment when freshly qualified ─
            if curadoria_service.deve_oferecer_curadoria(
                status_antes, lead.status, briefing.completude_pct
            ):
                if not await curadoria_service.lead_tem_agendamento_ativo(db, lead.id):
                    slots = await curadoria_service.get_proximos_slots_disponiveis(db, quantidade=3)
                    reply = curadoria_service.gerar_mensagem_oferta_curadoria(
                        slots, nome_cliente=lead.nome
                    )
                    logger.info(
                        "curadoria_offered",
                        lead_id=str(lead.id),
                        slots_count=len(slots),
                    )
                else:
                    logger.info(
                        "curadoria_skipped_already_scheduled",
                        lead_id=str(lead.id),
                    )
        except Exception as exc:
            logger.error("briefing_update_error", lead_id=str(lead.id), error=str(exc))

    # ── Step 6: Persist interaction record (sempre executado) ─────────────
    interacao = await lead_service.save_interacao(
        db, lead.id,
        msg_cliente=text,
        msg_ia=reply if msg_type == "text" else None,
        tipo=tipo,
    )

    # ── Step 8: Reply to client via WhatsApp; persist send outcome ────────
    send_result = await whatsapp_service.send_message(phone, reply)
    await lead_service.update_interacao_send_result(db, interacao, send_result)
    logger.info(
        "whatsapp_reply_dispatched",
        lead_id=str(lead.id),
        success=send_result.success,
        wamid=send_result.wamid,
        latency_ms=send_result.latency_ms,
        retries=send_result.retries_used,
    )


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
