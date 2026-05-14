import uuid
from app.infrastructure.persistence.types import GUID
from datetime import datetime
from typing import Optional

from sqlalchemy import (
    DateTime,
    ForeignKey,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class LeadOffer(Base):
    """Tracking table for client interest in offers."""

    __tablename__ = "lead_offers"

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    offer_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("offers.id", ondelete="CASCADE"), nullable=False
    )
    client_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("leads.id", ondelete="CASCADE"), nullable=False
    )
    agency_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    __table_args__ = (
        UniqueConstraint("offer_id", "client_id", name="uq_offer_client_interest"),
    )
