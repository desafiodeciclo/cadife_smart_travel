from datetime import datetime
from typing import Optional, Dict, List
import uuid

from pydantic import BaseModel, Field, ConfigDict
from app.domain.entities.enums import SuitcaseCategory


class SuitcaseItemBase(BaseModel):
    nome: str = Field(..., min_length=1, max_length=255)
    categoria: SuitcaseCategory = SuitcaseCategory.outros
    quantidade: int = Field(1, ge=1)
    empacotado: bool = False


class SuitcaseItemCreate(SuitcaseItemBase):
    pass


class SuitcaseItemUpdate(BaseModel):
    nome: Optional[str] = Field(None, min_length=1, max_length=255)
    categoria: Optional[SuitcaseCategory] = None
    quantidade: Optional[int] = Field(None, ge=1)
    empacotado: Optional[bool] = None


class SuitcaseItemResponse(SuitcaseItemBase):
    id: uuid.UUID
    lead_id: uuid.UUID
    user_id: uuid.UUID
    criado_em: datetime
    atualizado_em: datetime

    model_config = ConfigDict(from_attributes=True)


class SuitcaseGroupedResponse(BaseModel):
    items_by_category: Dict[SuitcaseCategory, List[SuitcaseItemResponse]]
    total_items: int
    total_packed: int


class SuitcaseSuggestionResponse(BaseModel):
    id: int
    tipo_destino: str
    categoria: SuitcaseCategory
    nome: str
    quantidade_sugerida: int
    descricao: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
