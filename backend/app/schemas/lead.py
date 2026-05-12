<<<<<<< HEAD
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
=======
from enum import Enum
from typing import List, Optional
from datetime import datetime
import uuid
from pydantic import BaseModel, Field, ConfigDict

class LeadStatus(str, Enum):
    """
    Representa os estados possíveis de um Lead no sistema.
    """
    NOVO = "novo"
    EM_QUALIFICACAO = "em_qualificacao"
    QUALIFICADO = "qualificado"
    DESQUALIFICADO = "desqualificado"
    CONVERTIDO = "convertido"
    ARQUIVADO = "arquivado"

class LeadResponse(BaseModel):
    """
    Schema de resposta para detalhes de um Lead.
    """
    id: uuid.UUID
    nome: str
    email: Optional[str] = None
    telefone: str
    status: LeadStatus
    score: float = Field(default=0.0, description="Pontuação de qualificação do lead (0-100)")
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(
        from_attributes=True,
        json_schema_extra={
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "nome": "João Silva",
                "email": "joao.silva@example.com",
                "telefone": "+5511999998888",
                "status": "novo",
                "score": 85.5,
                "created_at": "2024-05-12T10:00:00",
                "updated_at": "2024-05-12T10:30:00"
            }
        }
    )

class LeadsListResponse(BaseModel):
    """
    Schema de resposta para listagem de Leads com suporte a paginação.
    """
    items: List[LeadResponse]
    total: int = Field(..., description="Total de registros encontrados")
    page: int = Field(..., description="Página atual")
    pages: int = Field(..., description="Total de páginas disponível")

    model_config = ConfigDict(
        from_attributes=True,
        json_schema_extra={
            "example": {
                "items": [
                    {
                        "id": "550e8400-e29b-41d4-a716-446655440000",
                        "nome": "João Silva",
                        "email": "joao.silva@example.com",
                        "telefone": "+5511999998888",
                        "status": "novo",
                        "score": 85.5,
                        "created_at": "2024-05-12T10:00:00"
                    }
                ],
                "total": 1,
                "page": 1,
                "pages": 1
            }
        }
    )
>>>>>>> origin/developer
