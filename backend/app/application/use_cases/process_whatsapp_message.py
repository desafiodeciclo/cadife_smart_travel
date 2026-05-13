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


_FALLBACK_INFRA_REPLY = (
    "Recebi sua mensagem! Tivemos uma instabilidade momentânea. "
    "Um consultor da Cadife Tour irá te atender em breve. 😊"
)


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
    message_id: str | None = msg.get("message_id")
    text: str | None = msg.get("text")
    msg_type: str = msg.get("type", "text")
    media_id: str | None = msg.get("media_id")

    logger.info("processing_whatsapp_message", phone=phone, msg_type=msg_type, message_id=message_id)

    try:
        await _execute_inner(
            phone=phone,
            message_id=message_id,
            text=text,
            msg_type=msg_type,
            media_id=media_id,
            msg=msg,
            db=db,
        )
    except Exception as exc:
        logger.error(
            "execute_unhandled_error",
            phone=phone[-4:] if len(phone) >= 4 else "****",
            error=str(exc),
            error_type=type(exc).__name__,
        )
        try:
            await whatsapp_service.send_message(phone, _FALLBACK_INFRA_REPLY)
        except Exception:
            pass


async def _execute_inner(
    *,
    phone: str,
    message_id: str | None,
    text: str | None,
    msg_type: str,
    media_id: str | None,
    msg: dict,
    db: AsyncSession,
) -> None:
    # Mark message as read early
    if message_id:
        await whatsapp_service.mark_as_read(phone, message_id)

    # ── Step 1: Get or create lead (Upsert) ───────────────────────────────
    lead_data = {
        "telefone": phone,
        "nome": msg.get("name"),
        "status": LeadStatus.novo,
    }
    lead: Lead = await lead_service.upsert_lead_with_resilience(db, lead_data)

    # ── AYA Gate: se AYA desativada, persiste mensagem e notifica consultor ──
    if not lead.aya_ativo:
        tipo_gate: TipoMensagem = (
            TipoMensagem(msg_type)
            if msg_type in TipoMensagem.__members__
            else TipoMensagem.texto
        )
        await lead_service.save_interacao(
            db, lead.id, msg_cliente=text, msg_ia=None, tipo=tipo_gate
        )
        await _enqueue_aya_disabled_notification(db, lead)
        logger.info("aya_disabled_message_persisted", lead_id=str(lead.id), phone=phone)
        return

    # ── Step 2: Advance status NOVO → EM_ATENDIMENTO ─────────────────────
    is_new_lead = lead.status == LeadStatus.novo
    if is_new_lead:
        await lead_service.update_lead_status(db, lead, LeadStatus.em_atendimento)
        logger.info(
            "lead_status_updated",
            lead_id=str(lead.id),
            new_status=LeadStatus.em_atendimento,
        )
        await _notify_new_lead_creation(db, lead)

    lead_id = lead.id

    # ── Step 2.5: Carrega histórico do DB (restart-resilient) ────────────────
    interacoes_list = await lead_service.get_recent_interacoes(db, lead_id, limit=20)
    ai_service.preload_memory_from_db(phone, interacoes_list)

    # --- RESOLUÇÃO DO CONFLITO ---

    # 1. Formata histórico para o orquestrador (Essencial para Step 4)
    conversation_history: list[dict[str, str]] = []
    for row in interacoes_list:
        cliente_msg = row.get("mensagem_cliente")
        ia_msg = row.get("mensagem_ia")
        if cliente_msg:
            conversation_history.append({"role": "user", "content": cliente_msg})
        if ia_msg:
            conversation_history.append({"role": "assistant", "content": ia_msg})

    # 2. Notifica consultor que o cliente respondeu (Sua funcionalidade)
    if lead.consultor_id:
        await _enqueue_message_received_notification(db, lead, text or "Mídia recebida")

    # 3. Resolução de mídia — transcreve áudio antes de processar
    _original_msg_type = msg_type
    transcription_used = False

    # --- FIM DA RESOLUÇÃO ---

    if msg_type in ("audio", "voice") and media_id:
        mime_type = msg.get("mime_type", "audio/ogg")
        transcribed = await model_router.route_media_message(
            msg_type, media_id, mime_type
        )
        if transcribed:
            text = transcribed
            msg_type = "text"  
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
        tipo = TipoMensagem.audio if transcription_used else TipoMensagem.texto

        reply = await multi_agent_orchestrator.orchestrate(
            wa_id=phone,
            message=text,
            conversation_history=conversation_history,
            db=db,
        )

        lead_id_str = str(lead_id)
        status_antes = lead.status

        try:
            full_conv_for_briefing = conversation_history + [
                {"role": "user", "content": text}
            ]
            extracted = await ai_service.extract_briefing(full_conv_for_briefing)
            briefing = await lead_service.update_briefing_from_extraction(
                db, lead, extracted
            )

            if briefing.completude_pct >= 60 and lead.status == LeadStatus.qualificado:
                await _enqueue_qualified_notification(db, lead, briefing)

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
                    logger.info("curadoria_offered", lead_id=lead_id_str, slots_count=len(slots))
        except Exception as exc:
            try:
                await db.rollback()
            except Exception as rollback_exc:
                logger.error(
                    "db_rollback_failed",
                    lead_id=lead_id_str,
                    error=str(rollback_exc),
                )
            logger.error("briefing_update_error", lead_id=lead_id_str, error=str(exc))

    # ── Step 6: Persist interaction record ─────────────────────────────
    interacao = await lead_service.save_interacao(
        db,
        lead_id,
        msg_cliente=text,
        msg_ia=reply,
        tipo=tipo,
        whatsapp_message_id=message_id,
    )

    if interacao.status_envio == "sent":
        logger.info("skipping_replay_reply", lead_id=str(lead_id), message_id=message_id)
        return

    # ── Step 8: Reply via WhatsApp ──────────────────────────────────────
    send_result = await whatsapp_service.send_message(phone, reply)
    await lead_service.update_interacao_send_result(db, interacao, send_result)

    # ── Step 9: Detect closed sessions and generate conversation summaries ──
    # Runs after the interaction is persisted so the current message is included.
    # Non-blocking: failures are caught and logged without affecting the main flow.
    try:
        from app.services.conversation_summary_service import summarise_closed_sessions

        all_interacoes = await lead_service.get_recent_interacoes(db, lead_id, limit=500)
        await summarise_closed_sessions(db, lead_id, all_interacoes)
    except Exception as exc:
        logger.warning(
            "conversation_summary_trigger_failed",
            lead_id=str(lead_id),
            error=str(exc),
        )


async def _notify_new_lead_creation(db: AsyncSession, lead: Lead) -> None:
    """Send FCM push to the assigned consultor or next in round-robin queue.

    Round-robin: increments a Redis counter and picks consultores[idx % count].
    Falls back to the first available consultor when Redis is unavailable.
    """
    from sqlalchemy import select

    # Honour explicit assignment first
    target_token: str | None = None
    if lead.consultor_id:
        result = await db.execute(
            select(User).where(User.id == lead.consultor_id, User.fcm_token.isnot(None))
        )
        consultor = result.scalar_one_or_none()
        if consultor:
            target_token = consultor.fcm_token

    if not target_token:
        # Round-robin across active consultores with FCM tokens
        result = await db.execute(
            select(User)
            .where(
                User.perfil == "consultor",
                User.fcm_token.isnot(None),
                User.is_active.is_(True),
            )
            .order_by(User.criado_em)
        )
        consultores = result.scalars().all()
        if consultores:
            try:
                from app.infrastructure.cache.redis_client import get_redis

                redis = await get_redis()
                idx = await redis.incr("rr:consultor:new_lead")
                chosen = consultores[(idx - 1) % len(consultores)]
            except Exception:
                chosen = consultores[0]
            target_token = chosen.fcm_token

    if not target_token:
        logger.warning("no_consultor_token_for_new_lead", lead_id=str(lead.id))
        return

    from app.services.fcm_service import send_push_notification

    await send_push_notification(
        fcm_token=target_token,
        title="Novo lead recebido",
        body=f"Novo contato via WhatsApp: {lead.nome or lead.telefone}",
        data={"type": "new_lead", "lead_id": str(lead.id)},
    )
    logger.info("fcm_new_lead_sent", lead_id=str(lead.id))


# --- Funções Auxiliares de Notificação ---

async def _enqueue_aya_disabled_notification(db: AsyncSession, lead: Lead) -> None:
    from sqlalchemy import select
    from app.models.notification_queue import NotificationQueue

    if not lead.consultor_id:
        return

    result = await db.execute(
        select(User).where(User.id == lead.consultor_id, User.fcm_token.isnot(None))
    )
    consultor = result.scalar_one_or_none()
    if not consultor or not consultor.fcm_token:
        return

    job = NotificationQueue(
        lead_id=lead.id,
        status="pending",
        payload={
            "title": "Mensagem recebida — AYA desativada",
            "body": f"{lead.nome or 'Cliente'} enviou uma mensagem. Você está em atendimento manual.",
            "data": {"type": "aya_disabled_message", "lead_id": str(lead.id)},
            "fcm_tokens": [consultor.fcm_token],
        },
    )
    db.add(job)
    await db.commit()

async def _enqueue_message_received_notification(db: AsyncSession, lead: Lead, text: str) -> None:
    from sqlalchemy import select
    from app.models.notification_queue import NotificationQueue

    if not lead.consultor_id:
        return

    result = await db.execute(
        select(User).where(User.id == lead.consultor_id, User.fcm_token.isnot(None))
    )
    consultor = result.scalar_one_or_none()
    if not consultor or not consultor.fcm_token:
        return

    resumo = (text[:50] + "...") if len(text) > 50 else text
    job = NotificationQueue(
        lead_id=lead.id,
        status="pending",
        payload={
            "title": f"Resposta de {lead.nome or 'Cliente'}",
            "body": resumo,
            "data": {"type": "new_customer_message", "lead_id": str(lead.id)},
            "fcm_tokens": [consultor.fcm_token],
        },
    )
    db.add(job)
    await db.commit()

async def _enqueue_qualified_notification(db: AsyncSession, lead: Lead, briefing) -> None:
    from sqlalchemy import select
    result = await db.execute(
        select(User).where(User.perfil == "agencia", User.fcm_token.isnot(None))
    )
    consultores = result.scalars().all()
    tokens = [c.fcm_token for c in consultores if c.fcm_token]

    if not tokens: return

    queue_service = NotificationQueueService()
    await queue_service.enqueue_qualified_lead_notification(
        db=db,
        lead_id=lead.id,
        lead_nome=lead.nome,
        destino=briefing.destino,
        fcm_tokens=tokens,
    )