import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict

from app.domain.entities.enums import UserPerfil


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
    bio: Optional[str] = None
    is_active: bool
    criado_em: datetime
    tipo_viagem: Optional[list[str]]
    preferencias: Optional[list[str]]
    tem_passaporte: Optional[bool]

    model_config = ConfigDict(from_attributes=True)


class UserProfileUpdate(BaseModel):
    nome: Optional[str] = None
    tipo_viagem: Optional[list[str]] = None
    preferencias: Optional[list[str]] = None
    tem_passaporte: Optional[bool] = None


class FcmTokenRequest(BaseModel):
    fcm_token: str


class FcmTokenResponse(BaseModel):
    message: str
