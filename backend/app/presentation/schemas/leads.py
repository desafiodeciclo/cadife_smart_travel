"""
Lead Schemas — Presentation Layer (DTOs / Response Models)
============================================================
Strict Pydantic v2 schemas for everything that crosses the wire.
These classes must NEVER contain ORM/SQLAlchemy objects — only
primitive types, enums, UUIDs and datetime.

Defence rules:
  * No internal DB fields (e.g. telefone_hash) are exposed.
  * No ORM instances are returned directly from route handlers.
  * Mappers in app/application/dto/lead_mapper.py translate ORM → DTO.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.domain.entities.enums import (
    LeadOrigem,
    LeadScore,
    LeadStatus,
    OrcamentoPerfil,
    PerfilViagem,
    PropostaStatus,
    TipoMensagem,
)

# ── Shared sub-items ───────────────────────────────────────────────────────


class PropostaListItemDTO(BaseModel):
    id: uuid.UUID
    descricao: str
    status: PropostaStatus
    valor_estimado: Optional[Decimal] = None
    criado_em: datetime

    model_config = ConfigDict(from_attributes=True, extra="forbid")


class BriefingDTO(BaseModel):
    """Briefing snapshot embedded in lead detail response."""

    id: uuid.UUID
    destino: Optional[str] = None
    origem: Optional[str] = None
    data_ida: Optional[date] = None
    data_volta: Optional[date] = None
    duracao_dias: Optional[int] = None
    qtd_pessoas: Optional[int] = None
    perfil: Optional[PerfilViagem] = None
    tipo_viagem: Optional[list[str]] = None
    preferencias: Optional[list[str]] = None
    orcamento: Optional[OrcamentoPerfil] = None
    tem_passaporte: Optional[bool] = None
    observacoes: Optional[str] = None
    completude_pct: int = 0

    model_config = ConfigDict(from_attributes=True, extra="forbid")


class InteracaoSummaryDTO(BaseModel):
    """Compact interaction for the last-messages list in lead detail."""

    id: uuid.UUID
    mensagem_cliente: Optional[str] = None
    mensagem_ia: Optional[str] = None
    tipo_mensagem: TipoMensagem
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True, extra="forbid")


# ── Request bodies ─────────────────────────────────────────────────────────


class LeadCreateRequest(BaseModel):
    nome: Optional[str] = None
    telefone: str = Field(..., min_length=8, max_length=32)
    origem: LeadOrigem = LeadOrigem.whatsapp

    model_config = ConfigDict(extra="forbid")


class ManualLeadCreate(BaseModel):
    """Schema for manual lead creation via agency app."""

    nome: str
    telefone: str = Field(..., min_length=8, max_length=32)
    email: Optional[str] = None
    destino_interesse: Optional[str] = None
    datas_aproximadas: Optional[str] = None
    orcamento_estimado: Optional[str] = None
    numero_passageiros: Optional[int] = None
    origem: LeadOrigem = Field(..., description="Must be one of the manual origins")
    consultor_id: Optional[uuid.UUID] = None
    preferencias: Optional[str] = None
    force_create: bool = Field(
        default=False, description="If True, bypasses phone duplication check"
    )

    model_config = ConfigDict(extra="forbid")


class LeadUpdateRequest(BaseModel):
    nome: Optional[str] = None
    status: Optional[LeadStatus] = None
    score: Optional[LeadScore] = None
    consultor_id: Optional[uuid.UUID] = None

    model_config = ConfigDict(extra="forbid")


class LeadPatchRequest(BaseModel):
    """Partial update — all fields optional. Used by PATCH /leads/{id}."""

    status: Optional[LeadStatus] = None
    consultor_id: Optional[uuid.UUID] = None
    nome: Optional[str] = None
    score: Optional[LeadScore] = None

    model_config = ConfigDict(extra="forbid")


class AyaToggleRequest(BaseModel):
    ativo: bool
    motivo: Optional[str] = Field(
        default=None,
        max_length=500,
        description="Motivo do toggle — obrigatório ao desativar (recomendado)",
    )

    model_config = ConfigDict(extra="forbid")


class AyaToggleResponseDTO(BaseModel):
    lead_id: uuid.UUID
    aya_ativo: bool
    motivo: Optional[str] = None
    alterado_em: datetime
    contexto_msgs_count: int = Field(
        description="Mensagens recentes disponíveis para contexto quando AYA for reativada"
    )

    model_config = ConfigDict(extra="forbid")


# ── Response DTOs ──────────────────────────────────────────────────────────


class LeadListItemDTO(BaseModel):
    """DTO for paginated list (GET /leads)."""

    id: uuid.UUID
    nome: Optional[str] = None
    telefone_mascarado: Optional[str] = None
    origem: LeadOrigem
    status: LeadStatus
    score: Optional[LeadScore] = None
    consultor_id: Optional[uuid.UUID] = None
    score_numerico: Optional[int] = None
    aya_ativo: bool = True
    criado_em: datetime
    atualizado_em: datetime
    completude_pct: Optional[int] = None

    model_config = ConfigDict(from_attributes=True, extra="forbid")


class LeadDetailDTO(BaseModel):
    """DTO for single-lead detail (GET /leads/{id}).
    Includes embedded briefing snapshot and last 10 interactions.
    """

    id: uuid.UUID
    nome: Optional[str] = None
    telefone: str
    origem: LeadOrigem
    status: LeadStatus
    score: Optional[LeadScore] = None
    
    # --- Unificação de campos Aya e Score ---
    aya_ativo: bool = True
    score_numerico: Optional[int] = None
    score_calculado_em: Optional[datetime] = None

    consultor_id: Optional[uuid.UUID] = None
    consultor_nome: Optional[str] = None
    consultor_avatar: Optional[str] = None
    is_archived: bool
    deletado_em: Optional[datetime] = None
    criado_em: datetime
    atualizado_em: datetime
    propostas: list[PropostaListItemDTO] = Field(default_factory=list)
    briefing: Optional[BriefingDTO] = None
    ultimas_interacoes: list[InteracaoSummaryDTO] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True, extra="forbid")


class LeadListResponseDTO(BaseModel):
    """Offset-based paginated list response (backward compatible)."""

    items: list[LeadListItemDTO]
    total: int
    page: int
    limit: int
    pages: int

    model_config = ConfigDict(extra="forbid")


class LeadCursorListResponseDTO(BaseModel):
    """Cursor-based paginated list response."""

    items: list[LeadListItemDTO]
    next_cursor: Optional[str] = None
    has_more: bool

    model_config = ConfigDict(extra="forbid")


class LeadMetricsDTO(BaseModel):
    """DTO for lead dashboard metrics."""

    total_ativos: int
    total_novos: int
    total_em_atendimento: int
    total_qualificados: int
    total_agendados: int
    total_proposta: int
    total_fechados: int
    total_perdidos: int

    model_config = ConfigDict(extra="forbid")