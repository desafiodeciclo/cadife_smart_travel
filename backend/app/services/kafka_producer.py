"""
Kafka Producer — Services Layer
================================
Produtor assíncrono singleton para publicar eventos de negócio nos tópicos Kafka.

Tópicos produzidos:
  whatsapp.messages.incoming   — payload bruto recebido do webhook Meta
  whatsapp.messages.dlq        — mensagens que esgotaram tentativas no consumer
  leads.qualified              — lead atingiu completude >= 60 %
  leads.orchestrator.errors    — falha crítica no LangGraph orchestrator
  agendamentos.confirmados     — agendamento de curadoria criado e Meet link gerado

Uso:
    from app.services.kafka_producer import produce, TOPICS
    await produce(TOPICS.LEADS_QUALIFIED, key=str(lead_id), value={...})

Em desenvolvimento (KAFKA_ENABLED=False) todas as chamadas são no-op silenciosos.
"""

from __future__ import annotations

import json
from typing import Any

import structlog

logger = structlog.get_logger()

_producer = None  # AIOKafkaProducer singleton


class TOPICS:
    """Constantes de nomes de tópicos — evita typos espalhados pelo codebase."""

    WHATSAPP_INCOMING = "whatsapp.messages.incoming"
    WHATSAPP_DLQ = "whatsapp.messages.dlq"
    LEADS_QUALIFIED = "leads.qualified"
    LEADS_ORCHESTRATOR_ERRORS = "leads.orchestrator.errors"
    AGENDAMENTOS_CONFIRMADOS = "agendamentos.confirmados"


async def _get_producer():
    global _producer
    if _producer is not None:
        return _producer

    try:
        from aiokafka import AIOKafkaProducer  # type: ignore[import]
        from app.infrastructure.config.settings import get_settings

        settings = get_settings()
        _producer = AIOKafkaProducer(
            bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
            value_serializer=lambda v: json.dumps(v, default=str).encode(),
            key_serializer=lambda k: k.encode() if k else None,
            acks="all",
            enable_idempotence=True,
            request_timeout_ms=10_000,
            retry_backoff_ms=200,
        )
        await _producer.start()
        logger.info(
            "kafka_producer_started",
            brokers=settings.KAFKA_BOOTSTRAP_SERVERS,
        )
    except Exception as exc:
        logger.error("kafka_producer_start_failed", error=str(exc))
        _producer = None
        raise

    return _producer


async def produce(topic: str, key: str, value: dict[str, Any]) -> None:
    """Publica uma mensagem no tópico Kafka de forma assíncrona.

    Não-operacional quando KAFKA_ENABLED=False (não levanta exceção).
    """
    from app.infrastructure.config.settings import get_settings

    if not get_settings().KAFKA_ENABLED:
        return

    try:
        producer = await _get_producer()
        await producer.send_and_wait(topic, key=key, value=value)
        logger.info("kafka_message_produced", topic=topic, key=key[:20])
    except Exception as exc:
        # Kafka nunca deve derrubar o fluxo principal — loga e segue
        logger.error("kafka_produce_failed", topic=topic, key=key[:20], error=str(exc))


async def close_producer() -> None:
    """Para o producer graciosamente. Chamar no shutdown da aplicação."""
    global _producer
    if _producer is not None:
        try:
            await _producer.stop()
            logger.info("kafka_producer_stopped")
        except Exception as exc:
            logger.warning("kafka_producer_stop_error", error=str(exc))
        finally:
            _producer = None
