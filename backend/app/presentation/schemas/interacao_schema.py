import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.domain.entities.enums import TipoMensagem


class InteracaoResponse(BaseModel):
    id: uuid.UUID
    mensagem_cliente: Optional[str]
    mensagem_ia: Optional[str]
    tipo_mensagem: TipoMensagem
    timestamp: datetime

    model_config = {"from_attributes": True}


class InteracaoListResponse(BaseModel):
    items: list[InteracaoResponse]
    total: int
