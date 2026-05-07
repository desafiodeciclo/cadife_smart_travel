"""
Scheduled Job — Proposta SLA Expiration
========================================
Runs every 5 minutes via APScheduler AsyncIOScheduler.

For each execution:
  1. Opens a dedicated AsyncSession (outside request context).
  2. Expires proposals in 'enviada' or 'em_revisao' status whose SLA window
     (criado_em + expiration_hours) has elapsed.
  3. Optionally dispatches an HTTP webhook to external systems.
  4. Logs the outcome via structlog.

Exceptions are caught and logged so a transient DB/network failure does not
crash the scheduler or bring down the application.
"""

import structlog

from app.infrastructure.config.settings import get_settings
from app.infrastructure.persistence.database import AsyncSessionLocal
from app.services.proposta_expiration_service import (
    dispatch_expiration_webhook,
    expire_stale_propostas,
)

logger = structlog.get_logger()


async def expire_stale_propostas_job() -> None:
    """
    APScheduler entry point — called every 5 minutes by the AsyncIOScheduler.
    Creates its own DB session so it works outside of a FastAPI request context.
    """
    settings = get_settings()
    default_hours = settings.PROPOSTA_EXPIRATION_HOURS_DEFAULT
    webhook_url = settings.PROPOSTA_EXPIRATION_WEBHOOK_URL

    logger.info(
        "proposta_expiration_job_started",
        default_expiration_hours=default_hours,
        webhook_configured=bool(webhook_url),
    )

    try:
        async with AsyncSessionLocal() as db:
            expired = await expire_stale_propostas(db, default_expiration_hours=default_hours)

        await dispatch_expiration_webhook(webhook_url, expired)

        logger.info(
            "proposta_expiration_job_completed",
            propostas_expired=len(expired),
            actor="sistema/rotina_automatica",
        )

    except Exception as exc:
        logger.error(
            "proposta_expiration_job_failed",
            error=str(exc),
            actor="sistema/rotina_automatica",
            exc_info=True,
        )
