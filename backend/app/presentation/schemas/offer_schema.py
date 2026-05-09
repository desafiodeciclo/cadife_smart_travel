import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.domain.entities.enums import OfferCategoria, OfferStatus


class OfferCreate(BaseModel):
    titulo: str = Field(..., min_length=3, max_length=255)
    destino: str = Field(..., min_length=2, max_length=255)
    descricao: Optional[str] = None
    categoria: OfferCategoria = OfferCategoria.outros
    preco_base: Optional[Decimal] = Field(None, ge=0, decimal_places=2)
    servicos_inclusos: list[str] = Field(default_factory=list)
    data_saida_sugerida: Optional[date] = None
    duracao_dias: Optional[int] = Field(None, ge=1)

    model_config = ConfigDict(extra="forbid")


class OfferUpdate(BaseModel):
    titulo: Optional[str] = Field(None, min_length=3, max_length=255)
    destino: Optional[str] = Field(None, min_length=2, max_length=255)
    descricao: Optional[str] = None
    categoria: Optional[OfferCategoria] = None
    preco_base: Optional[Decimal] = Field(None, ge=0, decimal_places=2)
    servicos_inclusos: Optional[list[str]] = None
    imagens: Optional[list[str]] = None
    data_saida_sugerida: Optional[date] = None
    duracao_dias: Optional[int] = Field(None, ge=1)

    model_config = ConfigDict(extra="forbid")


class OfferResponse(BaseModel):
    id: uuid.UUID
    titulo: str
    destino: str
    descricao: Optional[str]
    categoria: OfferCategoria
    preco_base: Optional[Decimal]
    servicos_inclusos: list[str]
    imagens: list[str]
    data_saida_sugerida: Optional[date]
    duracao_dias: Optional[int]
    status: OfferStatus
    criado_por: uuid.UUID
    criado_em: datetime
    atualizado_em: datetime

    model_config = ConfigDict(from_attributes=True, extra="forbid")

    @field_validator("servicos_inclusos", "imagens", mode="before")
    @classmethod
    def _ensure_list(cls, v):
        return v if v is not None else []


class OfferListItem(BaseModel):
    id: uuid.UUID
    titulo: str
    destino: str
    categoria: OfferCategoria
    preco_base: Optional[Decimal]
    imagens: list[str]
    status: OfferStatus
    criado_em: datetime

    model_config = ConfigDict(from_attributes=True, extra="forbid")


class OfferInterestResponse(BaseModel):
    message: str
    lead_id: uuid.UUID
    offer_id: uuid.UUID

    model_config = ConfigDict(extra="forbid")


class OfferListResponse(BaseModel):
    items: list[OfferListItem]
    total: int
    page: int
    limit: int
    pages: int

    model_config = ConfigDict(extra="forbid")
