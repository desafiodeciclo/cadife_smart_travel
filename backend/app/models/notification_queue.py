import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.database import Base


class NotificationQueue(Base):
    """
    Fila de notificações push pendentes para leads qualificados.
    Processada pelo NotificationWorker em background com backoff exponencial.
    """
    __tablename__ = "notification_queue"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("leads.id"), nullable=False, index=True
    )
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="pending", index=True
    )
    # retry politics
    retry_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    max_retries: Mapped[int] = mapped_column(Integer, nullable=False, default=3)
    retry_delay_seconds: Mapped[int] = mapped_column(Integer, nullable=False, default=60)
    next_retry_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True
    )
    # payload para FCM
    payload: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)
    error_log: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    def compute_next_retry(self) -> datetime:
        """Calcula próximo retry com backoff exponencial: delay * 2^(retry_count-1)."""
        import datetime as dt

        # retry_count already incremented; use retry_count-1 for 0-indexed backoff
        backoff_multiplier = max(0, self.retry_count - 1)
        delay = self.retry_delay_seconds * (2 ** backoff_multiplier)
        return datetime.now(dt.timezone.utc) + dt.timedelta(seconds=delay)
