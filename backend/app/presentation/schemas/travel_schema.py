from enum import Enum
from typing import Optional, List
from datetime import datetime
import uuid
from pydantic import BaseModel, Field, ConfigDict


class TravelStatus(str, Enum):
    upcoming = "upcoming"
    ongoing = "ongoing"
    completed = "completed"
    cancelled = "cancelled"


class TravelResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    destination: str
    start_date: datetime
    end_date: Optional[datetime] = None
    status: TravelStatus
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class TravelListResponse(BaseModel):
    items: List[TravelResponse]
    total: int
