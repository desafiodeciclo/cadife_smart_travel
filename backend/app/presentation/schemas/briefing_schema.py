from datetime import date
from typing import Optional, List
from pydantic import BaseModel, Field, field_validator
import uuid
from app.domain.entities.enums import PerfilViagem, OrcamentoPerfil

class BriefingSchema(BaseModel):
    destino: Optional[str] = Field(None, min_length=2, max_length=255)
    data_ida: Optional[date] = None
    data_volta: Optional[date] = None
    qtd_pessoas: Optional[int] = Field(None, gt=0)
    perfil: Optional[PerfilViagem] = None
    tipo_viagem: List[str] = Field(default_factory=list)
    preferencias: List[str] = Field(default_factory=list)
    orcamento: Optional[OrcamentoPerfil] = None
    tem_passaporte: Optional[bool] = None
    observacoes: Optional[str] = None

    @field_validator("data_volta")
    @classmethod
    def validate_dates(cls, v: Optional[date], info):
        if v and info.data.get("data_ida") and v < info.data["data_ida"]:
            raise ValueError("Data de volta não pode ser anterior à data de ida")
        return v

    model_config = {"from_attributes": True}

class BriefingResponse(BriefingSchema):
    lead_id: uuid.UUID
    completude_pct: int
    duracao_dias: Optional[int] = None
