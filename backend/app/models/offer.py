import uuid
from app.infrastructure.persistence.types import GUID
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING, Optional, List, Dict

from sqlalchemy import (
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    func,
    JSON,
)
from sqlalchemy.dialects.postgresql import ENUM as PgEnum, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.domain.entities.enums import OfferStatus

if TYPE_CHECKING:
    from app.models.user import User


class Offer(Base):
    """Travel offer / showcase entity (vitrine digital da Cadife Tour)."""

    __tablename__ = "offers"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    agency_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("users.id"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    destination: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    destination_image_url: Mapped[Optional[str]] = mapped_column(String(500))
    
    # Datas
    departure_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    return_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    booking_deadline: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    
    # Detalhes da viagem
    duration_days: Mapped[int] = mapped_column(Integer, nullable=False)
    accommodations: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    included_services: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    travelers: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    available_spots: Mapped[int] = mapped_column(Integer, nullable=False)
    spots_reserved: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    
    # Preço
    base_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="BRL")
    discounts: Mapped[Optional[dict]] = mapped_column(JSON)
    final_price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    
    # SEO/Marketing
    highlights: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    amenities: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    
    # Status
    status: Mapped[OfferStatus] = mapped_column(
        PgEnum(OfferStatus, name="offer_status_enum", create_type=False),
        nullable=False,
        default=OfferStatus.draft,
        index=True,
    )
    views: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    interests: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    conversions: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    
    # Metadata
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
    published_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), index=True)
    
    is_deleted: Mapped[bool] = mapped_column(
        default=False, nullable=False, server_default="false"
    )

    agency: Mapped["User"] = relationship("User", foreign_keys=[agency_id])
