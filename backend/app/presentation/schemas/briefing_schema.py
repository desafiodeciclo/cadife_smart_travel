import unicodedata
import uuid
from datetime import date
from typing import Optional, List

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.domain.entities.enums import OrcamentoPerfil, PerfilViagem
from app.services.ai_normalization import normalize_orcamento, normalize_perfil


class BriefingSchema(BaseModel):
    destino: Optional[str] = Field(None, min_length=2, max_length=255)
    origem: Optional[str] = Field(None, min_length=2, max_length=255)
    data_ida: Optional[date] = None
    data_volta: Optional[date] = None
    qtd_pessoas: Optional[int] = Field(None, gt=0)
    perfil: Optional[PerfilViagem] = None
    tipo_viagem: List[str] = Field(default_factory=list)
    preferencias: List[str] = Field(default_factory=list)
    orcamento: Optional[OrcamentoPerfil] = None
    tem_passaporte: Optional[bool] = None
    observacoes: Optional[str] = None

    @field_validator("data_volta")
    @classmethod
    def validate_dates(cls, v: Optional[date], info):
        if v and info.data.get("data_ida") and v < info.data["data_ida"]:
            raise ValueError("Data de volta não pode ser anterior à data de ida")
        return v

    model_config = {"from_attributes": True}


class BriefingExtracted(BaseModel):
    """Schema para Structured Outputs API — extração automática pela IA."""

    model_config = ConfigDict(extra="forbid")

    destino: Optional[str] = Field(
        None,
        description="Cidade, país ou região de destino. Extraia APENAS se mencionado explicitamente pelo cliente.",
    )
    origem: Optional[str] = Field(
        None,
        description="Cidade, país ou região de origem. Extraia APENAS se mencionado explicitamente.",
    )
    data_ida: Optional[date] = Field(
        None,
        description=(
            "Data de início da viagem (YYYY-MM-DD). "
            "Extraia APENAS se houver uma data ou mês/ano claro. NÃO infira."
        ),
    )
    data_volta: Optional[date] = Field(
        None,
        description="Data de retorno da viagem (YYYY-MM-DD). Extraia APENAS se mencionada explicitamente.",
    )
    qtd_pessoas: Optional[int] = Field(
        None, description="Número total de passageiros (adultos + crianças)."
    )
    perfil: Optional[PerfilViagem] = Field(
        None, description="Composição do grupo: casal, familia, solo, grupo ou amigos."
    )
    tipo_viagem: list[str] = Field(
        default_factory=list,
        description="Estilo da viagem: aventura, luxo, romântica, gastronômica, etc.",
    )
    preferencias: list[str] = Field(
        default_factory=list,
        description="Interesses específicos: praias, museus, compras, resorts, neve, etc.",
    )
    orcamento: Optional[OrcamentoPerfil] = Field(
        None,
        description="Nível de investimento: baixo (econômico), medio (padrão), alto (conforto) ou premium (luxo).",
    )
    tem_passaporte: Optional[bool] = Field(
        None,
        description="True se o cliente confirmou que possui passaporte válido, False se disse que não tem.",
    )
    observacoes: Optional[str] = Field(
        None,
        description="Notas adicionais, restrições alimentares, celebrações ou pedidos especiais.",
    )
    campos_inferidos: list[str] = Field(
        default_factory=list,
        description=(
            "Lista de campos cujo valor foi inferido pelo contexto, "
            "não mencionados explicitamente pelo cliente. "
            "Não afeta o score — apenas rastreabilidade."
        ),
    )

    @field_validator("perfil", mode="before")
    @classmethod
    def _normalize_perfil(cls, v: object) -> object:
        return normalize_perfil(v)

    @field_validator("orcamento", mode="before")
    @classmethod
    def _normalize_orcamento(cls, v: object) -> object:
        return normalize_orcamento(v)


class BriefingUpdate(BaseModel):
    destino: Optional[str] = None
    origem: Optional[str] = None
    data_ida: Optional[date] = None
    data_volta: Optional[date] = None
    qtd_pessoas: Optional[int] = None
    perfil: Optional[PerfilViagem] = None
    tipo_viagem: Optional[list[str]] = None
    preferencias: Optional[list[str]] = None
    orcamento: Optional[OrcamentoPerfil] = None
    tem_passaporte: Optional[bool] = None
    observacoes: Optional[str] = None


class BriefingResponse(BriefingSchema):
    lead_id: uuid.UUID
    completude_pct: int
    duracao_dias: Optional[int] = None
