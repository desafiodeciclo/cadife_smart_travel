"""
Interacao ORM Table — Infrastructure/Persistence Layer
=======================================================
SQLAlchemy model for the 'interacoes' table (spec.md §4.3).
Stores every WhatsApp message exchange between client and AI.

Indexes:
  - (lead_id, timestamp) DESC — for loading conversation history
"""
import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import DateTime, ForeignKey, Index, String, Text, func
from sqlalchemy.dialects.postgresql import ENUM as SAEnum, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.domain.entities.enums import TipoMensagem
from app.infrastructure.persistence.database import Base

if TYPE_CHECKING:
    from app.infrastructure.persistence.models.lead_model import LeadModel


tipo_mensagem_enum = SAEnum(
    *[e.value for e in TipoMensagem],
    name="tipo_mensagem_enum",
    create_type=True,
)


class InteracaoModel(Base):
    """
    ORM representation of a WhatsApp interaction (spec.md §4.3).
    Each row = one exchange (client message + optional AI response).
    """

    __tablename__ = "interacoes"

    __table_args__ = (
        # Composite index: fetch conversation history sorted by time
        Index("ix_interacoes_lead_timestamp", "lead_id", "timestamp"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("leads.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    mensagem_cliente: Mapped[Optional[str]] = mapped_column(Text)
    mensagem_ia: Mapped[Optional[str]] = mapped_column(Text)
    tipo_mensagem: Mapped[str] = mapped_column(
        tipo_mensagem_enum, nullable=False, default=TipoMensagem.texto.value
    )
    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    lead: Mapped["LeadModel"] = relationship("LeadModel", back_populates="interacoes")
