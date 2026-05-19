"""
AgencySettings + MessageTemplate ORM — Infrastructure/Persistence Layer
========================================================================
Singleton-style settings (one row per agency_id) plus reusable message
templates with placeholder whitelist (validated at the service layer).

See PRD `docs/prd/PRD-agency-settings-and-consultor-profile.md`.
"""

import uuid
from app.infrastructure.persistence.types import GUID
from datetime import datetime
from typing import Optional

from sqlalchemy import (
    JSON,
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.database import Base


SINGLETON_AGENCY_ID = uuid.UUID("00000000-0000-0000-0000-000000000001")


class AgencySettingsModel(Base):
    """One row per agency_id (singleton today). Stores hours + notification prefs as JSON."""

    __tablename__ = "agency_settings"
    __table_args__ = (
        UniqueConstraint("agency_id", name="uq_agency_settings_agency"),
        {"extend_existing": True},
    )

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    agency_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), nullable=False, default=SINGLETON_AGENCY_ID
    )
    horario_funcionamento: Mapped[dict] = mapped_column(JSON, nullable=False)
    notificacoes_prefs: Mapped[dict] = mapped_column(JSON, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )


class MessageTemplateModel(Base):
    """Reusable message template with placeholders like {{nome}}, {{destino}}."""

    __tablename__ = "message_templates"
    __table_args__ = (
        CheckConstraint(
            "categoria IN ('boas_vindas','lembrete','pos_curadoria','follow_up','proposta','outro')",
            name="ck_template_categoria",
        ),
        Index(
            "idx_templates_active",
            "agency_id",
            "categoria",
            postgresql_where="deletado_em IS NULL",
        ),
        {"extend_existing": True},
    )

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    agency_id: Mapped[uuid.UUID] = mapped_column(
        GUID(), nullable=False, default=SINGLETON_AGENCY_ID
    )
    nome: Mapped[str] = mapped_column(String(100), nullable=False)
    categoria: Mapped[str] = mapped_column(String(50), nullable=False)
    conteudo: Mapped[str] = mapped_column(Text, nullable=False)
    variaveis: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    ativo: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    created_by: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    deletado_em: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
