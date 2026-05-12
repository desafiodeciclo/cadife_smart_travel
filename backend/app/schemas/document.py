from pydantic import BaseModel
from datetime import datetime
from enum import Enum

class DocumentType(str, Enum):
    PDF = "pdf"
    IMAGE = "image"
    OTHER = "other"

class DocumentResponse(BaseModel):
    id: str
    travel_id: str
    name: str
    type: DocumentType
    size_kb: int
    url: str
    uploaded_at: datetime
    
    class Config:
        json_schema_extra = {
            "example": {
                "id": "607f1f77bcf86cd799439011",
                "travel_id": "607f1f77bcf86cd799439010",
                "name": "Passagem_Aerea_GRU_SSA.pdf",
                "type": "pdf",
                "size_kb": 256,
                "url": "https://s3.amazonaws.com/...",
                "uploaded_at": "2026-05-01T10:30:00Z"
            }
        }

class DocumentsListResponse(BaseModel):
    documents: list[DocumentResponse]
    count: int
