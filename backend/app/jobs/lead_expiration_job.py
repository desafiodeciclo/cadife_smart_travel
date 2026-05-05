"""
Scheduled Job — Lead Expiration (spec.md §8.4)
===============================================
Marks leads inactive for LEAD_EXPIRATION_DAYS as PERDIDO once per day.

Runs inside the FastAPI process via APScheduler AsyncIOScheduler.
Creates its own DB session so it works outside of a request context.
All status changes are logged via structlog with actor="sistema/rotina_automatica"
to satisfy the Audit Trail requirement without an HTTP request context.
"""

import structlog
from app.infrastructure.config.settings import get_settings
from app.infrastructure.persistence.database import AsyncSessionLocal
from app.services.lead_service import mark_stale_leads_as_perdido

logger = structlog.get_logger()


async def expire_stale_leads() -> None:
    """
    Scheduled daily job: queries leads inactive beyond LEAD_EXPIRATION_DAYS
    and transitions them to PERDIDO via LeadStateMachine.

    Exceptions are caught and logged so a transient DB failure does not
    crash the scheduler or bring down the application.
    """
    settings = get_settings()
    expiration_days = settings.LEAD_EXPIRATION_DAYS

    logger.info("lead_expiration_job_started", expiration_days=expiration_days)

    try:
        async with AsyncSessionLocal() as db:
            count = await mark_stale_leads_as_perdido(db, inactivity_days=expiration_days)

        logger.info(
            "lead_expiration_job_completed",
            leads_expired=count,
            expiration_days=expiration_days,
            actor="sistema/rotina_automatica",
        )
    except Exception as exc:
        logger.error(
            "lead_expiration_job_failed",
            error=str(exc),
            expiration_days=expiration_days,
            actor="sistema/rotina_automatica",
            exc_info=True,
        )
