"""
Travel ORM Table — Infrastructure/Persistence Layer
====================================================
SQLAlchemy mapped model for the 'travels' table.
Represents a client's trip / travel booking.
"""

import uuid
from app.infrastructure.persistence.types import GUID
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import (
    DateTime,
    ForeignKey,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.persistence.database import Base

if TYPE_CHECKING:
    from app.infrastructure.persistence.models.user_model import UserModel


class TravelModel(Base):
    """
    ORM representation of a travel (trip) for the client portal.
    """

    __tablename__ = "travels"

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    destination: Mapped[str] = mapped_column(String(255), nullable=False)

    start_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )

    end_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )

    status: Mapped[str] = mapped_column(String(20), nullable=False, index=True)

    image_url: Mapped[Optional[str]] = mapped_column(
        String(1024), nullable=True
    )

    description: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True
    )

    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # Relationships
    user: Mapped["UserModel"] = relationship("UserModel", lazy="select")
