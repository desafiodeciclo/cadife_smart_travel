import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, Text, func
from sqlalchemy import JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.database import Base


class DeadLetterQueue(Base):
    """
    Dead Letter Queue para mensagens que esgotaram tentativas de processamento.
    Preserva payload original, rastro de erro e ciclo de vida de resolução.
    """

    __tablename__ = "dead_letter_queue"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("leads.id"), nullable=False, index=True
    )
    original_payload: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    error_trace: Mapped[str] = mapped_column(Text, nullable=False)
    retry_count_exhausted: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0
    )
    failed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    # Retry scheduling fields
    tentativas: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    proximo_retry: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True
    )
    # Resolution tracking fields (audit §5.2)
    resolvido: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, index=True)
    resolvido_por: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=True
    )
    resolvido_em: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
