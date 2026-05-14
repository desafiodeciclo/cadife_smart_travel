"""
DLQ Retry Worker — Workers Layer
==================================
Polling worker que reprocessa entradas da `dead_letter_queue` do PostgreSQL
cujo `proximo_retry` seja passado e `resolvido = FALSE`.

Estratégia de backoff exponencial:
  tentativa 1 → retry em  5 min
  tentativa 2 → retry em 15 min
  tentativa 3 → retry em 60 min
  tentativa 4+ → marca resolvido=TRUE com error_trace atualizado (poison pill permanente)

Execução standalone:
    python -m app.application.workers.dlq_retry_worker

Em desenvolvimento (KAFKA_ENABLED=False) o worker ainda roda — a DLQ do
PostgreSQL pode ter entradas mesmo sem Kafka (modo BackgroundTasks).
"""

from __future__ import annotations

import asyncio
import signal
from datetime import datetime, timedelta, timezone

import structlog

logger = structlog.get_logger()

_POLL_INTERVAL_S = 60
_MAX_ATTEMPTS = 4
_BACKOFF_MINUTES = [5, 15, 60]  # índice = tentativa-1; após MAX_ATTEMPTS: poison pill


def _next_retry_at(tentativas: int) -> datetime | None:
    """Retorna o próximo timestamp de retry ou None quando excede o limite."""
    if tentativas >= _MAX_ATTEMPTS:
        return None
    idx = min(tentativas, len(_BACKOFF_MINUTES) - 1)
    return datetime.now(timezone.utc) + timedelta(minutes=_BACKOFF_MINUTES[idx])


async def _process_due_entries() -> None:
    from sqlalchemy import select, update
    from app.core.dependencies import get_db_session
    from app.models.dead_letter_queue import DeadLetterQueue
    from app.application.use_cases import process_whatsapp_message
    from app.models.lead import Lead

    now = datetime.now(timezone.utc)

    async with get_db_session() as db:
        result = await db.execute(
            select(DeadLetterQueue)
            .where(
                DeadLetterQueue.resolvido.is_(False),
                DeadLetterQueue.proximo_retry <= now,
            )
            .limit(50)
            .with_for_update(skip_locked=True)
        )
        entries = result.scalars().all()

    if not entries:
        return

    logger.info("dlq_retry_batch", count=len(entries))

    for entry in entries:
        async with get_db_session() as db:
            # Re-fetch with lock inside own session
            refreshed = await db.get(DeadLetterQueue, entry.id)
            if refreshed is None or refreshed.resolvido:
                continue

            phone_result = await db.execute(
                select(Lead.telefone).where(Lead.id == refreshed.lead_id).limit(1)
            )
            phone = phone_result.scalar_one_or_none() or "unknown"

            try:
                await process_whatsapp_message.execute_with_new_session(
                    refreshed.original_payload.get("payload", refreshed.original_payload)
                )
                # Success: mark as resolved
                refreshed.resolvido = True
                refreshed.resolvido_em = datetime.now(timezone.utc)
                refreshed.proximo_retry = None
                await db.commit()
                logger.info(
                    "dlq_entry_resolved",
                    dlq_id=str(refreshed.id),
                    phone=phone,
                    tentativas=refreshed.tentativas + 1,
                )
            except Exception as exc:
                new_tentativas = refreshed.tentativas + 1
                next_retry = _next_retry_at(new_tentativas)

                if next_retry is None:
                    # Poison pill — give up, mark resolved with error note
                    refreshed.resolvido = True
                    refreshed.resolvido_em = datetime.now(timezone.utc)
                    refreshed.error_trace = (
                        f"[GAVE_UP after {new_tentativas} attempts] {str(exc)[:1000]}"
                    )
                    logger.error(
                        "dlq_entry_gave_up",
                        dlq_id=str(refreshed.id),
                        phone=phone,
                        attempts=new_tentativas,
                        error=str(exc)[:200],
                    )
                else:
                    refreshed.tentativas = new_tentativas
                    refreshed.proximo_retry = next_retry
                    logger.warning(
                        "dlq_entry_rescheduled",
                        dlq_id=str(refreshed.id),
                        phone=phone,
                        attempt=new_tentativas,
                        next_retry=next_retry.isoformat(),
                        error=str(exc)[:200],
                    )

                await db.commit()


async def _run(stop_event: asyncio.Event) -> None:
    logger.info("dlq_retry_worker_started", poll_interval_s=_POLL_INTERVAL_S)
    while not stop_event.is_set():
        try:
            await _process_due_entries()
        except Exception as exc:
            logger.error("dlq_retry_worker_error", error=str(exc))
        try:
            await asyncio.wait_for(stop_event.wait(), timeout=_POLL_INTERVAL_S)
        except asyncio.TimeoutError:
            pass
    logger.info("dlq_retry_worker_stopped")


async def main() -> None:
    stop_event = asyncio.Event()

    def _handle_signal(*_):
        logger.info("dlq_retry_worker_shutdown_signal")
        stop_event.set()

    loop = asyncio.get_running_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, _handle_signal)

    await _run(stop_event)


if __name__ == "__main__":
    asyncio.run(main())
