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
    Time,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import ENUM as SAEnum, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.domain.entities.enums import AgendamentoStatus, AgendamentoTipo
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
        # Business rule: a lead cannot have duplicate slot bookings
        UniqueConstraint("lead_id", "data", "hora", name="uq_agendamento_lead_slot"),
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
    data: Mapped[date] = mapped_column(Date, nullable=False)
    hora: Mapped[time] = mapped_column(Time, nullable=False)
    status: Mapped[str] = mapped_column(
        agendamento_status_enum, nullable=False, default=AgendamentoStatus.pendente.value
    )
    tipo: Mapped[str] = mapped_column(
        agendamento_tipo_enum, nullable=False, default=AgendamentoTipo.online.value
    )
    consultor_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    lead: Mapped["LeadModel"] = relationship("LeadModel", back_populates="agendamentos")
