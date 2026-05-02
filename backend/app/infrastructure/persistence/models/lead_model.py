"""
Lead ORM Table — Infrastructure/Persistence Layer
==================================================
SQLAlchemy mapped model for the 'leads' table.
Includes DB-level constraints (CheckConstraint, Enum) and composite indexes
for the most frequent query patterns in the CRM dashboard.

Changes from previous app/models/lead.py:
  - Imports Base from infrastructure.persistence (canonical location)
  - PostgreSQL native ENUM types via SAEnum for constraint at DB level
  - Composite index (status, criado_em) for dashboard list queries
  - Composite index (consultor_id, status) for per-consultant views
  - telefone/nome enlarged to String(512) for Fernet ciphertext (migration a1b2c3d4e5f6)
  - telefone_hash String(64) for deterministic HMAC-SHA256 lookups (migration b2c3d4e5f6a1)
"""
import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Index,
    String,
    func,
)
from sqlalchemy.dialects.postgresql import ENUM as SAEnum, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.domain.entities.enums import LeadOrigem, LeadScore, LeadStatus
from app.infrastructure.persistence.database import Base

if TYPE_CHECKING:
    from app.infrastructure.persistence.models.briefing_model import BriefingModel
    from app.infrastructure.persistence.models.interacao_model import InteracaoModel
    from app.infrastructure.persistence.models.agendamento_model import AgendamentoModel
    from app.infrastructure.persistence.models.proposta_model import PropostaModel


# PostgreSQL native ENUM types — enforced at DB level, not just application level
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
        # Composite index: CRM dashboard queries by status + date (most frequent)
        Index("ix_leads_status_criado_em", "status", "criado_em"),
        # Composite index: consultant view queries
        Index("ix_leads_consultor_status", "consultor_id", "status"),
        # Note: ck_leads_telefone_min_length was dropped in migration a1b2c3d4e5f6
        # (meaningless after Fernet encryption of telefone field)
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    nome: Mapped[Optional[str]] = mapped_column(String(512))
    telefone: Mapped[str] = mapped_column(
        String(512), unique=True, nullable=False, index=True
    )
    telefone_hash: Mapped[Optional[str]] = mapped_column(String(64), nullable=True, index=True)
    origem: Mapped[str] = mapped_column(
        lead_origem_enum, nullable=False, default=LeadOrigem.whatsapp.value
    )
    status: Mapped[str] = mapped_column(
        lead_status_enum, nullable=False, default=LeadStatus.novo.value
    )
    score: Mapped[Optional[str]] = mapped_column(lead_score_enum)
    consultor_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL")
    )
    is_archived: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    atualizado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships — lazy loaded by default for async safety
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
