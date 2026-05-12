from pydantic import BaseModel
from datetime import datetime
from enum import Enum
from typing import Optional, List

class LeadStatus(str, Enum):
    NOVO = "novo"
    EM_ATENDIMENTO = "em_atendimento"
    QUALIFICADO = "qualificado"
    PERDIDO = "perdido"

class LeadResponse(BaseModel):
    id: str
    name: str
    email: str
    destination: str  # destino principal
    status: LeadStatus
    score: float  # 0-100
    created_at: datetime

    class Config:
        from_attributes = True
        json_schema_extra = {
            "example": {
                "id": "507f1f77bcf86cd799439011",
                "name": "Maria Silva",
                "email": "maria@email.com",
                "destination": "Salvador, BA",
                "status": "qualificado",
                "score": 75.5,
                "created_at": "2026-05-01T10:30:00Z"
            }
        }

class LeadsListResponse(BaseModel):
    leads: List[LeadResponse]
    total: int
    page: int
    pages: int

    class Config:
        from_attributes = True
