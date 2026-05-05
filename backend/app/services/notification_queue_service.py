"""
Notification Queue Service — Application Layer
================================================
Orquestra o enfileiramento de notificações push para leads qualificados,
respeitando debounce e evitando duplicatas na fila.

Integração:
  - Chamado por process_whatsapp_message quando lead transita para QUALIFICADO
  - Usa NotificationDebounceService para throttle de 60s
  - Persiste job em notification_queue para processamento assíncrono pelo Worker
"""
from __future__ import annotations

import uuid
from typing import Optional

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.config.settings import get_settings
from app.models.dead_letter_queue import DeadLetterQueue
from app.models.notification_queue import NotificationQueue
from app.services.notification_debounce_service import NotificationDebounceService

logger = structlog.get_logger()
settings = get_settings()

# Configurações default de retry (podem vir do Settings futuramente)
DEFAULT_MAX_RETRIES = 3
DEFAULT_RETRY_DELAY_SECONDS = 60


class NotificationQueueService:
    """Service to enqueue and manage FCM notification jobs."""

    def __init__(self, debounce_service: NotificationDebounceService | None = None) -> None:
        self._debounce = debounce_service or NotificationDebounceService()

    async def enqueue_qualified_lead_notification(
        self,
        db: AsyncSession,
        lead_id: uuid.UUID,
        lead_nome: Optional[str],
        destino: Optional[str],
        fcm_tokens: list[str],
        max_retries: int = DEFAULT_MAX_RETRIES,
        retry_delay_seconds: int = DEFAULT_RETRY_DELAY_SECONDS,
    ) -> NotificationQueue | None:
        """
        Enfileira notificação de lead qualificado se debounce permitir.

        Args:
            db: sessão async do SQLAlchemy
            lead_id: UUID do lead
            lead_nome: nome do lead (para exibição na notificação)
            destino: destino desejado (para exibição na notificação)
            fcm_tokens: lista de tokens FCM dos consultores ativos
            max_retries: máximo de tentativas de envio
            retry_delay_seconds: delay base entre retries (backoff exponencial)

        Returns:
            NotificationQueue criado, ou None se debounce bloqueou.
        """
        lead_id_str = str(lead_id)

        if not await self._debounce.is_allowed(lead_id_str):
            logger.info(
                "notification_enqueue_blocked_by_debounce",
                lead_id=lead_id_str,
                reason="duplicate_within_debounce_window",
            )
            return None

        # Evita duplicata exata na fila (mesmo lead_id + status pending)
        existing = await db.execute(
            select(NotificationQueue).where(
                NotificationQueue.lead_id == lead_id,
                NotificationQueue.status.in_(["pending", "processing"]),
            )
        )
        if existing.scalar_one_or_none():
            logger.info(
                "notification_enqueue_blocked_by_existing_job",
                lead_id=lead_id_str,
                reason="pending_or_processing_job_exists",
            )
            return None

        payload = {
            "title": "Novo lead qualificado",
            "body": self._build_body(lead_nome, destino),
            "data": {"type": "new_lead", "lead_id": lead_id_str},
            "fcm_tokens": fcm_tokens,
        }

        job = NotificationQueue(
            lead_id=lead_id,
            status="pending",
            retry_count=0,
            max_retries=max_retries,
            retry_delay_seconds=retry_delay_seconds,
            next_retry_at=None,
            payload=payload,
        )
        db.add(job)
        await db.commit()
        await db.refresh(job)

        await self._debounce.touch(lead_id_str)

        logger.info(
            "notification_enqueued",
            job_id=str(job.id),
            lead_id=lead_id_str,
            fcm_tokens_count=len(fcm_tokens),
            max_retries=max_retries,
            retry_delay_seconds=retry_delay_seconds,
        )
        return job

    @staticmethod
    def _build_body(lead_nome: Optional[str], destino: Optional[str]) -> str:
        body = f"Lead: {lead_nome or 'Novo contato'}"
        if destino:
            body += f" — Destino: {destino}"
        return body

    async def move_to_dead_letter(
        self,
        db: AsyncSession,
        job: NotificationQueue,
        error_trace: str,
    ) -> DeadLetterQueue:
        """
        Move um job da fila ativa para a Dead Letter Queue após exaurir retries.
        """
        dlq_entry = DeadLetterQueue(
            lead_id=job.lead_id,
            original_payload=job.payload,
            error_trace=error_trace,
            retry_count_exhausted=job.retry_count,
        )
        db.add(dlq_entry)
        await db.delete(job)
        await db.commit()
        await db.refresh(dlq_entry)

        logger.warning(
            "notification_moved_to_dlq",
            dlq_id=str(dlq_entry.id),
            lead_id=str(job.lead_id),
            retry_count=job.retry_count,
            error_trace=error_trace[:200],
        )
        return dlq_entry
