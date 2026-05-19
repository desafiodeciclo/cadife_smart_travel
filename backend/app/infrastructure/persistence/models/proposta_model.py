"""
Proposta ORM Table — Infrastructure/Persistence Layer
======================================================
SQLAlchemy model for the 'propostas' table (spec.md §4.5).
Represents a travel proposal created for a lead.

Fields per spec §4.5:
  id, lead_id (FK), descricao, valor_estimado, status (enum), criado_em

Constraints:
  - valor_estimado: DB CHECK >= 0 when not null
  - status: native PostgreSQL ENUM
  - Index (lead_id, status): frequent query pattern for lead proposal view
"""

import uuid
from app.infrastructure.persistence.types import GUID
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING, Optional

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import ENUM as SAEnum, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.domain.entities.enums import PropostaStatus
from app.infrastructure.persistence.database import Base

if TYPE_CHECKING:
    from app.infrastructure.persistence.models.lead_model import LeadModel


proposta_status_enum = SAEnum(
    *[e.value for e in PropostaStatus],
    name="proposta_status_enum",
    create_type=True,
)


class PropostaModel(Base):
    """
    ORM representation of a travel proposal (spec.md §4.5).
    Created by the consultant after curation; sent to the client for approval.
    """

    __tablename__ = "propostas"

    __table_args__ = (
        # Composite index: lead detail page loads proposals filtered by status
        Index("ix_propostas_lead_status", "lead_id", "status"),
        # Composite index: consultant views all proposals by status
        Index("ix_propostas_consultor_status", "consultor_id", "status"),
        # Business rule: estimated value must be non-negative
        CheckConstraint(
            "valor_estimado IS NULL OR valor_estimado >= 0",
            name="ck_propostas_valor_positivo",
        ),
        {"extend_existing": True},
    )

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        ForeignKey("leads.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    descricao: Mapped[str] = mapped_column(Text, nullable=False)
    valor_estimado: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    status: Mapped[str] = mapped_column(
        proposta_status_enum,
        nullable=False,
        default=PropostaStatus.rascunho.value,
    )
    consultor_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(), ForeignKey("users.id", ondelete="SET NULL")
    )
    expiration_hours: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        server_default="48",
    )
    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    # gap §3.4 — sent / send-notification idempotency / soft-delete
    enviado_em: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    notificacao_enviada_em: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    deletado_em: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    deletado_por: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )

    lead: Mapped["LeadModel"] = relationship("LeadModel", back_populates="propostas")
