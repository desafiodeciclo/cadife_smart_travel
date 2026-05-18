import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class ScoreHistoryItem(BaseModel):
    id: uuid.UUID
    score_numerico: int
    score_label: str
    motivo: Optional[str]
    criterios_json: Optional[str]
    criado_em: datetime

    model_config = ConfigDict(from_attributes=True)


class ScoreHistoryResponse(BaseModel):
    items: list[ScoreHistoryItem]
    total: int
    lead_id: uuid.UUID
