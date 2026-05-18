import uuid
from datetime import date
from typing import TYPE_CHECKING, Optional
from sqlalchemy import Boolean, Date, Enum as SAEnum, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.persistence.types import GUID, StringArray
from app.core.database import Base
from app.domain.entities.enums import PerfilViagem, OrcamentoPerfil as OrcamentoNivel

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

    lead: Mapped["Lead"] = relationship("Lead", back_populates="briefing")
