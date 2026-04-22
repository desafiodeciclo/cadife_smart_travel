import uuid
from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING, Optional

from sqlalchemy import DateTime, ForeignKey, Numeric, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from pydantic import BaseModel

from app.core.database import Base
from app.domain.entities.enums import PropostaStatus

if TYPE_CHECKING:
    from app.models.lead import Lead


class Proposta(Base):
    __tablename__ = "propostas"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    lead_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("leads.id"), nullable=False, index=True)
    descricao: Mapped[str] = mapped_column(Text, nullable=False)
    valor_estimado: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    status: Mapped[PropostaStatus] = mapped_column(String(20), nullable=False, default=PropostaStatus.rascunho)
    consultor_id: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    lead: Mapped["Lead"] = relationship("Lead", back_populates="propostas")


class PropostaCreate(BaseModel):
    lead_id: uuid.UUID
    descricao: str
    valor_estimado: Optional[Decimal] = None


class PropostaUpdate(BaseModel):
    status: Optional[PropostaStatus] = None
    descricao: Optional[str] = None
    valor_estimado: Optional[Decimal] = None


class PropostaResponse(BaseModel):
    id: uuid.UUID
    lead_id: uuid.UUID
    descricao: str
    valor_estimado: Optional[Decimal]
    status: PropostaStatus
    consultor_id: Optional[uuid.UUID]
    criado_em: datetime

    model_config = {"from_attributes": True}
