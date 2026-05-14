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
