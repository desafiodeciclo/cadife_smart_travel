import uuid
from app.infrastructure.persistence.types import GUID
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING, Any, Literal, Optional

from sqlalchemy import JSON, DateTime, ForeignKey, Integer, Numeric, String, Text, func
from sqlalchemy.dialects.postgresql import ENUM as PgEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from pydantic import BaseModel, Field, model_validator

from app.core.database import Base
from app.domain.entities.enums import PropostaStatus

if TYPE_CHECKING:
    from app.models.lead import Lead


# ─────────────────────────────────────────────────────────────────────────────
# ORM MODELS
# ─────────────────────────────────────────────────────────────────────────────


class Proposta(Base):
    __tablename__ = "propostas"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("leads.id"), nullable=False, index=True
    )
    descricao: Mapped[str] = mapped_column(Text, nullable=False)
    valor_estimado: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    status: Mapped[PropostaStatus] = mapped_column(
        PgEnum(PropostaStatus, name="proposta_status_enum", create_type=False),
        nullable=False,
        default=PropostaStatus.rascunho,
    )
    consultor_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(), ForeignKey("users.id")
    )
    expiration_hours: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default="48"
    )
    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    # gap §3.4
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
        ForeignKey("users.id"),
        nullable=True,
    )

    lead: Mapped["Lead"] = relationship("Lead", back_populates="propostas")


class PropostaVersao(Base):
    """Append-only snapshot of a proposta at a moment in time (gap §3.4.4)."""

    __tablename__ = "proposta_versoes"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    proposta_id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        ForeignKey("propostas.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    numero_versao: Mapped[int] = mapped_column(Integer, nullable=False)
    snapshot_json: Mapped[dict] = mapped_column(JSON, nullable=False)
    motivo: Mapped[str] = mapped_column(String(50), nullable=False)
    created_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(), ForeignKey("users.id"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


# ─────────────────────────────────────────────────────────────────────────────
# Pydantic SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────


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

    model_config = {"from_attributes": True}


class PropostaVersaoDTO(BaseModel):
    id: uuid.UUID
    proposta_id: uuid.UUID
    numero_versao: int
    motivo: MotivoVersao
    snapshot_json: dict[str, Any]
    created_by: Optional[uuid.UUID]
    created_at: datetime

    model_config = {"from_attributes": True}


class PropostaVersoesListResponse(BaseModel):
    items: list[PropostaVersaoDTO]
    total: int
