from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.domain.entities.enums import TravelCheckpoint


class CheckpointActivateRequest(BaseModel):
    checkpoint: TravelCheckpoint


class CheckpointResponse(BaseModel):
    checkpoint: TravelCheckpoint
    ativado_em: datetime
    ativado_por: str

    model_config = {"from_attributes": True}


class CheckpointListResponse(BaseModel):
    checkpoints: list[CheckpointResponse]
    total: int
