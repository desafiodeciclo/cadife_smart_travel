"""
SaleGoal ORM — Infrastructure/Persistence Layer
================================================
Monthly sales target/achieved counters per consultant.

See PRD `docs/prd/PRD-agency-settings-and-consultor-profile.md` §3.2.4.
"""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Optional

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.persistence.database import Base

if TYPE_CHECKING:
    from app.infrastructure.persistence.models.user_model import UserModel


class SaleGoalModel(Base):
    """One row per (user, year, month). target editable by admin; achieved auto-incremented on proposta approve."""

    __tablename__ = "sale_goals"
    __table_args__ = (
        UniqueConstraint(
            "user_id", "period_year", "period_month", name="uq_sale_goal_user_period"
        ),
        CheckConstraint("period_month BETWEEN 1 AND 12", name="ck_sale_goal_month"),
        CheckConstraint("target >= 0", name="ck_sale_goal_target"),
        CheckConstraint("achieved >= 0", name="ck_sale_goal_achieved"),
        Index(
            "idx_sale_goals_user_period",
            "user_id",
            "period_year",
            "period_month",
        ),
        {"extend_existing": True},
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    period_year: Mapped[int] = mapped_column(Integer, nullable=False)
    period_month: Mapped[int] = mapped_column(Integer, nullable=False)
    target: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    achieved: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
