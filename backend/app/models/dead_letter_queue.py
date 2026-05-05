import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, Integer, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.database import Base


class DeadLetterQueue(Base):
    """
    Dead Letter Queue para notificações push que exauriram todas as tentativas.
    Preserva payload original e rastro de erro para análise posterior.
    """
    __tablename__ = "dead_letter_queue"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("leads.id"), nullable=False, index=True
    )
    original_payload: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)
    error_trace: Mapped[str] = mapped_column(Text, nullable=False)
    retry_count_exhausted: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    failed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
