"""
Pydantic schemas — Agency Settings + Message Templates
=======================================================
Validation rules implemented here:
  - Horario: dias ⊂ [1..7]; fim > inicio; intervalo ≥ 1h.
  - Template placeholders: whitelist enforced via regex.
  - Categoria: enum validated.
"""

from __future__ import annotations

import re
from datetime import datetime, time
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator, model_validator


CategoriaTemplate = Literal[
    "boas_vindas", "lembrete", "pos_curadoria", "follow_up", "proposta", "outro"
]

ALLOWED_PLACEHOLDERS = {
    "nome",
    "destino",
    "data_ida",
    "data_volta",
    "consultor_nome",
    "agency_nome",
}

PLACEHOLDER_RE = re.compile(r"\{\{(\w+)\}\}")


# ── Horario / Notificacoes ──────────────────────────────────────────────────


class HorarioFuncionamento(BaseModel):
    dias: list[int] = Field(..., min_length=1, max_length=7)
    inicio: str = Field(..., description="HH:MM")
    fim: str = Field(..., description="HH:MM")

    @field_validator("dias")
    @classmethod
    def _dias_in_range(cls, v: list[int]) -> list[int]:
        for d in v:
            if d < 1 or d > 7:
                raise ValueError("dia_invalido_use_1_a_7")
        return sorted(set(v))

    @model_validator(mode="after")
    def _validate_intervalo(self) -> "HorarioFuncionamento":
        try:
            inicio = time.fromisoformat(self.inicio)
            fim = time.fromisoformat(self.fim)
        except ValueError:
            raise ValueError("formato_horario_invalido_use_HH:MM")
        if fim <= inicio:
            raise ValueError("fim_deve_ser_apos_inicio")
        # intervalo mínimo 1h
        diff_min = (fim.hour * 60 + fim.minute) - (inicio.hour * 60 + inicio.minute)
        if diff_min < 60:
            raise ValueError("intervalo_minimo_1h")
        return self


class NotificacoesPrefs(BaseModel):
    leads_qualificados: bool = True
    novos_leads: bool = True
    propostas_aprovadas: bool = True
    agendamentos_confirmados: bool = True


# ── Templates ───────────────────────────────────────────────────────────────


class MessageTemplateBase(BaseModel):
    nome: str = Field(..., min_length=1, max_length=100)
    categoria: CategoriaTemplate
    conteudo: str = Field(..., min_length=1, max_length=4000)
    variaveis: list[str] = Field(default_factory=list)

    @model_validator(mode="after")
    def _validate_placeholders(self) -> "MessageTemplateBase":
        found = set(PLACEHOLDER_RE.findall(self.conteudo))
        invalid = found - ALLOWED_PLACEHOLDERS
        if invalid:
            raise ValueError(f"placeholders_nao_permitidos:{','.join(sorted(invalid))}")
        declared = set(self.variaveis)
        if declared and (found - declared):
            raise ValueError("variaveis_declaradas_incompletas")
        return self


class MessageTemplateCreate(MessageTemplateBase):
    pass


class MessageTemplateUpdate(BaseModel):
    """Partial update — fields are all optional."""

    nome: Optional[str] = Field(None, min_length=1, max_length=100)
    categoria: Optional[CategoriaTemplate] = None
    conteudo: Optional[str] = Field(None, min_length=1, max_length=4000)
    variaveis: Optional[list[str]] = None
    ativo: Optional[bool] = None

    @model_validator(mode="after")
    def _validate_placeholders_if_present(self) -> "MessageTemplateUpdate":
        if self.conteudo is not None:
            found = set(PLACEHOLDER_RE.findall(self.conteudo))
            invalid = found - ALLOWED_PLACEHOLDERS
            if invalid:
                raise ValueError(
                    f"placeholders_nao_permitidos:{','.join(sorted(invalid))}"
                )
        return self


class MessageTemplateDTO(BaseModel):
    id: UUID
    nome: str
    categoria: CategoriaTemplate
    conteudo: str
    variaveis: list[str]
    ativo: bool
    created_at: datetime

    model_config = {"from_attributes": True}


# ── Settings response / update ──────────────────────────────────────────────


class AgencySettingsResponse(BaseModel):
    horario_funcionamento: HorarioFuncionamento
    notificacoes_prefs: NotificacoesPrefs
    templates: list[MessageTemplateDTO]
    updated_at: datetime


class AgencySettingsUpdateRequest(BaseModel):
    horario_funcionamento: Optional[HorarioFuncionamento] = None
    notificacoes_prefs: Optional[NotificacoesPrefs] = None

    @model_validator(mode="after")
    def _at_least_one_field(self) -> "AgencySettingsUpdateRequest":
        if self.horario_funcionamento is None and self.notificacoes_prefs is None:
            raise ValueError("at_least_one_field_required")
        return self
