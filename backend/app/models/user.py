import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.domain.entities.enums import UserPerfil
from app.infrastructure.persistence.types import GUID, StringArray


class User(Base):
    __tablename__ = "users"
    __table_args__ = {"extend_existing": True}

    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(
        String(255), unique=True, nullable=False, index=True
    )
    nome: Mapped[str] = mapped_column(String(255), nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    perfil: Mapped[UserPerfil] = mapped_column(
        String(20), nullable=False, default=UserPerfil.agencia
    )
    telefone: Mapped[Optional[str]] = mapped_column(String(20))
    fcm_token: Mapped[Optional[str]] = mapped_column(String(500))
    avatar_url: Mapped[Optional[str]] = mapped_column(String(500))
    bio: Mapped[Optional[str]] = mapped_column(String(500))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    # Preferências de viagem do cliente
    tipo_viagem: Mapped[Optional[list[str]]] = mapped_column(StringArray())
    preferencias: Mapped[Optional[list[str]]] = mapped_column(StringArray())
    tem_passaporte: Mapped[Optional[bool]] = mapped_column(Boolean)
