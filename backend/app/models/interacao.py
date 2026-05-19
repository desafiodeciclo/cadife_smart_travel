import uuid
from pydantic import BaseModel
from app.infrastructure.persistence.types import GUID
from datetime import datetime
from typing import TYPE_CHECKING, Optional


from sqlalchemy import DateTime, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import ENUM as PgEnum, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.domain.entities.enums import TipoMensagem

if TYPE_CHECKING:
    from app.models.lead import Lead


class Interacao(Base):
    __tablename__ = "interacoes"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), ForeignKey("leads.id", ondelete="CASCADE"), nullable=False, index=True
    )
    mensagem_cliente: Mapped[Optional[str]] = mapped_column(Text)
    mensagem_ia: Mapped[Optional[str]] = mapped_column(Text)
    tipo_mensagem: Mapped[TipoMensagem] = mapped_column(
        PgEnum(TipoMensagem, name="tipo_mensagem_enum", create_type=False),
        nullable=False,
        default=TipoMensagem.texto,
    )
    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    # ID único da mensagem vindo da Meta para evitar Replay Attacks
    whatsapp_message_id: Mapped[Optional[str]] = mapped_column(
        String(255), unique=True, nullable=True, index=True
    )

    # Outbound send tracking (spec.md §9.1 — reply back to customer)
    enviado_em: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    status_envio: Mapped[Optional[str]] = mapped_column(
        String(10), nullable=True
    )  # "sent" | "failed"
    erro_envio: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    lead: Mapped["Lead"] = relationship("Lead", back_populates="interacoes", lazy="noload")


class InteracaoResponse(BaseModel):
    id: uuid.UUID
    mensagem_cliente: Optional[str]
    mensagem_ia: Optional[str]
    tipo_mensagem: TipoMensagem
    timestamp: datetime

    model_config = {"from_attributes": True}


class InteracaoListResponse(BaseModel):
    items: list[InteracaoResponse]
    total: int
