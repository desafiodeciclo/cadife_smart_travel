import uuid
from datetime import datetime
from enum import Enum
from typing import TYPE_CHECKING, Optional

if TYPE_CHECKING:
    from app.models.briefing import Briefing
    from app.models.interacao import Interacao
    from app.models.agendamento import Agendamento
    from app.models.proposta import Proposta
from typing import TYPE_CHECKING, Optional

from sqlalchemy import Boolean, DateTime, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from pydantic import BaseModel

from app.core.database import Base
from app.infrastructure.security.pii_encryption import EncryptedString
from app.domain.entities.enums import LeadOrigem, LeadStatus, LeadScore



class Lead(Base):
    __tablename__ = "leads"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    # PII: campos criptografados at-rest via Fernet (AES-128)
    nome: Mapped[Optional[str]] = mapped_column(EncryptedString(512))
    telefone: Mapped[str] = mapped_column(EncryptedString(512), unique=True, nullable=False, index=True)
    origem: Mapped[LeadOrigem] = mapped_column(String(20), nullable=False, default=LeadOrigem.whatsapp)
    status: Mapped[LeadStatus] = mapped_column(String(30), nullable=False, default=LeadStatus.novo)
    score: Mapped[Optional[LeadScore]] = mapped_column(String(10))
    consultor_id: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"))
    is_archived: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    atualizado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    briefing: Mapped[Optional["Briefing"]] = relationship("Briefing", back_populates="lead", uselist=False)
    interacoes: Mapped[list["Interacao"]] = relationship("Interacao", back_populates="lead")
    agendamentos: Mapped[list["Agendamento"]] = relationship("Agendamento", back_populates="lead")
    propostas: Mapped[list["Proposta"]] = relationship("Proposta", back_populates="lead")


# Pydantic schemas

class LeadCreate(BaseModel):
    nome: Optional[str] = None
    telefone: str
    origem: LeadOrigem = LeadOrigem.whatsapp


class LeadUpdate(BaseModel):
    nome: Optional[str] = None
    status: Optional[LeadStatus] = None
    score: Optional[LeadScore] = None
    consultor_id: Optional[uuid.UUID] = None


class LeadResponse(BaseModel):
    id: uuid.UUID
    nome: Optional[str]
    telefone: str
    origem: LeadOrigem
    status: LeadStatus
    score: Optional[LeadScore]
    consultor_id: Optional[uuid.UUID]
    is_archived: bool
    criado_em: datetime
    atualizado_em: datetime

    model_config = {"from_attributes": True}


class LeadListItem(BaseModel):
    id: uuid.UUID
    nome: Optional[str]
    telefone: str
    origem: LeadOrigem
    status: LeadStatus
    score: Optional[LeadScore]
    criado_em: datetime
    atualizado_em: datetime
    completude_pct: Optional[int] = None

    model_config = {"from_attributes": True}


class LeadListResponse(BaseModel):
    items: list[LeadListItem]
    total: int
    page: int
    limit: int
    pages: int
