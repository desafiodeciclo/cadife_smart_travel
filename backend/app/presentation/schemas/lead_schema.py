from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field
import uuid
from app.domain.entities.enums import LeadOrigem, LeadStatus, LeadScore
from app.presentation.schemas.briefing_schema import BriefingSchema

class LeadBaseSchema(BaseModel):
    nome: Optional[str] = Field(None, min_length=2, max_length=255)
    telefone: str = Field(..., pattern=r"^\+[1-9]\d{7,14}$") # E.164 format (ex: +5511...)
    origem: LeadOrigem = LeadOrigem.whatsapp

class LeadCreateSchema(LeadBaseSchema):
    pass

class LeadUpdateSchema(BaseModel):
    nome: Optional[str] = None
    status: Optional[LeadStatus] = None
    score: Optional[LeadScore] = None
    consultor_id: Optional[uuid.UUID] = None
    is_archived: Optional[bool] = None

class LeadResponseSchema(LeadBaseSchema):
    id: uuid.UUID
    status: LeadStatus
    score: Optional[LeadScore]
    consultor_id: Optional[uuid.UUID]
    is_archived: bool
    criado_em: datetime
    atualizado_em: datetime
    briefing: Optional[BriefingSchema] = None
    completude_pct: Optional[int] = None

    model_config = {"from_attributes": True}
