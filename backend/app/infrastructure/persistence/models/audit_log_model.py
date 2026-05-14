import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import DateTime, String, Text, func, JSON
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.infrastructure.persistence.types import GUID

class AuditLog(Base):
    """
    General purpose audit log for critical business events.
    Captures: WHO, WHEN, WHAT, and the CONTEXT.
    """
    __tablename__ = "audit_logs"

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(), primary_key=True, default=uuid.uuid4
    )
    
    # WHO
    user_id: Mapped[Optional[uuid.UUID]] = mapped_column(GUID(), index=True)
    user_email: Mapped[Optional[str]] = mapped_column(String(255))
    
    # WHEN
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False, index=True
    )
    
    # WHAT
    event_type: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    resource_type: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    resource_id: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    
    # CONTEXT
    description: Mapped[Optional[str]] = mapped_column(Text)
    payload: Mapped[Optional[dict]] = mapped_column(JSON)
    ip_address: Mapped[Optional[str]] = mapped_column(String(45))
    user_agent: Mapped[Optional[str]] = mapped_column(String(500))

    def __repr__(self) -> str:
        return f"<AuditLog(event={self.event_type}, resource={self.resource_type}:{self.resource_id})>"
