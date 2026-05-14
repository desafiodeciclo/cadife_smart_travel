"""
Lead ORM Table — Infrastructure/Persistence Layer
==================================================
SQLAlchemy mapped model for the 'leads' table.
Includes DB-level constraints (CheckConstraint, Enum) and composite indexes
for the most frequent query patterns in the CRM dashboard.
"""

import uuid
from app.infrastructure.persistence.types import GUID
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    func,
)
from sqlalchemy.dialects.postgresql import ENUM as SAEnum, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.domain.entities.enums import LeadOrigem, LeadScore, LeadStatus
from app.infrastructure.persistence.database import Base
from app.infrastructure.security.pii_encryption import EncryptedString

if TYPE_CHECKING:
    from app.infrastructure.persistence.models.briefing_model import BriefingModel
    from app.infrastructure.persistence.models.interacao_model import InteracaoModel
    from app.infrastructure.persistence.models.agendamento_model import AgendamentoModel
    from app.infrastructure.persistence.models.proposta_model import PropostaModel
    from app.infrastructure.persistence.models.suitcase_model import SuitcaseItemModel
    from app.infrastructure.persistence.models.travel_diary_model import TravelDiaryEntryModel
    # --- Imports Unificados ---
    from app.infrastructure.persistence.models.aya_toggle_history_model import AyaToggleHistoryModel
    from app.infrastructure.persistence.models.itinerary_model import ItineraryItemModel
    from app.infrastructure.persistence.models.conversation_summary_model import ConversationSummaryModel
    from app.infrastructure.persistence.models.lead_score_history_model import LeadScoreHistoryModel


# PostgreSQL native ENUM types
lead_status_enum = SAEnum(
    *[e.value for e in LeadStatus],
    name="lead_status_enum",
    create_type=True,
)
lead_score_enum = SAEnum(
    *[e.value for e in LeadScore],
    name="lead_score_enum",
    create_type=True,
)
lead_origem_enum = SAEnum(
    *[e.value for e in LeadOrigem],
    name="lead_origem_enum",
    create_type=True,
)


class LeadModel(Base):
    """
    ORM representation of a sales lead (spec.md §4.1).
    This class ONLY lives in the Infrastructure layer.
    """

    __tablename__ = "leads"

    __table_args__ = (
        Index("ix_leads_status_criado_em", "status", "criado_em"),
        Index("ix_leads_consultor_status", "consultor_id", "status"),
        {"extend_existing": True},
    )

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    nome: Mapped[Optional[str]] = mapped_column(EncryptedString(512))
    telefone: Mapped[str] = mapped_column(
        EncryptedString(512), unique=True, nullable=False, index=True
    )
    telefone_hash: Mapped[Optional[str]] = mapped_column(
        String(64), nullable=True, index=True
    )
    origem: Mapped[str] = mapped_column(
        lead_origem_enum, nullable=False, default=LeadOrigem.whatsapp.value
    )
    status: Mapped[str] = mapped_column(
        lead_status_enum, nullable=False, default=LeadStatus.novo.value
    )
    score: Mapped[Optional[str]] = mapped_column(lead_score_enum)
    score_numerico: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    score_calculado_em: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    consultor_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(), ForeignKey("users.id", ondelete="SET NULL")
    )
    client_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    offer_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(), ForeignKey("offers.id", ondelete="SET NULL"), nullable=True
    )
    budget: Mapped[Optional[Numeric]] = mapped_column(Numeric(12, 2), nullable=True)
    aya_ativo: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False, server_default="true")
    is_archived: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    deletado_em: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    atualizado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # --- Relationships ---
    briefing: Mapped[Optional["BriefingModel"]] = relationship(
        "BriefingModel", back_populates="lead", uselist=False, lazy="select"
    )
    interacoes: Mapped[list["InteracaoModel"]] = relationship(
        "InteracaoModel", back_populates="lead", lazy="select"
    )
    agendamentos: Mapped[list["AgendamentoModel"]] = relationship(
        "AgendamentoModel", back_populates="lead", lazy="select"
    )
    propostas: Mapped[list["PropostaModel"]] = relationship(
        "PropostaModel", back_populates="lead", lazy="select"
    )
    suitcase_items: Mapped[list["SuitcaseItemModel"]] = relationship(
        "SuitcaseItemModel", back_populates="lead", lazy="select"
    )
    diary_entries: Mapped[list["TravelDiaryEntryModel"]] = relationship(
        "TravelDiaryEntryModel", back_populates="lead", lazy="select", cascade="all, delete-orphan"
    )
    
    # Adicionado pela branch de Fluxo de Registro
    itinerary_items: Mapped[list["ItineraryItemModel"]] = relationship(
        "ItineraryItemModel", back_populates="lead", lazy="select", cascade="all, delete-orphan",
        order_by="ItineraryItemModel.horario_inicio",
    )
    conversation_summaries: Mapped[list["ConversationSummaryModel"]] = relationship(
        "ConversationSummaryModel", back_populates="lead", lazy="select", cascade="all, delete-orphan"
    )

    # Adicionado pela branch Developer
    aya_toggle_history: Mapped[list["AyaToggleHistoryModel"]] = relationship(
        "AyaToggleHistoryModel", back_populates="lead", lazy="select", cascade="all, delete-orphan"
    )
    score_history: Mapped[list["LeadScoreHistoryModel"]] = relationship(
        "LeadScoreHistoryModel",
        back_populates="lead",
        lazy="select",
        order_by="LeadScoreHistoryModel.criado_em.desc()",
    )