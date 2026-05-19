import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class NotificationQueueCreate(BaseModel):
    lead_id: uuid.UUID
    status: str = "pending"
    payload: dict = {}
    retry_delay_seconds: int = 60
    max_retries: int = 3


class NotificationQueueResponse(BaseModel):
    id: uuid.UUID
    lead_id: uuid.UUID
    status: str
    retry_count: int
    max_retries: int
    retry_delay_seconds: int
    next_retry_at: Optional[datetime] = None
    payload: dict
    error_log: Optional[str] = None
    processing_started_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class NotificationQueueListResponse(BaseModel):
    items: list[NotificationQueueResponse]
    total: int
