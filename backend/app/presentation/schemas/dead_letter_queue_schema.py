import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class DeadLetterQueueCreate(BaseModel):
    lead_id: uuid.UUID
    original_payload: dict = {}
    error_trace: str
    retry_count_exhausted: int = 0


class DeadLetterQueueResponse(BaseModel):
    id: uuid.UUID
    lead_id: uuid.UUID
    original_payload: dict
    error_trace: str
    retry_count_exhausted: int
    failed_at: datetime

    model_config = ConfigDict(from_attributes=True)


class DeadLetterQueueListResponse(BaseModel):
    items: list[DeadLetterQueueResponse]
    total: int
