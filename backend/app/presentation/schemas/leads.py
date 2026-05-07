"""
Lead Schemas — Presentation Layer (DTOs / Response Models)
============================================================
Strict Pydantic v2 schemas for everything that crosses the wire.
These classes must NEVER contain ORM/SQLAlchemy objects — only
primitive types, enums, UUIDs and datetime.

This module enforces the IDOR / DataLeak defence rule:
  * No internal DB fields (e.g. telefone_hash) are exposed.
  * No ORM instances are returned directly from route handlers.
  * Mappers in app/application/dto/lead_mapper.py translate ORM → DTO.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.domain.entities.enums import LeadOrigem, LeadScore, LeadStatus, PropostaStatus


# ── Shared sub-items ───────────────────────────────────────────────────────

class PropostaListItemDTO(BaseModel):
    id: uuid.UUID
    descricao: str
    status: PropostaStatus
    valor_estimado: Optional[Decimal] = None
    criado_em: datetime

    model_config = ConfigDict(from_attributes=True, extra="forbid")


# ── Request bodies ─────────────────────────────────────────────────────────

class LeadCreateRequest(BaseModel):
    nome: Optional[str] = None
    telefone: str = Field(..., min_length=8, max_length=32)
    origem: LeadOrigem = LeadOrigem.whatsapp

    model_config = ConfigDict(extra="forbid")


class LeadUpdateRequest(BaseModel):
    nome: Optional[str] = None
    status: Optional[LeadStatus] = None
    score: Optional[LeadScore] = None
    consultor_id: Optional[uuid.UUID] = None

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
    criado_em: datetime
    atualizado_em: datetime
    completude_pct: Optional[int] = None

    model_config = ConfigDict(from_attributes=True, extra="forbid")


class LeadDetailDTO(BaseModel):
    """DTO for single-lead detail (GET /leads/{id})."""
    id: uuid.UUID
    nome: Optional[str] = None
    telefone: str
    origem: LeadOrigem
    status: LeadStatus
    score: Optional[LeadScore] = None
    consultor_id: Optional[uuid.UUID] = None
    consultor_nome: Optional[str] = None
    consultor_avatar: Optional[str] = None
    is_archived: bool
    criado_em: datetime
    atualizado_em: datetime
    propostas: list[PropostaListItemDTO] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True, extra="forbid")


class LeadListResponseDTO(BaseModel):
    items: list[LeadListItemDTO]
    total: int
    page: int
    limit: int
    pages: int

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
