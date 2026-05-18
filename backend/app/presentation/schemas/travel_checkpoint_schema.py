import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.domain.entities.enums import TravelCheckpoint


class TravelCheckpointCreate(BaseModel):
    lead_id: uuid.UUID
    checkpoint: TravelCheckpoint
    ativado_por: str


class TravelCheckpointResponse(BaseModel):
    id: uuid.UUID
    lead_id: uuid.UUID
    checkpoint: TravelCheckpoint
    ativado_em: datetime
    ativado_por: str

    model_config = ConfigDict(from_attributes=True)


class TravelCheckpointListResponse(BaseModel):
    items: list[TravelCheckpointResponse]
    total: int
