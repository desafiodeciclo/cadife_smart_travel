"""
Diary Schemas — Presentation Layer
==================================
Pydantic schemas for the Travel Diary feature.
Includes validation for entry notes and data responses.
"""

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, HttpUrl


class DiaryEntryBase(BaseModel):
    """Base fields for a diary entry."""
    nota: Optional[str] = Field(
        None, 
        max_length=280, 
        description="Nota de texto da memória (máx. 280 caracteres)"
    )
    data_entrada: Optional[datetime] = Field(
        default_factory=datetime.now,
        description="Data em que a memória ocorreu"
    )


class DiaryEntryCreate(DiaryEntryBase):
    """Schema for creating a new diary entry. Photo is handled via UploadFile."""
    pass


class DiaryEntryRead(DiaryEntryBase):
    """Schema for reading a diary entry."""
    id: uuid.UUID
    lead_id: uuid.UUID
    user_id: uuid.UUID
    foto_url: str
    thumb_url: str
    criado_em: datetime

    model_config = ConfigDict(from_attributes=True)


class DiaryEntryList(BaseModel):
    """Schema for paginated diary entries."""
    entries: list[DiaryEntryRead]
    total: int
    page: int
    size: int
