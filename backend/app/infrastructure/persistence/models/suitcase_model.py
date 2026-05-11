"""
Suitcase ORM Table — Infrastructure/Persistence Layer
=====================================================
SQLAlchemy mapped models for 'suitcase_items' and 'suitcase_suggestions'.
Enforces ownership and category constraints at the DB level.
"""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Integer,
    String,
    func,
)
from sqlalchemy.dialects.postgresql import ENUM as SAEnum, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.domain.entities.enums import SuitcaseCategory, DestinationType
from app.infrastructure.persistence.database import Base

if TYPE_CHECKING:
    from app.infrastructure.persistence.models.lead_model import LeadModel
    from app.infrastructure.persistence.models.user_model import UserModel


# PostgreSQL native ENUM types
suitcase_category_enum = SAEnum(
    *[e.value for e in SuitcaseCategory],
    name="suitcase_category_enum",
    create_type=True,
)
destination_type_enum = SAEnum(
    *[e.value for e in DestinationType],
    name="destination_type_enum",
    create_type=True,
)


class SuitcaseItemModel(Base):
    """
    Checklist item for a lead's suitcase (feat/client-suitcase-backend).
    """

    __tablename__ = "suitcase_items"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    lead_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("leads.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    categoria: Mapped[str] = mapped_column(
        suitcase_category_enum,
        nullable=False,
        default=SuitcaseCategory.outros.value,
    )
    nome: Mapped[str] = mapped_column(String(255), nullable=False)
    quantidade: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    empacotado: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )

    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    atualizado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    lead: Mapped["LeadModel"] = relationship("LeadModel", lazy="select")
    user: Mapped["UserModel"] = relationship("UserModel", lazy="select")


class SuitcaseSuggestionModel(Base):
    """
    Static suggestions by destination type (deterministic logic).
    Used to pre-populate a suitcase or offer recommendations.
    """

    __tablename__ = "suitcase_suggestions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    tipo_destino: Mapped[str] = mapped_column(
        destination_type_enum, nullable=False, index=True
    )
    categoria: Mapped[str] = mapped_column(suitcase_category_enum, nullable=False)
    nome: Mapped[str] = mapped_column(String(255), nullable=False)
    quantidade_sugerida: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    descricao: Mapped[Optional[str]] = mapped_column(String(512))
