"""
ItineraryDailyNoteModel ORM Table — Infrastructure/Persistence Layer
=====================================================================
Notas diárias do itinerário de um lead, indexadas por data.
Upsert idempotente: uma nota por (lead_id, date).
"""

import uuid
from datetime import date, datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import Date, DateTime, ForeignKey, Text, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.persistence.database import Base

if TYPE_CHECKING:
    from app.infrastructure.persistence.models.lead_model import LeadModel


class ItineraryDailyNoteModel(Base):
    __tablename__ = "itinerary_daily_notes"

    __table_args__ = (
        UniqueConstraint("lead_id", "date", name="uq_itinerary_daily_notes_lead_date"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("leads.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    date: Mapped[date] = mapped_column(Date, nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    lead: Mapped["LeadModel"] = relationship("LeadModel", back_populates="daily_notes", lazy="select")
