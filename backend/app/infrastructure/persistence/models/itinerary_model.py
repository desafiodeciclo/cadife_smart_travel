"""
ItineraryItemModel ORM Table — Infrastructure/Persistence Layer
===============================================================
Represents a single step of a trip itinerary populated by the consultant
after the alignment meeting (agendamento realizado).

API contract: GET /leads/{lead_id}/itinerary
Response field mapping (DB column → JSON key):
  horario_inicio  → horarioInicio
  horario_fim     → horarioFim  (nullable)
  tipo            → tipo  (ItineraryItemType string values)
"""

import uuid
from app.infrastructure.persistence.types import GUID
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import DateTime, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import ENUM as SAEnum, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.domain.entities.enums import ItineraryItemType
from app.infrastructure.persistence.database import Base

if TYPE_CHECKING:
    from app.infrastructure.persistence.models.lead_model import LeadModel
    from app.infrastructure.persistence.models.user_model import UserModel


itinerary_item_type_enum = SAEnum(
    *[e.value for e in ItineraryItemType],
    name="itinerary_item_type_enum",
    create_type=True,
)


class ItineraryItemModel(Base):
    """
    A single step in a lead's curated trip itinerary.
    Created by the consultant after the alignment meeting.
    One lead can have many ordered itinerary items.
    """

    __tablename__ = "itinerary_items"

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )

    lead_id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        ForeignKey("leads.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # Consultant who created this item
    criado_por: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=False,
        index=True,
    )

    tipo: Mapped[str] = mapped_column(
        itinerary_item_type_enum,
        nullable=False,
        default=ItineraryItemType.evento_customizado.value,
    )

    titulo: Mapped[str] = mapped_column(String(255), nullable=False)
    descricao: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Location fields (match Flutter entity: local + endereco)
    local: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    endereco: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)

    # Temporal bounds — serialised as horarioInicio / horarioFim in JSON
    horario_inicio: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    horario_fim: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Free-text notes from the consultant (e.g. baggage allowance, dress code)
    notas: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    atualizado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    lead: Mapped["LeadModel"] = relationship(
        "LeadModel", back_populates="itinerary_items", lazy="select"
    )
    consultor: Mapped["UserModel"] = relationship(
        "UserModel", foreign_keys=[criado_por], lazy="select"
    )
