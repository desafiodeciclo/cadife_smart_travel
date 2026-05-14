"""
WhatsApp Kafka Consumer — Workers Layer
========================================
Consome mensagens do tópico `whatsapp.messages.incoming` e delega para o
use case `process_whatsapp_message.execute()`.

Características:
  - Commit manual (enable_auto_commit=False): mensagem só é commitada após
    processamento bem-sucedido, garantindo at-least-once delivery.
  - Retry tracking em memória: após MAX_RETRIES falhas consecutivas para o
    mesmo offset, a mensagem é enviada ao tópico `whatsapp.messages.dlq`
    (Dead Letter Queue Kafka) e o offset é commitado — evita bloqueio infinito
    da partição por mensagens irrecuperáveis (poison pills).
  - Group ID fixo: múltiplas réplicas do worker compartilham a carga
    automaticamente via particionamento Kafka.
  - Graceful shutdown via asyncio.Event.

Execução:
    python -m app.application.workers.whatsapp_consumer

Em desenvolvimento (KAFKA_ENABLED=False) o worker não inicializa (avisa e sai).
"""

from __future__ import annotations

import asyncio
import json
import signal
from collections import defaultdict

import structlog

logger = structlog.get_logger()

_TOPIC = "whatsapp.messages.incoming"
_GROUP_ID = "whatsapp-processor"
MAX_RETRIES = 3  # tentativas antes de mover para DLQ


async def _send_to_dlq(producer, phone: str, raw_value: dict, error: str) -> None:
    """Publica a mensagem irrecuperável no tópico DLQ via producer existente."""
    from datetime import datetime, timezone
    from app.services.kafka_producer import TOPICS

    try:
        dlq_payload = {
            "original_payload": raw_value,
            "phone": phone,
            "error": error,
            "failed_at": datetime.now(timezone.utc).isoformat(),
        }
        await producer.send_and_wait(
            TOPICS.WHATSAPP_DLQ,
            key=phone.encode(),
            value=json.dumps(dlq_payload, default=str).encode(),
        )
        logger.warning(
            "whatsapp_message_sent_to_dlq",
            phone=phone,
            error=error[:200],
        )
    except Exception as dlq_exc:
        logger.error("whatsapp_dlq_publish_failed", phone=phone, error=str(dlq_exc))


async def _run(stop_event: asyncio.Event) -> None:
    from app.infrastructure.config.settings import get_settings

    settings = get_settings()

    if not settings.KAFKA_ENABLED:
        logger.warning("whatsapp_consumer_disabled", reason="KAFKA_ENABLED=False")
        return

    from aiokafka import AIOKafkaConsumer, AIOKafkaProducer  # type: ignore[import]
    from app.core.dependencies import get_db_session
    from app.application.use_cases import process_whatsapp_message

    consumer = AIOKafkaConsumer(
        _TOPIC,
        bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
        group_id=_GROUP_ID,
        auto_offset_reset="earliest",
        enable_auto_commit=False,
        value_deserializer=lambda v: json.loads(v.decode()),
    )

    # Producer dedicado ao worker para publicar no DLQ sem depender do singleton
    dlq_producer = AIOKafkaProducer(
        bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
        acks="all",
    )

    await consumer.start()
    await dlq_producer.start()
    logger.info("whatsapp_consumer_started", topic=_TOPIC, group=_GROUP_ID)

    # Rastreia falhas consecutivas por (partition, offset) para evitar loops infinitos
    _failure_counts: dict[tuple[int, int], int] = defaultdict(int)

    try:
        async for msg in consumer:
            if stop_event.is_set():
                break

            phone = msg.key.decode() if msg.key else "unknown"
            msg_key = (msg.partition, msg.offset)

            try:
                payload = msg.value.get("payload", msg.value)
                async with get_db_session() as db:
                    await process_whatsapp_message.execute(payload, db)

                # Processa com sucesso: limpa contador e commita
                _failure_counts.pop(msg_key, None)
                await consumer.commit()
                logger.info(
                    "whatsapp_message_processed",
                    phone=phone,
                    offset=msg.offset,
                    partition=msg.partition,
                )
            except Exception as exc:
                _failure_counts[msg_key] += 1
                attempt = _failure_counts[msg_key]

                if attempt >= MAX_RETRIES:
                    # Poison pill: envia para DLQ e commita para não bloquear a partição
                    logger.error(
                        "whatsapp_message_max_retries_exceeded",
                        phone=phone,
                        offset=msg.offset,
                        partition=msg.partition,
                        attempts=attempt,
                        error=str(exc),
                    )
                    await _send_to_dlq(dlq_producer, phone, msg.value, str(exc))
                    _failure_counts.pop(msg_key, None)
                    await consumer.commit()
                else:
                    logger.warning(
                        "whatsapp_message_processing_failed",
                        phone=phone,
                        offset=msg.offset,
                        attempt=attempt,
                        max_retries=MAX_RETRIES,
                        error=str(exc),
                        error_type=type(exc).__name__,
                    )
    finally:
        await dlq_producer.stop()
        await consumer.stop()
        logger.info("whatsapp_consumer_stopped")


async def main() -> None:
    stop_event = asyncio.Event()

    def _handle_signal(*_):
        logger.info("shutdown_signal_received")
        stop_event.set()

    loop = asyncio.get_running_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, _handle_signal)

    await _run(stop_event)


if __name__ == "__main__":
    asyncio.run(main())
