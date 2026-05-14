import uuid
from datetime import date, datetime, time
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.domain.entities.enums import AgendamentoStatus, AgendamentoTipo, MotivoBloqueio


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

    model_config = ConfigDict(from_attributes=True)


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
