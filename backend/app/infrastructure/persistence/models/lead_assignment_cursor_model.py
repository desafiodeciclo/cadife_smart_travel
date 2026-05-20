"""
LeadAssignmentCursor ORM — Infrastructure/Persistence Layer
============================================================
Single-row cursor for round-robin lead auto-assignment.

See `specs/active/B-feat-lead-auto-assignment-round-robin.json`.

The cursor stores the last consultant that received a lead so the next
assignment can pick the next one in the rotation. A SELECT FOR UPDATE on
this row serializes concurrent assignments, preventing two simultaneous
leads from picking the same consultant.
"""

import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.persistence.database import Base


class LeadAssignmentCursorModel(Base):
    """Singleton row (id=fixed UUID) holding the last-assigned consultor."""

    __tablename__ = "lead_assignment_cursor"
    __table_args__ = ({"extend_existing": True},)

    # Fixed singleton ID so the row is upserted, never duplicated.
    SINGLETON_ID = uuid.UUID("00000000-0000-0000-0000-000000000001")

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=SINGLETON_ID
    )
    last_assigned_user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
