"""
Notification Worker — Background Job
======================================
Processa a fila de notificações push (NotificationQueue) aplicando:
  - Backoff exponencial entre tentativas
  - Retry limitado por max_retries
  - Movimentação para Dead Letter Queue (DLQ) ao exaurir retries

Gatilho:
  - Executado pelo AsyncIOScheduler a cada 15 segundos (main.py lifespan)
  - Reage a jobs com status 'pending' ou 'failed' cujo next_retry_at <= agora
"""
from __future__ import annotations

import datetime as dt
from typing import Optional

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.persistence.database import AsyncSessionLocal
from app.models.notification_queue import NotificationQueue
from app.services import fcm_service
from app.services.notification_queue_service import NotificationQueueService

logger = structlog.get_logger()

# Intervalo entre execuções do worker (segundos)
WORKER_INTERVAL_SECONDS = 15


class NotificationWorker:
    """
    Background worker that drains the notification queue and dispatches FCM pushes.
    """

    def __init__(self, queue_service: NotificationQueueService | None = None) -> None:
        self._queue_service = queue_service or NotificationQueueService()

    async def run(self) -> None:
        """
        Entry point chamado pelo scheduler.
        Abre uma sessão DB, busca jobs elegíveis e processa.
        """
        async with AsyncSessionLocal() as db:
            jobs = await self._fetch_eligible_jobs(db)
            if not jobs:
                return

            logger.info("notification_worker_started", jobs_count=len(jobs))
            for job in jobs:
                await self._process_job(db, job)

    async def _fetch_eligible_jobs(self, db: AsyncSession) -> list[NotificationQueue]:
        """
        Retorna jobs elegíveis para processamento:
          - status == 'pending' e next_retry_at IS NULL (nunca tentados)
          - status == 'failed' e next_retry_at <= NOW()
        """
        now = dt.datetime.now(dt.timezone.utc)
        stmt = (
            select(NotificationQueue)
            .where(
                (
                    (NotificationQueue.status == "pending")
                    & (NotificationQueue.next_retry_at.is_(None))
                )
                | (
                    (NotificationQueue.status == "failed")
                    & (NotificationQueue.next_retry_at <= now)
                )
            )
            .order_by(NotificationQueue.created_at.asc())
            .limit(50)
        )
        result = await db.execute(stmt)
        return list(result.scalars().all())

    async def _process_job(self, db: AsyncSession, job: NotificationQueue) -> None:
        """
        Processa um único job: envia FCM e atualiza estado ou move para DLQ.
        """
        job.status = "processing"
        await db.commit()

        try:
            success = await self._dispatch_fcm(job)
        except Exception as exc:
            logger.error(
                "notification_dispatch_exception",
                job_id=str(job.id),
                lead_id=str(job.lead_id),
                error=str(exc),
            )
            success = False

        if success:
            job.status = "completed"
            job.error_log = None
            await db.commit()
            logger.info(
                "notification_completed",
                job_id=str(job.id),
                lead_id=str(job.lead_id),
            )
            return

        # Falha — aplicar retry ou DLQ
        job.retry_count += 1
        if job.retry_count >= job.max_retries:
            error_trace = job.error_log or "Max retries exceeded without explicit error log"
            await self._queue_service.move_to_dead_letter(db, job, error_trace)
            return

        # Backoff exponencial: delay * 2^retry_count
        job.status = "failed"
        job.next_retry_at = job.compute_next_retry()
        if not job.error_log:
            job.error_log = f"Retry {job.retry_count}/{job.max_retries}"
        await db.commit()

        logger.warning(
            "notification_retry_scheduled",
            job_id=str(job.id),
            lead_id=str(job.lead_id),
            retry_count=job.retry_count,
            max_retries=job.max_retries,
            next_retry_at=job.next_retry_at.isoformat(),
        )

    async def _dispatch_fcm(self, job: NotificationQueue) -> bool:
        """
        Envia notificação FCM para todos os tokens do payload.
        Retorna True apenas se TODOS os envios forem bem-sucedidos.
        """
        payload = job.payload
        tokens: list[str] = payload.get("fcm_tokens", [])
        title: str = payload.get("title", "Cadife Smart Travel")
        body: str = payload.get("body", "")
        data: dict = payload.get("data", {})

        if not tokens:
            logger.warning("notification_no_tokens", job_id=str(job.id), lead_id=str(job.lead_id))
            job.error_log = "No FCM tokens available"
            return False

        all_success = True
        errors: list[str] = []

        for token in tokens:
            try:
                ok = await fcm_service.send_push_notification(
                    fcm_token=token,
                    title=title,
                    body=body,
                    data=data,
                )
                if not ok:
                    all_success = False
                    errors.append(f"token_{token[:8]}..._failed")
            except Exception as exc:
                all_success = False
                errors.append(f"token_{token[:8]}..._exc:{str(exc)}")

        if not all_success:
            job.error_log = "; ".join(errors)

        return all_success
