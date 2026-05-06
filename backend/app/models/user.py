import uuid
from datetime import datetime
from enum import Enum
from typing import Optional

from sqlalchemy import Boolean, DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column
from pydantic import BaseModel, Field

from app.core.database import Base
from app.infrastructure.persistence.types import GUID, StringArray


class UserPerfil(str, Enum):
    agencia = "agencia"
    cliente = "cliente"
    consultor = "consultor"
    admin = "admin"


class User(Base):
    __tablename__ = "users"
    __table_args__ = {'extend_existing': True}

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    nome: Mapped[str] = mapped_column(String(255), nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    perfil: Mapped[UserPerfil] = mapped_column(String(20), nullable=False, default=UserPerfil.agencia)
    telefone: Mapped[Optional[str]] = mapped_column(String(20))
    fcm_token: Mapped[Optional[str]] = mapped_column(String(500))
    avatar_url: Mapped[Optional[str]] = mapped_column(String(500))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    # Preferências de viagem do cliente
    tipo_viagem: Mapped[Optional[list[str]]] = mapped_column(StringArray())
    preferencias: Mapped[Optional[list[str]]] = mapped_column(StringArray())
    tem_passaporte: Mapped[Optional[bool]] = mapped_column(Boolean)


# Pydantic schemas

class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int = 3600


class RefreshRequest(BaseModel):
    refresh_token: str


class UserResponse(BaseModel):
    id: uuid.UUID
    email: str
    nome: str
    perfil: UserPerfil
    telefone: Optional[str]
    avatar_url: Optional[str]
    is_active: bool
    criado_em: datetime
    tipo_viagem: Optional[list[str]]
    preferencias: Optional[list[str]]
    tem_passaporte: Optional[bool]

    model_config = {"from_attributes": True}


class UserProfileUpdate(BaseModel):
    nome: Optional[str] = None
    tipo_viagem: Optional[list[str]] = None
    preferencias: Optional[list[str]] = None
    tem_passaporte: Optional[bool] = None


class FcmTokenRequest(BaseModel):
    fcm_token: str
