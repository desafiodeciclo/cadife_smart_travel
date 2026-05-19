import uuid
import unicodedata
from pydantic import BaseModel, Field, ConfigDict, field_validator
from app.infrastructure.persistence.types import GUID, StringArray
from datetime import date
from typing import TYPE_CHECKING, Optional
from sqlalchemy import Boolean, Date, Enum as SAEnum, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base
from app.domain.entities.enums import PerfilViagem, OrcamentoPerfil as OrcamentoNivel
from app.services.ai_normalization import (
    PERFIL_ALIASES as _PERFIL_ALIASES,
    ORCAMENTO_ALIASES as _ORCAMENTO_ALIASES,
)

if TYPE_CHECKING:
    from app.models.lead import Lead


class Briefing(Base):
    __tablename__ = "briefings"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    lead_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("leads.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    destino: Mapped[Optional[str]] = mapped_column(String(255))
    origem: Mapped[Optional[str]] = mapped_column(String(255))
    data_ida: Mapped[Optional[date]] = mapped_column(Date)
    data_volta: Mapped[Optional[date]] = mapped_column(Date)
    duracao_dias: Mapped[Optional[int]] = mapped_column(Integer)
    qtd_pessoas: Mapped[Optional[int]] = mapped_column(Integer)
    perfil: Mapped[Optional[PerfilViagem]] = mapped_column(
        SAEnum(
            PerfilViagem,
            name="perfil_viagem_enum",
            create_type=False,
            values_callable=lambda obj: [e.value for e in obj],
        ),
        nullable=True,
    )
    tipo_viagem: Mapped[Optional[list[str]]] = mapped_column(StringArray())
    preferencias: Mapped[Optional[list[str]]] = mapped_column(StringArray())
    orcamento: Mapped[Optional[OrcamentoNivel]] = mapped_column(
        SAEnum(
            OrcamentoNivel,
            name="orcamento_perfil_enum",
            create_type=False,
            values_callable=lambda obj: [e.value for e in obj],
        ),
        nullable=True,
    )
    tem_passaporte: Mapped[Optional[bool]] = mapped_column(Boolean)
    observacoes: Mapped[Optional[str]] = mapped_column(Text)
    completude_pct: Mapped[int] = mapped_column(Integer, default=0)

    lead: Mapped["Lead"] = relationship("Lead", back_populates="briefing", lazy="noload")


def calculate_completude(briefing_data: dict) -> int:
    """Calcula o percentual de completude do briefing (9 campos obrigatórios, peso uniforme)."""
    from app.infrastructure.persistence.models.briefing_model import (
        calculate_completude as _canonical,
    )
    return _canonical(briefing_data)


# Pydantic schemas

class BriefingExtracted(BaseModel):
    """Schema para Structured Outputs API — extração automática pela IA."""

    model_config = ConfigDict(extra="forbid")

    destino: Optional[str] = Field(
        None,
        description="Cidade, país ou região de destino. Extraia APENAS se mencionado explicitamente pelo cliente.",
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
    orcamento: Optional[OrcamentoNivel] = Field(
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
        if isinstance(v, str):
            # NFC-normalize before lookup to handle NFD strings from LLM responses
            key = unicodedata.normalize("NFC", v.lower().strip())
            return _PERFIL_ALIASES.get(key, key)
        return v

    @field_validator("orcamento", mode="before")
    @classmethod
    def _normalize_orcamento(cls, v: object) -> object:
        if isinstance(v, str):
            key = unicodedata.normalize("NFC", v.lower().strip())
            return _ORCAMENTO_ALIASES.get(key, key)
        return v

    @field_validator("tem_passaporte", mode="before")
    @classmethod
    def _normalize_tem_passaporte(cls, v: object) -> object:
        if isinstance(v, str):
            normalized = unicodedata.normalize("NFC", v.lower().strip())
            if normalized in ("sim", "s", "yes", "y", "true", "1"):
                return True
            if normalized in ("não", "nao", "n", "no", "false", "0"):
                return False
        return v



class BriefingUpdate(BaseModel):
    destino: Optional[str] = None
    origem: Optional[str] = None
    data_ida: Optional[date] = None
    data_volta: Optional[date] = None
    qtd_pessoas: Optional[int] = None
    perfil: Optional[PerfilViagem] = None
    tipo_viagem: Optional[list[str]] = None
    preferencias: Optional[list[str]] = None
    orcamento: Optional[OrcamentoNivel] = None
    tem_passaporte: Optional[bool] = None
    observacoes: Optional[str] = None


class BriefingResponse(BaseModel):
    lead_id: uuid.UUID
    destino: Optional[str]
    origem: Optional[str]
    data_ida: Optional[date]
    data_volta: Optional[date]
    duracao_dias: Optional[int]
    qtd_pessoas: Optional[int]
    perfil: Optional[str]
    tipo_viagem: Optional[list[str]]
    preferencias: Optional[list[str]]
    orcamento: Optional[str]
    tem_passaporte: Optional[bool]
    observacoes: Optional[str]
    completude_pct: int

    model_config = ConfigDict(from_attributes=True)