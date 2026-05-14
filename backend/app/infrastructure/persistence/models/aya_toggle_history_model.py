"""
AyaToggleHistory ORM Model — Infrastructure/Persistence Layer
=============================================================
Audit table for every AYA on/off toggle action.
Each row records who toggled, to which state, with what reason, and when.
"""

import uuid
from app.infrastructure.persistence.types import GUID
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import DateTime, ForeignKey, Text, Boolean, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.persistence.database import Base

if TYPE_CHECKING:
    from app.infrastructure.persistence.models.lead_model import LeadModel


class AyaToggleHistoryModel(Base):
    __tablename__ = "aya_toggle_history"

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        ForeignKey("leads.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    ativo: Mapped[bool] = mapped_column(Boolean, nullable=False)
    motivo: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    alterado_por: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    alterado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    lead: Mapped["LeadModel"] = relationship("LeadModel", back_populates="aya_toggle_history")
