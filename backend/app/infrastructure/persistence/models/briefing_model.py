"""
Briefing ORM Table — Infrastructure/Persistence Layer
=====================================================
SQLAlchemy model for the 'briefings' table (spec.md §4.2).
One-to-one with Lead (unique FK).

Constraints:
  - completude_pct: DB CHECK 0–100
  - qtd_pessoas: DB CHECK >= 1
  - duracao_dias: DB CHECK >= 1
  - PostgreSQL native ENUM for perfil and orcamento fields
"""
import uuid
from datetime import date
from typing import TYPE_CHECKING, Optional

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import ARRAY, ENUM as SAEnum, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.domain.entities.enums import OrcamentoPerfil, PerfilViagem
from app.infrastructure.persistence.database import Base

if TYPE_CHECKING:
    from app.infrastructure.persistence.models.lead_model import LeadModel


perfil_viagem_enum = SAEnum(
    *[e.value for e in PerfilViagem],
    name="perfil_viagem_enum",
    create_type=True,
)
orcamento_perfil_enum = SAEnum(
    *[e.value for e in OrcamentoPerfil],
    name="orcamento_perfil_enum",
    create_type=True,
)

BRIEFING_REQUIRED_FIELDS = [
    "destino", "data_ida", "data_volta", "qtd_pessoas", "perfil",
    "tipo_viagem", "preferencias", "orcamento", "tem_passaporte",
]


class BriefingModel(Base):
    """
    ORM representation of a travel briefing (spec.md §4.2).
    Linked 1-to-1 with Lead. Populated incrementally by the AI agent.
    """

    __tablename__ = "briefings"

    __table_args__ = (
        CheckConstraint(
            "completude_pct BETWEEN 0 AND 100",
            name="ck_briefings_completude_range",
        ),
        CheckConstraint("qtd_pessoas IS NULL OR qtd_pessoas >= 1", name="ck_briefings_qtd_pessoas_min"),
        CheckConstraint("duracao_dias IS NULL OR duracao_dias >= 1", name="ck_briefings_duracao_min"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("leads.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )
    destino: Mapped[Optional[str]] = mapped_column(String(255))
    origem: Mapped[Optional[str]] = mapped_column(String(255))
    data_ida: Mapped[Optional[date]] = mapped_column(Date)
    data_volta: Mapped[Optional[date]] = mapped_column(Date)
    duracao_dias: Mapped[Optional[int]] = mapped_column(Integer)
    qtd_pessoas: Mapped[Optional[int]] = mapped_column(Integer)
    perfil: Mapped[Optional[str]] = mapped_column(perfil_viagem_enum)
    tipo_viagem: Mapped[Optional[list[str]]] = mapped_column(ARRAY(String))
    preferencias: Mapped[Optional[list[str]]] = mapped_column(ARRAY(String))
    orcamento: Mapped[Optional[str]] = mapped_column(orcamento_perfil_enum)
    tem_passaporte: Mapped[Optional[bool]] = mapped_column(Boolean)
    observacoes: Mapped[Optional[str]] = mapped_column(Text)
    completude_pct: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    lead: Mapped["LeadModel"] = relationship("LeadModel", back_populates="briefing")


def calculate_completude(briefing_data: dict) -> int:
    """Calculate briefing completeness percentage (0–100)."""
    filled = sum(
        1 for field in BRIEFING_REQUIRED_FIELDS
        if briefing_data.get(field) not in (None, [], "", 0)
    )
    return round((filled / len(BRIEFING_REQUIRED_FIELDS)) * 100)
