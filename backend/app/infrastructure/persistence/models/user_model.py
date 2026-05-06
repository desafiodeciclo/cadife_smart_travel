"""
UserModel ORM — Infrastructure/Persistence Layer
=================================================
SQLAlchemy mapped model for the 'users' table.
Added here so Alembic autogenerate detects the table and migrations
referencing 'users.id' via FK can resolve the table at migration time.
"""
import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, Enum as SAEnum, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.database import Base
from app.infrastructure.persistence.types import GUID, StringArray


class UserModel(Base):
    __tablename__ = "users"
    __table_args__ = {'extend_existing': True}

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    nome: Mapped[str] = mapped_column(String(255), nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    perfil: Mapped[str] = mapped_column(String(20), nullable=False, server_default="agencia")
    telefone: Mapped[Optional[str]] = mapped_column(String(20))
    fcm_token: Mapped[Optional[str]] = mapped_column(String(500))
    avatar_url: Mapped[Optional[str]] = mapped_column(String(500))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    tipo_viagem: Mapped[Optional[list]] = mapped_column(StringArray())
    preferencias: Mapped[Optional[list]] = mapped_column(StringArray())
    tem_passaporte: Mapped[Optional[bool]] = mapped_column(Boolean)
