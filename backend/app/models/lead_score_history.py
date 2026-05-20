"""
LeadScoreHistory ORM Model
==========================
Auditoria imutável de cada recálculo do score de qualificação.
Uma linha é inserida a cada chamada ao LeadScoringService, jamais atualizada.
"""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.models.lead import Lead


class LeadScoreHistory(Base):
    __tablename__ = "lead_score_history"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("leads.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    score_numerico: Mapped[int] = mapped_column(Integer, nullable=False)
    score_label: Mapped[str] = mapped_column(String(10), nullable=False)
    motivo: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    criterios_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    lead: Mapped["Lead"] = relationship("Lead", back_populates="score_history", overlaps="lead,score_history")
