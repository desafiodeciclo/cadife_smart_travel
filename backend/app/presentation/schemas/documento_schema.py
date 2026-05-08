import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.domain.entities.enums import DocumentoCategoria

class DocumentoBase(BaseModel):
    nome: str
    categoria: DocumentoCategoria

class DocumentoCreate(DocumentoBase):
    pass

class DocumentoResponse(DocumentoBase):
    id: uuid.UUID
    lead_id: uuid.UUID
    tamanho_bytes: int
    mimetype: str
    url_signed: Optional[str] = None
    criado_em: datetime
    enviado_por: Optional[uuid.UUID] = None

    model_config = ConfigDict(from_attributes=True)
