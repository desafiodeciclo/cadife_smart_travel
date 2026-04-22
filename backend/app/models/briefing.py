import uuid
from datetime import date
from typing import TYPE_CHECKING, Optional

from sqlalchemy import Boolean, Date, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from pydantic import BaseModel, Field

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

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    lead_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("leads.id"), unique=True, nullable=False)
    destino: Mapped[Optional[str]] = mapped_column(String(255))
    origem: Mapped[Optional[str]] = mapped_column(String(255))
    data_ida: Mapped[Optional[date]] = mapped_column(Date)
    data_volta: Mapped[Optional[date]] = mapped_column(Date)
    duracao_dias: Mapped[Optional[int]] = mapped_column(Integer)
    qtd_pessoas: Mapped[Optional[int]] = mapped_column(Integer)
    perfil: Mapped[Optional[str]] = mapped_column(String(50))
    tipo_viagem: Mapped[Optional[list[str]]] = mapped_column(ARRAY(String))
    preferencias: Mapped[Optional[list[str]]] = mapped_column(ARRAY(String))
    orcamento: Mapped[Optional[str]] = mapped_column(String(20))
    tem_passaporte: Mapped[Optional[bool]] = mapped_column(Boolean)
    observacoes: Mapped[Optional[str]] = mapped_column(Text)
    completude_pct: Mapped[int] = mapped_column(Integer, default=0)

    lead: Mapped["Lead"] = relationship("Lead", back_populates="briefing")


def calculate_completude(briefing_data: dict) -> int:
    filled = sum(
        1 for field in BRIEFING_FIELDS
        if briefing_data.get(field) not in (None, [], "", 0)
    )
    return round((filled / len(BRIEFING_FIELDS)) * 100)


# Pydantic schemas

class BriefingExtracted(BaseModel):
    """Schema para PydanticOutputParser — extração automática pela IA."""
    destino: Optional[str] = None
    data_ida: Optional[date] = None
    data_volta: Optional[date] = None
    qtd_pessoas: Optional[int] = None
    perfil: Optional[PerfilViagem] = None
    tipo_viagem: list[str] = Field(default_factory=list)
    preferencias: list[str] = Field(default_factory=list)
    orcamento: Optional[OrcamentoNivel] = None
    tem_passaporte: Optional[bool] = None
    observacoes: Optional[str] = None
    completude_pct: int = 0


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
