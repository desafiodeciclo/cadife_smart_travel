import uuid
from datetime import date, datetime, time
from typing import TYPE_CHECKING, Optional

from pydantic import BaseModel, Field, model_validator
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

    lead: Mapped[Optional["Lead"]] = relationship("Lead", back_populates="agendamentos")


class AgendamentoCreate(BaseModel):
    lead_id: Optional[uuid.UUID] = Field(
        default=None,
        description="Obrigatório para curadoria (online/presencial); deve ser NULL para bloqueio.",
    )
    data: date
    hora: time
    tipo: AgendamentoTipo = AgendamentoTipo.online
    motivo_bloqueio: Optional[MotivoBloqueio] = Field(
        default=None,
        description="Obrigatório quando tipo=bloqueio.",
    )
    notas: Optional[str] = Field(default=None, max_length=2000)
    consultor_id: Optional[uuid.UUID] = Field(
        default=None,
        description="Read-only: definido automaticamente pelo backend com base no usuário autenticado.",
    )

    @model_validator(mode="after")
    def _validar_bloqueio_vs_curadoria(self):
        if self.tipo == AgendamentoTipo.bloqueio:
            if self.lead_id is not None:
                raise ValueError("Bloqueio não pode ter lead_id.")
            if self.motivo_bloqueio is None:
                raise ValueError("Bloqueio exige motivo_bloqueio.")
        else:
            if self.lead_id is None:
                raise ValueError("Curadoria (online/presencial) exige lead_id.")
        return self


class AgendamentoUpdate(BaseModel):
    status: AgendamentoStatus


class AgendamentoPatch(BaseModel):
    lead_id: Optional[uuid.UUID] = None
    data: Optional[date] = None
    hora: Optional[time] = None
    status: Optional[AgendamentoStatus] = None
    tipo: Optional[AgendamentoTipo] = None
    motivo_bloqueio: Optional[MotivoBloqueio] = None
    notas: Optional[str] = Field(default=None, max_length=2000)

    @model_validator(mode="after")
    def _proibir_cancelado_via_patch(self):
        if self.status == AgendamentoStatus.cancelado:
            raise ValueError("Use DELETE para cancelar um agendamento.")
        return self


class CancelAgendamentoRequest(BaseModel):
    motivo: Optional[str] = Field(default=None, max_length=500)


class AgendamentoResponse(BaseModel):
    id: uuid.UUID
    lead_id: Optional[uuid.UUID]
    data: date
    hora: time
    status: AgendamentoStatus
    tipo: AgendamentoTipo
    motivo_bloqueio: Optional[MotivoBloqueio] = None
    consultor_id: Optional[uuid.UUID]
    notas: Optional[str] = None
    cancelado_em: Optional[datetime] = None
    motivo_cancelamento: Optional[str] = None
    criado_em: datetime

    model_config = {"from_attributes": True}


class AgendamentoListResponse(BaseModel):
    items: list[AgendamentoResponse]
    total: int
    data: date


class SlotDisponivel(BaseModel):
    data: date
    hora: str
    disponivel: bool


class DisponibilidadeResponse(BaseModel):
    slots: list[SlotDisponivel]
