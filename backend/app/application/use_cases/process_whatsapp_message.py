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
from app.services import (
    ai_service,
    curadoria_service,
    lead_service,
    model_router,
    whatsapp_service,
)
from app.services.notification_queue_service import NotificationQueueService
from app.services.domain_validator import BriefingValidator

logger = structlog.get_logger()

<<<<<<< feat/whatsapp-media-analysis-layer
# Message for audio messages specifically (task requirement)
AUDIO_FALLBACK_REPLY = (
    "Áudio não suportado nestes momentos, prefira o meio texto."
)

# Message for other unsupported media types (spec.md §12.3)
=======
# Fallback when media cannot be processed (download failure, model unavailable)
>>>>>>> developer
MEDIA_FALLBACK_REPLY = (
    "Recebi sua mensagem! Tive um problema ao processar esse arquivo. "
    "Pode me enviar o conteúdo em texto? Um consultor também pode te ajudar em breve. 😊"
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
    media_id: str | None = msg.get("media_id")

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
        logger.info(
            "lead_status_updated",
            lead_id=str(lead.id),
            new_status=LeadStatus.em_atendimento,
        )

    # ── Step 2.5: Ensure conversation memory is loaded (restart-resilient) ─
    interacoes_list = await lead_service.get_recent_interacoes(db, lead.id, limit=20)
    ai_service.preload_memory_from_db(phone, interacoes_list)

    # ── Step 3: Generate AI reply — route by message type ─────────────────
    reply: str
    tipo: TipoMensagem

<<<<<<< feat/whatsapp-media-analysis-layer
    if msg_type == "audio":
        # Best-effort download from Meta's Media API (logged; reply always sent)
        if media_id:
            audio_bytes = await whatsapp_service.download_media(media_id)
            logger.info(
                "audio_received",
                lead_id=str(lead.id),
                media_id=media_id,
                downloaded=audio_bytes is not None,
                size_bytes=len(audio_bytes) if audio_bytes else 0,
            )
        reply = AUDIO_FALLBACK_REPLY
        tipo = TipoMensagem.audio

    elif msg_type != "text" or not text:
=======
    # For media messages: attempt to convert to text via the model router.
    # On success, feed the transcript/description into the AI pipeline.
    # On failure (download error, model unavailable), fall back gracefully.
    effective_text: str | None = text
    if msg_type in ("audio", "voice", "image"):
        media_id: str | None = msg.get("media_id")
        media_mime: str = msg.get("media_mime_type") or ""
        caption: str | None = msg.get("text")  # image caption (may be None)

        if media_id:
            converted = await model_router.route_media_message(
                msg_type=msg_type,
                media_id=media_id,
                mime_type=media_mime,
                caption=caption,
            )
            if converted:
                effective_text = converted
                logger.info(
                    "media_converted_to_text",
                    lead_id=str(lead.id),
                    msg_type=msg_type,
                    chars=len(converted),
                )
            else:
                logger.warning(
                    "media_conversion_failed_using_fallback",
                    lead_id=str(lead.id),
                    msg_type=msg_type,
                )

    tipo = (
        TipoMensagem(msg_type)
        if msg_type in TipoMensagem.__members__
        else TipoMensagem.texto
    )

    if not effective_text:
>>>>>>> developer
        reply = MEDIA_FALLBACK_REPLY
    else:
        reply = await ai_service.process_message(phone, effective_text)
        tipo = TipoMensagem.texto

        try:
            # ── Step 4: Extract briefing & update score ───────────────────
            status_antes = lead.status
            extracted = await ai_service.extract_briefing(
                [{"role": "user", "content": effective_text}]
            )
            briefing = await lead_service.update_briefing_from_extraction(
                db, lead, extracted
            )

            # ── Step 5: Enqueue FCM notification when lead qualifies ─────
            if briefing.completude_pct >= 60 and lead.status == LeadStatus.qualificado:
                await _enqueue_qualified_notification(db, lead, briefing)

            # ── Step 5b: Offer curation appointment when freshly qualified ─
            if curadoria_service.deve_oferecer_curadoria(
                status_antes, lead.status, briefing.completude_pct
            ):
                if not await curadoria_service.lead_tem_agendamento_ativo(db, lead.id):
                    slots = await curadoria_service.get_proximos_slots_disponiveis(
                        db, quantidade=3
                    )
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
    # Save AYA's reply whenever there was processable text (original text or
    # transcribed/described media). For unprocessable media, reply is fallback.
    interacao = await lead_service.save_interacao(
        db,
        lead.id,
        msg_cliente=text,
        msg_ia=reply if effective_text else None,
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


async def _enqueue_qualified_notification(
    db: AsyncSession, lead: Lead, briefing
) -> None:
    """Enqueue FCM push notification for all agency consultants via background queue."""
    from sqlalchemy import select

    result = await db.execute(
        select(User).where(User.perfil == "agencia", User.fcm_token.isnot(None))
    )
    consultores = result.scalars().all()
    tokens = [c.fcm_token for c in consultores if c.fcm_token]

    if not tokens:
        logger.warning("no_consultant_tokens_for_notification", lead_id=str(lead.id))
        return

    queue_service = NotificationQueueService()
    await queue_service.enqueue_qualified_lead_notification(
        db=db,
        lead_id=lead.id,
        lead_nome=lead.nome,
        destino=briefing.destino,
        fcm_tokens=tokens,
    )
