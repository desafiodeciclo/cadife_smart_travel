"""
ConversationSummary ORM Table — Infrastructure/Persistence Layer
================================================================
Stores AI-generated structured summaries of AYA conversation sessions
(feat-conversation-summary-001).

A "session" is a contiguous block of messages with < 30-minute gaps between them.
One row is created per session — so a lead can accumulate multiple summaries over time.

Schema decisions:
- resumo_json (JSONB): structured topics dict so the prompt output shape can evolve
  without requiring a schema migration.
- sessao_id (VARCHAR 64): opaque bucket key derived from the session's last message
  timestamp, e.g. "{lead_id}:{YYYYMMDD_HHMM}".
- resumo_pendente (BOOLEAN): fallback flag set True when LLM generation fails; the
  retry cron job watches for pending rows and reattempts generation.
- tokens_utilizados (INTEGER): LLM token cost per summary for billing/cost control.
"""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, Integer, String, func, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.persistence.database import Base

if TYPE_CHECKING:
    from app.infrastructure.persistence.models.lead_model import LeadModel


class ConversationSummaryModel(Base):
    __tablename__ = "conversation_summaries"

    __table_args__ = (
        Index("ix_conv_summaries_lead_gerado_em", "lead_id", "gerado_em"),
        Index("ix_conv_summaries_pendente", "resumo_pendente"),
        {"extend_existing": True},
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
    sessao_id: Mapped[str] = mapped_column(String(64), nullable=False)
    resumo_json: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    resumo_pendente: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    gerado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    tokens_utilizados: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    lead: Mapped["LeadModel"] = relationship(
        "LeadModel", back_populates="conversation_summaries"
    )
