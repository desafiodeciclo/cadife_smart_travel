"""
Agendamento Kafka Consumer — Workers Layer
==========================================
Consome eventos do tópico `agendamentos.confirmados` e executa ações downstream:
  1. Envia notificação FCM push para todos os consultores com token registrado,
     incluindo o link Google Meet no payload para acesso imediato.
  2. Registra métricas de observabilidade (lead_id, hora, meet_link).

O consumidor usa commit manual (enable_auto_commit=False) para garantia
at-least-once delivery: o evento só é marcado como processado após sucesso
do envio FCM; falhas transientes deixam o offset não commitado e o evento
será reprocessado no próximo restart do worker.

Execução standalone:
    python -m app.application.workers.agendamento_consumer

Em desenvolvimento (KAFKA_ENABLED=False) o worker não inicializa (avisa e sai).
"""

from __future__ import annotations

import asyncio
import json
import signal

import structlog

logger = structlog.get_logger()

_TOPIC = "agendamentos.confirmados"
_GROUP_ID = "agendamento-notifier"


async def _notify_consultores(event: dict) -> None:
    """Envia FCM push para todos os consultores sobre o agendamento confirmado."""
    from sqlalchemy import select
    from app.core.dependencies import get_db_session
    from app.infrastructure.persistence.models.user_model import UserModel
    from app.services.fcm_service import send_multicast

    lead_nome = event.get("lead_nome") or "Cliente"
    data = event.get("data", "")
    hora = event.get("hora", "")
    meet_link = event.get("meet_link") or ""
    lead_id = event.get("lead_id", "")

    async with get_db_session() as db:
        result = await db.execute(
            select(UserModel).where(
                UserModel.perfil == "agencia",
                UserModel.fcm_token.isnot(None),
            )
        )
        consultores = result.scalars().all()
        tokens = [c.fcm_token for c in consultores if c.fcm_token]

    if not tokens:
        logger.warning(
            "agendamento_notifier_no_tokens",
            lead_id=lead_id,
            reason="no_consultant_fcm_tokens",
        )
        return

    title = "📅 Nova Curadoria Confirmada"
    body = f"{lead_nome} agendou para {data} às {hora}"
    data_payload: dict = {
        "type": "agendamento_confirmado",
        "lead_id": lead_id,
        "data": data,
        "hora": hora,
        "meet_link": meet_link,
    }

    await send_multicast(tokens=tokens, title=title, body=body, data=data_payload)
    logger.info(
        "agendamento_fcm_dispatched",
        lead_id=lead_id,
        tokens_count=len(tokens),
        meet_link=bool(meet_link),
    )


async def _run(stop_event: asyncio.Event) -> None:
    from app.infrastructure.config.settings import get_settings

    settings = get_settings()

    if not settings.KAFKA_ENABLED:
        logger.warning("agendamento_consumer_disabled", reason="KAFKA_ENABLED=False")
        return

    from aiokafka import AIOKafkaConsumer  # type: ignore[import]

    consumer = AIOKafkaConsumer(
        _TOPIC,
        bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
        group_id=_GROUP_ID,
        auto_offset_reset="earliest",
        enable_auto_commit=False,
        value_deserializer=lambda v: json.loads(v.decode()),
    )
    await consumer.start()
    logger.info("agendamento_consumer_started", topic=_TOPIC, group=_GROUP_ID)

    try:
        async for msg in consumer:
            if stop_event.is_set():
                break

            lead_id = msg.key.decode() if msg.key else "unknown"
            try:
                event: dict = msg.value
                await _notify_consultores(event)
                await consumer.commit()
                logger.info(
                    "agendamento_event_processed",
                    lead_id=lead_id,
                    offset=msg.offset,
                    partition=msg.partition,
                )
            except Exception as exc:
                # Não commita — evento será reprocessado no próximo restart
                logger.error(
                    "agendamento_event_processing_failed",
                    lead_id=lead_id,
                    offset=msg.offset,
                    error=str(exc),
                    error_type=type(exc).__name__,
                )
    finally:
        await consumer.stop()
        logger.info("agendamento_consumer_stopped")


async def main() -> None:
    stop_event = asyncio.Event()

    def _handle_signal(*_):
        logger.info("agendamento_consumer_shutdown_signal")
        stop_event.set()

    loop = asyncio.get_running_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, _handle_signal)

    await _run(stop_event)


if __name__ == "__main__":
    asyncio.run(main())
