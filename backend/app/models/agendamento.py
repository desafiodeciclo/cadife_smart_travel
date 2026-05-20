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
from sqlalchemy.dialects.postgresql import ENUM as PgEnum, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.domain.entities.enums import AgendamentoStatus, AgendamentoTipo, MotivoBloqueio

if TYPE_CHECKING:
    from app.models.lead import Lead


class Agendamento(Base):
    __tablename__ = "agendamentos"
    __table_args__ = (
        Index("ix_agendamentos_lead_status", "lead_id", "status"),
        Index("ix_agendamentos_consultor_data", "consultor_id", "data"),
        UniqueConstraint("lead_id", "data", "hora", name="uq_agendamento_lead_slot"),
        CheckConstraint(
            "(tipo <> 'bloqueio') OR (lead_id IS NULL)",
            name="ck_agendamento_bloqueio_no_lead",
        ),
        CheckConstraint(
            "(tipo <> 'bloqueio') OR (motivo_bloqueio IS NOT NULL)",
            name="ck_agendamento_bloqueio_motivo",
        ),
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
        nullable=True,
        index=True,
    )
    data: Mapped[date] = mapped_column(Date, nullable=False)
    hora: Mapped[time] = mapped_column(Time, nullable=False)
    status: Mapped[AgendamentoStatus] = mapped_column(
        PgEnum(AgendamentoStatus, name="agendamento_status_enum", create_type=False),
        nullable=False,
        default=AgendamentoStatus.pendente,
    )
    tipo: Mapped[AgendamentoTipo] = mapped_column(
        PgEnum(AgendamentoTipo, name="agendamento_tipo_enum", create_type=False),
        nullable=False,
        default=AgendamentoTipo.online,
    )
    motivo_bloqueio: Mapped[Optional[MotivoBloqueio]] = mapped_column(
        PgEnum(MotivoBloqueio, name="motivo_bloqueio_enum", create_type=False),
        nullable=True,
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

    lead: Mapped[Optional["Lead"]] = relationship("Lead", back_populates="agendamentos", overlaps="agendamentos,lead")
