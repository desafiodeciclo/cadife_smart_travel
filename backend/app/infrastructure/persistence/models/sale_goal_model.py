import uuid
from datetime import datetime
from sqlalchemy import Integer, ForeignKey, UniqueConstraint, CheckConstraint, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column
from app.infrastructure.persistence.database import Base
from app.infrastructure.persistence.types import GUID

class SaleGoalModel(Base):
    __tablename__ = "sale_goals"
    
    id: Mapped[uuid.UUID] = mapped_column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(GUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    period_year: Mapped[int] = mapped_column(Integer, nullable=False)
    period_month: Mapped[int] = mapped_column(Integer, nullable=False)
    target: Mapped[int] = mapped_column(Integer, nullable=False, server_default="0")
    achieved: Mapped[int] = mapped_column(Integer, nullable=False, server_default="0")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        UniqueConstraint("user_id", "period_year", "period_month", name="uq_sale_goal_user_period"),
        CheckConstraint("period_month BETWEEN 1 AND 12", name="ck_sale_goal_month"),
        CheckConstraint("target >= 0", name="ck_sale_goal_target"),
    )
