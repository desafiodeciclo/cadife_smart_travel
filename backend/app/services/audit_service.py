import uuid
from typing import Optional, Any
import structlog
from sqlalchemy.ext.asyncio import AsyncSession
from app.infrastructure.persistence.models.audit_log_model import AuditLog

logger = structlog.get_logger()

async def log_event(
    db: AsyncSession,
    event_type: str,
    resource_type: str,
    resource_id: Any,
    user_id: Optional[uuid.UUID] = None,
    user_email: Optional[str] = None,
    description: Optional[str] = None,
    payload: Optional[dict] = None,
    ip_address: Optional[str] = None,
) -> None:
    """
    Persists a business event to the audit_logs table and logs it to structlog.
    """
    try:
        audit = AuditLog(
            user_id=user_id,
            user_email=user_email,
            event_type=event_type,
            resource_type=resource_type,
            resource_id=str(resource_id),
            description=description,
            payload=payload,
            ip_address=ip_address,
        )
        db.add(audit)
        # We don't commit here; the caller's transaction handles it.
        
        logger.info(
            "audit_event_recorded",
            audit_event_type=event_type,
            resource=f"{resource_type}:{resource_id}",
            user=str(user_id) if user_id else "anonymous",
        )
    except Exception as exc:
        logger.error("audit_log_failed", error=str(exc), audit_event_type=event_type)
