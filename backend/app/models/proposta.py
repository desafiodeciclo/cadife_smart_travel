import uuid
from app.infrastructure.persistence.types import GUID
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING, Optional

from sqlalchemy import JSON, DateTime, ForeignKey, Integer, Numeric, String, Text, func
from sqlalchemy.dialects.postgresql import ENUM as PgEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.domain.entities.enums import PropostaStatus

if TYPE_CHECKING:
    from app.models.lead import Lead


class Proposta(Base):
    __tablename__ = "propostas"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("leads.id", ondelete="CASCADE"), nullable=False, index=True
    )
    descricao: Mapped[str] = mapped_column(Text, nullable=False)
    valor_estimado: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    status: Mapped[PropostaStatus] = mapped_column(
        PgEnum(PropostaStatus, name="proposta_status_enum", create_type=False),
        nullable=False,
        default=PropostaStatus.rascunho,
    )
    consultor_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    expiration_hours: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default="48"
    )
    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    enviado_em: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    notificacao_enviada_em: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    deletado_em: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    deletado_por: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(),
        ForeignKey("users.id"),
        nullable=True,
    )

    lead: Mapped["Lead"] = relationship("Lead", back_populates="propostas")


class PropostaVersao(Base):
    """Append-only snapshot of a proposta at a moment in time (gap §3.4.4)."""

    __tablename__ = "proposta_versoes"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    proposta_id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        ForeignKey("propostas.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    numero_versao: Mapped[int] = mapped_column(Integer, nullable=False)
    snapshot_json: Mapped[dict] = mapped_column(JSON, nullable=False)
    motivo: Mapped[str] = mapped_column(String(50), nullable=False)
    created_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(), ForeignKey("users.id"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
