import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class LeadOfferCreate(BaseModel):
    offer_id: uuid.UUID
    client_id: uuid.UUID
    lead_id: uuid.UUID
    agency_id: uuid.UUID


class LeadOfferResponse(BaseModel):
    id: uuid.UUID
    offer_id: uuid.UUID
    client_id: uuid.UUID
    lead_id: uuid.UUID
    agency_id: uuid.UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class LeadOfferListResponse(BaseModel):
    items: list[LeadOfferResponse]
    total: int
