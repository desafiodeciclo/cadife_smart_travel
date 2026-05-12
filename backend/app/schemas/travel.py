from pydantic import BaseModel
from datetime import datetime
from enum import Enum
from typing import Optional

class TravelStatus(str, Enum):
    UPCOMING = "upcoming"
    ONGOING = "ongoing"
    COMPLETED = "completed"

class TravelResponse(BaseModel):
    id: str
    user_id: str
    destination: str
    start_date: datetime
    end_date: datetime
    status: TravelStatus
    image_url: Optional[str] = None
    description: Optional[str] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "id": "607f1f77bcf86cd799439011",
                "user_id": "507f1f77bcf86cd799439012",
                "destination": "Salvador, Bahia",
                "start_date": "2026-07-15T00:00:00Z",
                "end_date": "2026-07-22T00:00:00Z",
                "status": "upcoming",
                "image_url": "https://...",
                "description": "Viagem de luxo em Salvador"
            }
        }

class TravelListResponse(BaseModel):
    travels: list[TravelResponse]
    count: int
