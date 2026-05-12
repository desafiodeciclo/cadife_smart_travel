"""
TravelDiaryEntry ORM Table — Infrastructure/Persistence Layer
============================================================
SQLAlchemy mapped model for the 'travel_diary_entries' table.
Captures memories (photo + note) associated with a specific lead/trip.
"""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import (
    DateTime,
    ForeignKey,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.persistence.database import Base

if TYPE_CHECKING:
    from app.infrastructure.persistence.models.lead_model import LeadModel
    from app.infrastructure.persistence.models.user_model import UserModel


class TravelDiaryEntryModel(Base):
    """
    ORM representation of a travel diary entry (spec.md §3.3).
    Stores photo URLs and personal notes for a trip.
    """

    __tablename__ = "travel_diary_entries"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    
    # Association with a specific lead (trip)
    lead_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), 
        ForeignKey("leads.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    # Ownership - redundant but faster for GET /users/me/diary
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    # Media URLs
    foto_url: Mapped[str] = mapped_column(String(1024), nullable=False)
    thumb_url: Mapped[str] = mapped_column(String(1024), nullable=False)
    
    # Content
    nota: Mapped[Optional[str]] = mapped_column(String(280), nullable=True)
    
    # Temporal data
    data_entrada: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        nullable=False,
        server_default=func.now()
    )
    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        server_default=func.now(), 
        nullable=False
    )

    # Relationships
    lead: Mapped["LeadModel"] = relationship("LeadModel", back_populates="diary_entries", lazy="select")
    user: Mapped["UserModel"] = relationship("UserModel", lazy="select")
