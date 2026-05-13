"""
Agendamento ORM Table — Infrastructure/Persistence Layer
=========================================================
SQLAlchemy model for the 'agendamentos' table (spec.md §4.4).
Represents a curation appointment between a lead and a consultant.

Constraints:
  - (lead_id, data, hora) UNIQUE — one appointment per slot per lead
  - DB ENUM for status and tipo
"""

import uuid
from datetime import date, datetime, time
from typing import TYPE_CHECKING, Optional

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    String,
    Time,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import ENUM as SAEnum, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.domain.entities.enums import AgendamentoStatus, AgendamentoTipo, MotivoBloqueio
from app.infrastructure.persistence.database import Base

if TYPE_CHECKING:
    from app.infrastructure.persistence.models.lead_model import LeadModel


agendamento_status_enum = SAEnum(
    *[e.value for e in AgendamentoStatus],
    name="agendamento_status_enum",
    create_type=True,
)
agendamento_tipo_enum = SAEnum(
    *[e.value for e in AgendamentoTipo],
    name="agendamento_tipo_enum",
    create_type=True,
)
motivo_bloqueio_enum = SAEnum(
    *[e.value for e in MotivoBloqueio],
    name="motivo_bloqueio_enum",
    create_type=True,
)


class AgendamentoModel(Base):
    """
    ORM representation of a curation appointment (spec.md §4.4).
    """

    __tablename__ = "agendamentos"

    __table_args__ = (
        # Composite index: find appointments by lead + status
        Index("ix_agendamentos_lead_status", "lead_id", "status"),
        # Composite index: consultant schedule view
        Index("ix_agendamentos_consultor_data", "consultor_id", "data"),
        # Business rule: a lead cannot have duplicate slot bookings (only when lead_id IS NOT NULL)
        UniqueConstraint("lead_id", "data", "hora", name="uq_agendamento_lead_slot"),
        # Block-only constraints (gap §3.5.6): a 'bloqueio' must NOT have a lead_id and MUST have a motivo
        CheckConstraint(
            "(tipo <> 'bloqueio') OR (lead_id IS NULL)",
            name="ck_agendamento_bloqueio_no_lead",
        ),
        CheckConstraint(
            "(tipo <> 'bloqueio') OR (motivo_bloqueio IS NOT NULL)",
            name="ck_agendamento_bloqueio_motivo",
        ),
        # Curation entries (online/presencial) MUST have a lead_id
        CheckConstraint(
            "(tipo = 'bloqueio') OR (lead_id IS NOT NULL)",
            name="ck_agendamento_curadoria_lead",
        ),
        {"extend_existing": True},
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("leads.id", ondelete="CASCADE"),
        nullable=True,  # nullable for tipo='bloqueio'
        index=True,
    )
    data: Mapped[date] = mapped_column(Date, nullable=False)
    hora: Mapped[time] = mapped_column(Time, nullable=False)
    status: Mapped[str] = mapped_column(
        agendamento_status_enum,
        nullable=False,
        default=AgendamentoStatus.pendente.value,
    )
    tipo: Mapped[str] = mapped_column(
        agendamento_tipo_enum, nullable=False, default=AgendamentoTipo.online.value
    )
    motivo_bloqueio: Mapped[Optional[str]] = mapped_column(
        motivo_bloqueio_enum, nullable=True
    )
    consultor_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    notas: Mapped[Optional[str]] = mapped_column(String(2000), nullable=True)
    cancelado_em: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    motivo_cancelamento: Mapped[Optional[str]] = mapped_column(
        String(500), nullable=True
    )
    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    lead: Mapped[Optional["LeadModel"]] = relationship(
        "LeadModel", back_populates="agendamentos"
    )
