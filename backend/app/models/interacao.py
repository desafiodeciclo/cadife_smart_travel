import uuid
from datetime import datetime
from enum import Enum
from typing import TYPE_CHECKING, Optional


from sqlalchemy import DateTime, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from pydantic import BaseModel

from app.core.database import Base
from app.domain.entities.enums import TipoMensagem

if TYPE_CHECKING:
    from app.models.lead import Lead


class Interacao(Base):
    __tablename__ = "interacoes"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    lead_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("leads.id"), nullable=False, index=True)
    mensagem_cliente: Mapped[Optional[str]] = mapped_column(Text)
    mensagem_ia: Mapped[Optional[str]] = mapped_column(Text)
    tipo_mensagem: Mapped[TipoMensagem] = mapped_column(String(20), nullable=False, default=TipoMensagem.texto)
    timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    lead: Mapped["Lead"] = relationship("Lead", back_populates="interacoes")



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
