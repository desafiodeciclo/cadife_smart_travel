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

from sqlalchemy import select

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

# Fallback when audio transcription fails — friendly, not misleading
AUDIO_FALLBACK_REPLY = (
    "Recebi seu áudio! Infelizmente não consegui processá-lo desta vez. "
    "Pode me enviar sua mensagem em texto? Vou continuar te ajudando! 😊"
)

# Message for other unsupported media types (spec.md §12.3)
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
        # Distinguish status events (delivered, read, failed) from truly empty payloads
        statuses = whatsapp_service.extract_status_from_payload(payload)
        if statuses:
            for s in statuses:
                logger.info(
                    "whatsapp_status_event",
                    status=s.get("status"),
                    wamid=s.get("id"),
                    recipient=s.get("recipient_id"),
                )
        else:
            logger.debug("webhook_payload_ignored", reason="no_message_extracted")
        return

    phone: str = msg["phone"]
    message_id: str | None = msg.get("message_id")
    text: str | None = msg.get("text")
    msg_type: str = msg.get("type", "text")
    media_id: str | None = msg.get("media_id")

    # Idempotency guard: Meta may re-send webhooks on timeout (at-least-once delivery).
    # Check wamid before any AI processing to avoid duplicate side-effects.
    if message_id:
        from sqlalchemy import select as _select
        from app.models.interacao import Interacao as _Interacao
        _dup = await db.scalar(
            _select(_Interacao.id).where(_Interacao.whatsapp_message_id == message_id).limit(1)
        )
        if _dup is not None:
            logger.info("duplicate_webhook_ignored", wamid=message_id, phone=phone)
            return

    _masked_phone = f"+55...{phone[-4:]}" if len(phone) >= 4 else "***"
    logger.info("processing_whatsapp_message", phone=_masked_phone, msg_type=msg_type)

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

    # ── Step 2.5: Carrega histórico do DB (restart-resilient) ────────────────
    interacoes_list = await lead_service.get_recent_interacoes(db, lead_id, limit=20)
    await ai_service.preload_memory_from_db(phone, interacoes_list)
    _memory = ai_service.get_memory(phone)
    _memory_summary = _memory._summary  # Resumo comprimido; restaurado do Redis se worker novo

    # Timestamp da interação mais recente passado direto do DB — mais confiável
    # do que confiar na extração do TriagemAgent (LLM pode errar o parse).
    _last_interaction_at: str | None = None
    if interacoes_list:
        _last_ts = interacoes_list[-1].get("timestamp")
        if _last_ts is not None:
            _last_interaction_at = (
                _last_ts.isoformat() if hasattr(_last_ts, "isoformat") else str(_last_ts)
            )

    # ── Step 2.6: Verificação pré-orquestrador ────────────────────────────────
    # Lê o briefing ANTES do LangGraph para que o system prompt chegue informado,
    # eliminando a tool call get_lead_context_by_wa_id quando o briefing já está completo.
    from app.infrastructure.persistence.repositories.briefing_repository import (
        BriefingRepository,
    )

    _briefing_pre = await BriefingRepository(db).get_by_lead(lead_id)
    _pre_validated_briefing: dict | None = None
    _validation_errors: list[str] = []

    if _briefing_pre:
        _pre_validated_briefing = {
            "completude_pct": _briefing_pre.completude_pct,
            "destino": _briefing_pre.destino,
            "data_ida": str(_briefing_pre.data_ida) if _briefing_pre.data_ida else None,
            "data_volta": str(_briefing_pre.data_volta) if _briefing_pre.data_volta else None,
            "qtd_pessoas": _briefing_pre.qtd_pessoas,
            "perfil": _briefing_pre.perfil,
            "orcamento": _briefing_pre.orcamento,
            "tem_passaporte": _briefing_pre.tem_passaporte,
        }
        _validation_errors = _validator.validate(_briefing_pre)
        logger.info(
            "pre_orchestrator_briefing_loaded",
            lead_id=str(lead_id),
            completude_pct=_briefing_pre.completude_pct,
            has_errors=bool(_validation_errors),
        )

    # Histórico via SimpleWindowMemory — inclui pares recentes (até k=20) sem a
    # mensagem de sistema do resumo (que vai separada em memory_summary).
    _mem_vars = _memory.load_memory_variables({})
    conversation_history: list[dict[str, str]] = [
        m for m in _mem_vars.get("chat_history", []) if m["role"] != "system"
    ]

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

        import structlog as _structlog
        _correlation_id = _structlog.contextvars.get_contextvars().get("request_id")
        reply = await multi_agent_orchestrator.orchestrate(
            wa_id=phone,
            message=text,
            conversation_history=conversation_history,
            db=db,
            pre_validated_briefing=_pre_validated_briefing,
            validation_errors=_validation_errors,
            memory_summary=_memory_summary,
            last_interaction_at=_last_interaction_at,
            lead_status_db=status_antes.value if status_antes else None,
            correlation_id=_correlation_id,
        )

        # Tool calls inside orchestrate may commit the session, expiring all ORM
        # attributes. Re-read by lead_id instead of refresh to avoid loading
        # partial state if an internal commit failed (audit §4.3).
        _result = await db.execute(select(Lead).where(Lead.id == lead_id))
        lead = _result.scalar_one_or_none()
        if lead is None:
            logger.error("lead_not_found_after_orchestrate", lead_id=str(lead_id))
            lead_id_str = str(lead_id)
            # Skip briefing update but still send the reply
            interacao = await lead_service.save_interacao(
                db, lead_id, msg_cliente=text, msg_ia=reply, tipo=tipo,
            )
            if text and reply:
                _memory.save_context({"input": text}, {"output": reply})
            await whatsapp_service.send_message(phone, reply)
            return

        lead_id_str = str(lead_id)

        try:
            # ── Step 5: Lê briefing atualizado pelo orquestrador ──────────
            # O orquestrador já persiste campos via persist_lead_data tool.
            # Buscar direto do DB evita a race condition que existia quando
            # ai_service.extract_briefing re-escrevia campos que o orquestrador
            # acabara de salvar com valores divergentes (Zona C).
            from app.infrastructure.persistence.repositories.briefing_repository import (
                BriefingRepository,
            )
            briefing = await BriefingRepository(db).get_by_lead_id(lead_id)

            if briefing:
                # ── Step 6: Enfileira notificação FCM se lead qualificar ──
                if briefing.completude_pct >= 60 and lead.status == LeadStatus.qualificado:
                    await _enqueue_qualified_notification(db, lead, briefing)

                    from app.services.kafka_producer import produce as _kafka_produce
                    from datetime import datetime, timezone as _tz
                    await _kafka_produce(
                        topic="leads.qualified",
                        key=str(lead_id),
                        value={
                            "lead_id": str(lead_id),
                            "phone": phone,
                            "completude_pct": briefing.completude_pct,
                            "destino": briefing.destino,
                            "timestamp": datetime.now(_tz.utc).isoformat(),
                        },
                    )

                # ── Step 6b: Oferta de curadoria quando recém-qualificado ─
                if curadoria_service.deve_oferecer_curadoria(
                    status_antes, lead.status, briefing.completude_pct
                ):
                    if not await curadoria_service.lead_tem_agendamento_ativo(db, lead.id):
                        # Só sobrescreve se o orquestrador NÃO já incluiu slots ou Meet link
                        import re as _re
                        # Detecta quando o orquestrador JÁ incluiu oferta/confirmação de
                        # agendamento na resposta. Padrões ordenados do mais específico ao
                        # mais geral para reduzir falsos positivos:
                        #   - meet.google.com → Meet link presente (confirmação real)
                        #   - agendar|agendamento → verbo/substantivo de ação de scheduling
                        #   - horários disponíveis → listagem de slots
                        #   - \d{1,2}h\d{2} → formato de hora (09h00) típico de slot
                        #   - \d{2}/\d{2}/\d{4} → data no formato BR típico de slot
                        # "agendado" sozinho (passado) não conta — evita falso positivo
                        # quando AYA menciona "já foi agendado" em outro contexto.
                        _reply_has_scheduling = bool(
                            _re.search(
                                r"meet\.google\.com"
                                r"|quer\s+agendar|vamos\s+agendar|posso\s+agendar"
                                r"|hor[aá]rios?\s+dispon[ií]veis"
                                r"|\bagendar\s+sua\s+curadoria\b"
                                r"|\bcuradoria\b.*\bagend"
                                r"|\d{1,2}h\d{2}.*\d{1,2}h\d{2}"
                                r"|\d{2}/\d{2}/\d{4}.*\d{1,2}h\d{2}"
                                # Slots numerados: "1. 15/05 às 09:00"
                                r"|[1-3]\.\s+\d{2}/\d{2}\s+[àa]s\s+\d{2}:\d{2}"
                                # Oferta explícita de horários de curadoria
                                r"|horários?\s+para\s+(?:a\s+)?curadoria"
                                r"|conversa\s+r[aá]pida.*\d{2}\s*minutos",
                                reply,
                                _re.IGNORECASE | _re.DOTALL,
                            )
                        )
                        if not _reply_has_scheduling:
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
                                "curadoria_skipped_orchestrator_already_offered",
                                lead_id=lead_id_str,
                            )
                    else:
                        logger.info(
                            "curadoria_skipped_already_scheduled",
                            lead_id=lead_id_str,
                        )
        except Exception as exc:
            try:
                await db.rollback()
            except Exception:
                pass
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

    # ── Step 7: Atualiza buffer de memória com a interação recém-concluída ──
    # Mantém o buffer crescendo corretamente no fluxo do orquestrador
    # (process_message não é chamado nesse path). Se o buffer transbordar,
    # compress_pending gera o summary e persiste no Redis automaticamente.
    if text and reply:
        _memory.save_context({"input": text}, {"output": reply})
        if _memory.has_pending_summary():
            await _memory.compress_pending(ai_service.get_llm())

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


async def execute_with_new_session(payload: dict) -> None:
    """Entry point for BackgroundTask: creates an isolated DB session per invocation.

    Avoids passing the FastAPI request-scoped AsyncSession to a BackgroundTask,
    which can expire mid-flight and cause silent failures (audit §7.1).

    Also serializes processing per wa_id via a Redis distributed lock (audit §8)
    to prevent race conditions when a client sends multiple messages in rapid succession.
    Falls back to unguarded execution if Redis is unavailable (degraded mode).
    """
    from app.infrastructure.persistence.database import AsyncSessionLocal

    wa_id: str = "unknown"
    try:
        extracted = whatsapp_service.extract_message_from_payload(payload)
        if extracted:
            wa_id = extracted["phone"]
    except Exception:
        pass

    lock_acquired = False
    redis_lock = None
    try:
        from app.infrastructure.cache.redis_client import get_redis
        redis = get_redis()
        redis_lock = redis.lock(
            f"lock:wa:{wa_id}",
            timeout=60,        # auto-release after 60s even if worker crashes
            blocking_timeout=120,  # wait up to 2 min for a queued message to get the lock
        )
        lock_acquired = await redis_lock.acquire()
    except Exception as exc:
        logger.warning(
            "whatsapp_redis_lock_unavailable",
            wa_id=wa_id,
            error=str(exc),
            fallback="processing_without_lock",
        )

    try:
        async with AsyncSessionLocal() as db:
            await execute(payload, db)
    except Exception as exc:
        logger.error(
            "execute_whatsapp_message_unhandled_error",
            wa_id=wa_id,
            error=str(exc),
            error_type=type(exc).__name__,
        )
        # Tenta enviar fallback ao cliente mesmo após falha crítica
        try:
            from app.services.whatsapp_service import send_message as _send
            await _send(wa_id, (
                "Recebi sua mensagem! Tivemos uma instabilidade momentânea. "
                "Um consultor da Cadife Tour irá te atender em breve. 😊"
            ))
        except Exception:
            pass
    finally:
        if lock_acquired and redis_lock is not None:
            try:
                await redis_lock.release()
            except Exception:
                pass


async def _enqueue_qualified_notification(
    db: AsyncSession, lead: Lead, briefing
) -> None:
    """Enqueue FCM push notification for the assigned consultant (or all, if unassigned)."""
    from sqlalchemy import select

    if lead.consultor_id:
        # Lead atribuído: notifica apenas o consultor responsável
        result = await db.execute(
            select(User).where(
                User.id == lead.consultor_id,
                User.fcm_token.isnot(None),
            )
        )
        consultor = result.scalar_one_or_none()
        tokens = [consultor.fcm_token] if consultor and consultor.fcm_token else []
        if not tokens:
            logger.warning(
                "assigned_consultant_has_no_fcm_token",
                lead_id=str(lead.id),
                consultor_id=str(lead.consultor_id),
            )
            return
    else:
        # Lead sem consultor: broadcast para todos os consultores da agência
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
