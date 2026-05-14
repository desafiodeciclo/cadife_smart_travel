"""
Pydantic schemas — Consultor Profile Extension
================================================
Bio update, metrics aggregation, and sales goals.

PRD: docs/prd/PRD-agency-settings-and-consultor-profile.md
"""

from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, field_validator


class BioUpdateRequest(BaseModel):
    bio: str = Field(..., max_length=500)

    @field_validator("bio")
    @classmethod
    def _strip_tags(cls, v: str) -> str:
        # Cheap HTML-tag strip; service layer also runs `bleach` if available.
        import re

        cleaned = re.sub(r"<[^>]*>", "", v).strip()
        return cleaned


class ConsultorMetricsResponse(BaseModel):
    leads_total: int = Field(ge=0)
    leads_qualificados: int = Field(ge=0)
    propostas_enviadas: int = Field(ge=0)
    vendas_fechadas: int = Field(ge=0)
    taxa_conversao: float = Field(ge=0.0, le=1.0)
    gerado_em: datetime


class SaleGoalResponse(BaseModel):
    period_year: int
    period_month: int = Field(ge=1, le=12)
    target: int = Field(ge=0)
    achieved: int = Field(ge=0)

    model_config = {"from_attributes": True}


class SaleGoalsListResponse(BaseModel):
    goals: list[SaleGoalResponse]


class SaleGoalUpdateRequest(BaseModel):
    """Body for PUT /users/me/goals/{year}/{month} — admin only."""

    target: int = Field(..., ge=0, le=10000)
