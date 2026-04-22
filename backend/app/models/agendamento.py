import uuid
from datetime import date, datetime, time
from typing import TYPE_CHECKING, Optional

from sqlalchemy import Date, DateTime, ForeignKey, String, Time, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from pydantic import BaseModel

from app.core.database import Base
from app.domain.entities.enums import AgendamentoStatus, AgendamentoTipo

if TYPE_CHECKING:
    from app.models.lead import Lead


class Agendamento(Base):
    __tablename__ = "agendamentos"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    lead_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("leads.id"), nullable=False, index=True)
    data: Mapped[date] = mapped_column(Date, nullable=False)
    hora: Mapped[time] = mapped_column(Time, nullable=False)
    status: Mapped[AgendamentoStatus] = mapped_column(String(20), nullable=False, default=AgendamentoStatus.pendente)
    tipo: Mapped[AgendamentoTipo] = mapped_column(String(20), nullable=False, default=AgendamentoTipo.online)
    consultor_id: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    lead: Mapped["Lead"] = relationship("Lead", back_populates="agendamentos")


class AgendamentoCreate(BaseModel):
    lead_id: uuid.UUID
    data: date
    hora: time
    tipo: AgendamentoTipo = AgendamentoTipo.online
    consultor_id: Optional[uuid.UUID] = None


class AgendamentoUpdate(BaseModel):
    status: AgendamentoStatus


class AgendamentoResponse(BaseModel):
    id: uuid.UUID
    lead_id: uuid.UUID
    data: date
    hora: time
    status: AgendamentoStatus
    tipo: AgendamentoTipo
    consultor_id: Optional[uuid.UUID]
    criado_em: datetime

    model_config = {"from_attributes": True}


class SlotDisponivel(BaseModel):
    data: date
    hora: str
    disponivel: bool


class DisponibilidadeResponse(BaseModel):
    slots: list[SlotDisponivel]
