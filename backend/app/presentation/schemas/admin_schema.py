"""
Admin Schemas — Pydantic models for admin user management.
"""

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.domain.entities.enums import UserPerfil


class AdminUserCreate(BaseModel):
    """Payload for creating a new consultant by admin."""

    nome: str = Field(..., min_length=2, max_length=255)
    email: EmailStr
    telefone: Optional[str] = Field(None, max_length=20)
    role: UserPerfil = Field(default=UserPerfil.consultor)

    model_config = ConfigDict(extra="forbid")


class AdminUserUpdate(BaseModel):
    """Payload for updating a consultant by admin."""

    nome: Optional[str] = Field(None, min_length=2, max_length=255)
    email: Optional[EmailStr] = None
    telefone: Optional[str] = Field(None, max_length=20)
    is_active: Optional[bool] = None

    model_config = ConfigDict(extra="forbid")


class AdminUserMetrics(BaseModel):
    """Aggregated metrics for a consultant."""

    total_leads: int = 0
    active_leads: int = 0
    closed_leads: int = 0

    model_config = ConfigDict(extra="forbid")


class AdminUserResponse(BaseModel):
    """Consultant detail returned by admin endpoints."""

    id: uuid.UUID
    nome: str
    email: str
    telefone: Optional[str]
    perfil: UserPerfil
    is_active: bool
    criado_em: datetime
    metrics: AdminUserMetrics = AdminUserMetrics()

    model_config = ConfigDict(from_attributes=True)


class AdminUserListResponse(BaseModel):
    """Paginated list of consultants."""

    items: list[AdminUserResponse]
    total: int

    model_config = ConfigDict(extra="forbid")


class AgenciaMetricsResponse(BaseModel):
    """Aggregated agency-wide metrics for the admin dashboard."""

    total_leads: int = 0
    taxa_conversao: float = 0.0
    receita_estimada: float = 0.0
    consultores_ativos: int = 0
    leads_novos_mes: int = 0
    leads_fechados_mes: int = 0
    leads_perdidos_mes: int = 0

    model_config = ConfigDict(extra="forbid")


class AdminLeadReassignRequest(BaseModel):
    """Payload for reassigning a lead to another consultant."""

    new_consultor_id: uuid.UUID

    model_config = ConfigDict(extra="forbid")


class AdminLeadReassignResponse(BaseModel):
    """Response after reassigning a lead."""

    lead_id: uuid.UUID
    old_consultor_id: Optional[uuid.UUID]
    new_consultor_id: uuid.UUID
    message: str = "Lead reatribuído com sucesso"

    model_config = ConfigDict(extra="forbid")
