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

import asyncio
import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import LeadStatus, TipoMensagem
from app.infrastructure.persistence.database import AsyncSessionLocal
from app.models.lead import Lead
from app.models.user import User
from app.services import (
    ai_service,
    curadoria_service,
    lead_service,
    model_router,
    multi_agent_orchestrator,
    whatsapp_service,
)
from app.services.notification_queue_service import NotificationQueueService
from app.services.domain_validator import BriefingValidator

logger = structlog.get_logger()

# Message for audio messages specifically (task requirement)
AUDIO_FALLBACK_REPLY = (
    "Áudio não suportado nestes momentos, prefira o meio texto."
)

# Message for other unsupported media types (spec.md §12.3)
MEDIA_FALLBACK_REPLY = (
    "Recebi sua mensagem! Tive um problema ao processar esse arquivo. "
    "Pode me enviar o conteúdo em texto? Um consultor também pode te ajudar em breve. 😊"
)

_validator = BriefingValidator()

# FIFO lock per phone — prevents concurrent processing of messages from the
# same number, which would cause rate-limit amplification and DB race conditions.
_phone_locks: dict[str, asyncio.Lock] = {}


async def execute_with_own_session(payload: dict) -> None:
    """
    BackgroundTask entry point — creates its own DB session to avoid
    greenlet_spawn errors caused by reusing a request-scoped session after
    the HTTP response has been sent and the request context has been torn down.
    """
    async with AsyncSessionLocal() as db:
        await execute(payload, db)


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
    async with _phone_locks.setdefault(phone, asyncio.Lock()):
        await _process(msg, db)


async def _process(msg: dict, db: AsyncSession) -> None:
    """Serialized per-phone processing — always called under the phone lock."""
    phone: str = msg["phone"]
    message_id: str | None = msg.get("message_id")
    text: str | None = msg.get("text")
    msg_type: str = msg.get("type", "text")
    media_id: str | None = msg.get("media_id")

    logger.info("processing_whatsapp_message", phone=phone, msg_type=msg_type)

    # Mark message as read early — shows blue ticks before we even generate a reply,
    # signalling to the client that AYA received the message.
    if message_id:
        await whatsapp_service.mark_as_read(phone, message_id)

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

    # Cache lead_id e status antes de qualquer branch — após commit/rollback o SQLAlchemy
    # expira todos os atributos do lead, causando MissingGreenlet se acessados depois.
    lead_id = lead.id
    status_antes = lead.status

    # ── Step 2.5: Carrega histórico do DB (source of truth) ─────────────────
    interacoes_list = await lead_service.get_recent_interacoes(db, lead_id, limit=20)

    # Formata histórico para o orquestrador — interleave correto user + assistant.
    # Cada row de interacao contém AMBAS as mensagens (cliente e IA), então cada
    # row gera até dois turnos no histórico, preservando a alternância real.
    conversation_history: list[dict[str, str]] = []
    for row in interacoes_list:
        cliente_msg = row.get("mensagem_cliente")
        ia_msg = row.get("mensagem_ia")
        if cliente_msg:
            conversation_history.append({"role": "user", "content": cliente_msg})
        if ia_msg:
            conversation_history.append({"role": "assistant", "content": ia_msg})

    # ── Step 3: Resolução de mídia — transcreve áudio antes de processar ─────
    # wa_id = phone (número WhatsApp sem '+') usado como chave de lookup CRM
    _original_msg_type = msg_type
    transcription_used = False

    if msg_type in ("audio", "voice") and media_id:
        mime_type = msg.get("mime_type", "audio/ogg")
        transcribed = await model_router.route_media_message(
            msg_type, media_id, mime_type
        )
        if transcribed:
            text = transcribed
            msg_type = "text"  # recast: trata áudio transcrito como mensagem de texto
            transcription_used = True
            logger.info(
                "audio_transcribed_injected",
                lead_id=str(lead.id),
                chars=len(transcribed),
            )

    # ── Step 4: Geração da resposta via orquestrador multi-agente ─────────────
    reply: str
    tipo: TipoMensagem

    if msg_type != "text" or not text:
        # Mídia não suportada ou áudio sem transcrição
        reply = (
            AUDIO_FALLBACK_REPLY
            if _original_msg_type in ("audio", "voice")
            else MEDIA_FALLBACK_REPLY
        )
        tipo = (
            TipoMensagem.audio
            if _original_msg_type in ("audio", "voice")
            else (
                TipoMensagem(_original_msg_type)
                if _original_msg_type in TipoMensagem.__members__
                else TipoMensagem.texto
            )
        )
    else:
        # Texto puro ou áudio transcrito → orquestrador multi-agente
        tipo = TipoMensagem.audio if transcription_used else TipoMensagem.texto

        reply = await multi_agent_orchestrator.orchestrate(
            wa_id=phone,
            message=text,
            conversation_history=conversation_history,
            db=db,
        )

        # Tool calls inside orchestrate may commit the session, expiring `lead`.
        # Refresh so subsequent attribute accesses (lead.status, lead.nome) don't
        # raise MissingGreenlet.
        await db.refresh(lead)

        lead_id_str = str(lead_id)

        try:
            # ── Step 5: Extrai briefing & atualiza score ──────────────────
            # Passa o histórico COMPLETO (não só a mensagem atual) para que o
            # extrator acumule dados de turnos anteriores corretamente.
            full_conv_for_briefing = conversation_history + [
                {"role": "user", "content": text}
            ]
            extracted = await ai_service.extract_briefing(full_conv_for_briefing)
            briefing = await lead_service.update_briefing_from_extraction(
                db, lead, extracted
            )

            # ── Step 6: Enfileira notificação FCM se lead qualificar ──────
            if briefing.completude_pct >= 60 and lead.status == LeadStatus.qualificado:
                await _enqueue_qualified_notification(db, lead, briefing)

            # ── Step 6b: Oferta de curadoria quando recém-qualificado ─────
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
                        lead_id=lead_id_str,
                        slots_count=len(slots),
                    )
                else:
                    logger.info(
                        "curadoria_skipped_already_scheduled",
                        lead_id=lead_id_str,
                    )
        except Exception as exc:
            # Rollback explícito para limpar qualquer transação pendente antes
            # de continuar — evita PendingRollbackError nas etapas seguintes.
            try:
                await db.rollback()
            except Exception as rb_exc:
                logger.error("briefing_rollback_failed", lead_id=lead_id_str, error=str(rb_exc))
            logger.error("briefing_update_error", lead_id=lead_id_str, error=str(exc))

    # ── Step 6: Persist interaction record (sempre executado) ─────────────
    # Save AYA's reply whenever there was processable text (original text or
    # transcribed/described media). For unprocessable media, reply is fallback.
    interacao = await lead_service.save_interacao(
        db,
        lead_id,
        msg_cliente=text,
        msg_ia=reply,
        tipo=tipo,
    )

    # ── Step 8: Reply to client via WhatsApp; persist send outcome ────────
    send_result = await whatsapp_service.send_message(phone, reply)
    await lead_service.update_interacao_send_result(db, interacao, send_result)
    logger.info(
        "whatsapp_reply_dispatched",
        lead_id=str(lead_id),
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
