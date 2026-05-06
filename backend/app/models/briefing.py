import uuid
from datetime import date
from typing import TYPE_CHECKING, Optional

from sqlalchemy import Boolean, Date, Enum as SAEnum, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from pydantic import BaseModel, Field

from app.infrastructure.persistence.types import GUID, StringArray

from app.core.database import Base
from app.domain.entities.enums import PerfilViagem, OrcamentoPerfil as OrcamentoNivel

if TYPE_CHECKING:
    from app.models.lead import Lead


BRIEFING_FIELDS = [
    "destino", "data_ida", "data_volta", "qtd_pessoas", "perfil",
    "tipo_viagem", "preferencias", "orcamento", "tem_passaporte",
]


class Briefing(Base):
    __tablename__ = "briefings"
    __table_args__ = {'extend_existing': True}

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    lead_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("leads.id"), unique=True, nullable=False)
    destino: Mapped[Optional[str]] = mapped_column(String(255))
    origem: Mapped[Optional[str]] = mapped_column(String(255))
    data_ida: Mapped[Optional[date]] = mapped_column(Date)
    data_volta: Mapped[Optional[date]] = mapped_column(Date)
    duracao_dias: Mapped[Optional[int]] = mapped_column(Integer)
    qtd_pessoas: Mapped[Optional[int]] = mapped_column(Integer)
    perfil: Mapped[Optional[PerfilViagem]] = mapped_column(
        SAEnum(PerfilViagem, name="perfil_viagem_enum", create_type=False),
        nullable=True,
    )
    tipo_viagem: Mapped[Optional[list[str]]] = mapped_column(StringArray())
    preferencias: Mapped[Optional[list[str]]] = mapped_column(StringArray())
    orcamento: Mapped[Optional[OrcamentoNivel]] = mapped_column(
        SAEnum(OrcamentoNivel, name="orcamento_perfil_enum", create_type=False),
        nullable=True,
    )
    tem_passaporte: Mapped[Optional[bool]] = mapped_column(Boolean)
    observacoes: Mapped[Optional[str]] = mapped_column(Text)
    completude_pct: Mapped[int] = mapped_column(Integer, default=0)

    lead: Mapped["Lead"] = relationship("Lead", back_populates="briefing")


REQUIRED_FIELDS = ["destino", "data_ida", "orcamento", "perfil"]
OPTIONAL_FIELDS = ["data_volta", "qtd_pessoas", "tipo_viagem", "preferencias", "tem_passaporte"]

def calculate_completude(briefing_data: dict) -> int:
    """
    Calcula o percentual de completude do briefing.
    Campos obrigatórios (destino, data, orçamento, perfil) têm peso maior.
    """
    total_required = len(REQUIRED_FIELDS)
    filled_required = sum(
        1 for field in REQUIRED_FIELDS
        if briefing_data.get(field) not in (None, [], "", 0)
    )
    
    # Se todos os obrigatórios estiverem preenchidos, temos pelo menos 80%
    # Os outros 20% vêm dos campos opcionais
    base_pct = (filled_required / total_required) * 80
    
    total_optional = len(OPTIONAL_FIELDS)
    filled_optional = sum(
        1 for field in OPTIONAL_FIELDS
        if briefing_data.get(field) not in (None, [], "", 0)
    )
    
    extra_pct = (filled_optional / total_optional) * 20 if total_optional > 0 else 0
    
    return min(100, round(base_pct + extra_pct))


# Pydantic schemas

class BriefingExtracted(BaseModel):
    """Schema para Structured Outputs API — extração automática pela IA."""
    destino: Optional[str] = Field(None, description="Cidade, país ou região de destino. Extraia APENAS se mencionado explicitamente pelo cliente.")
    data_ida: Optional[date] = Field(None, description="Data de início da viagem (YYYY-MM-DD). Extraia APENAS se houver uma data ou mês/ano claro. NÃO infira.")
    data_volta: Optional[date] = Field(None, description="Data de retorno da viagem (YYYY-MM-DD). Extraia APENAS se mencionada explicitamente.")
    qtd_pessoas: Optional[int] = Field(None, description="Número total de passageiros (adultos + crianças).")
    perfil: Optional[PerfilViagem] = Field(None, description="Composição do grupo: casal, família, solo, grupo ou amigos.")
    tipo_viagem: list[str] = Field(default_factory=list, description="Estilo da viagem: aventura, luxo, romântica, gastronômica, etc.")
    preferencias: list[str] = Field(default_factory=list, description="Interesses específicos: praias, museus, compras, resorts, neve, etc.")
    orcamento: Optional[OrcamentoNivel] = Field(None, description="Nível de investimento: baixo (econômico), médio (padrão), alto (conforto) ou premium (luxo).")
    tem_passaporte: Optional[bool] = Field(None, description="True se o cliente confirmou que possui passaporte válido, False se disse que não tem.")
    observacoes: Optional[str] = Field(None, description="Notas adicionais, restrições alimentares, celebrações ou pedidos especiais.")


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

    model_config = {"from_attributes": True}
