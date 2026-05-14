"""
LeadScoreHistory ORM Model — Infrastructure/Persistence Layer
===============================================================
Auditoria imutável de cada recálculo do score de qualificação.
Espelha app/models/lead_score_history.py para manter consistência
com LeadModel nesta camada.
"""

import uuid
from app.infrastructure.persistence.types import GUID
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.persistence.database import Base

if TYPE_CHECKING:
    from app.infrastructure.persistence.models.lead_model import LeadModel


class LeadScoreHistoryModel(Base):
    __tablename__ = "lead_score_history"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
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

    lead: Mapped["LeadModel"] = relationship("LeadModel", back_populates="score_history")
