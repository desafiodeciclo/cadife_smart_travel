import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any, Literal, Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.domain.entities.enums import PropostaStatus


MotivoVersao = Literal[
    "criacao", "edicao", "envio", "aprovacao", "recusa", "cancelamento"
]


class PropostaCreate(BaseModel):
    lead_id: uuid.UUID
    descricao: str
    valor_estimado: Optional[Decimal] = None
    expiration_hours: int = 48


class PropostaUpdate(BaseModel):
    """Body for legacy PUT /propostas/{id}."""

    status: Optional[PropostaStatus] = None
    descricao: Optional[str] = None
    valor_estimado: Optional[Decimal] = None


class PropostaPatchRequest(BaseModel):
    """Body for PATCH /propostas/{id} — partial update WITHOUT side-effects.

    Status mutation is rejected here — use POST /propostas/{id}/enviar to send,
    or PUT /propostas/{id} (deprecated) for full status workflows.
    """

    descricao: Optional[str] = Field(None, min_length=1, max_length=4000)
    valor_estimado: Optional[Decimal] = Field(
        None, ge=0, max_digits=12, decimal_places=2
    )
    expiration_hours: Optional[int] = Field(None, ge=1, le=720)

    @model_validator(mode="after")
    def _at_least_one_field(self) -> "PropostaPatchRequest":
        if (
            self.descricao is None
            and self.valor_estimado is None
            and self.expiration_hours is None
        ):
            raise ValueError("at_least_one_field_required")
        return self


class CancelPropostaRequest(BaseModel):
    """Optional body for DELETE /propostas/{id}."""

    motivo: Optional[str] = Field(None, max_length=500)


class PropostaResponse(BaseModel):
    id: uuid.UUID
    lead_id: uuid.UUID
    descricao: str
    valor_estimado: Optional[Decimal]
    status: PropostaStatus
    consultor_id: Optional[uuid.UUID]
    expiration_hours: int
    criado_em: datetime
    enviado_em: Optional[datetime] = None
    notificacao_enviada_em: Optional[datetime] = None
    deletado_em: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class PropostaVersaoDTO(BaseModel):
    id: uuid.UUID
    proposta_id: uuid.UUID
    numero_versao: int
    motivo: MotivoVersao
    snapshot_json: dict[str, Any]
    created_by: Optional[uuid.UUID]
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PropostaVersoesListResponse(BaseModel):
    items: list[PropostaVersaoDTO]
    total: int
