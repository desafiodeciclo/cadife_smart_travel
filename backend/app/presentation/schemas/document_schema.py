from enum import Enum
from typing import Optional, List
from datetime import datetime
import uuid
from pydantic import BaseModel, ConfigDict


class DocumentType(str, Enum):
    passport = "passport"
    visa = "visa"
    ticket = "ticket"
    insurance = "insurance"
    voucher = "voucher"
    itinerary = "itinerary"
    other = "other"


class DocumentResponse(BaseModel):
    id: uuid.UUID
    travel_id: uuid.UUID
    name: str
    document_type: DocumentType
    file_url: Optional[str] = None
    uploaded_at: datetime

    model_config = ConfigDict(from_attributes=True)


class DocumentsListResponse(BaseModel):
    items: List[DocumentResponse]
    total: int
