"""
Scheduled Job — Conversation Summary Retry (feat-conversation-summary-001)
===========================================================================
Re-attempts AI summary generation for rows with resumo_pendente=True.
Runs every 15 minutes inside the FastAPI APScheduler instance.
"""

import structlog

from app.infrastructure.persistence.database import AsyncSessionLocal
from app.services.conversation_summary_service import retry_pending_summaries

logger = structlog.get_logger()


async def run_conversation_summary_retry() -> None:
    """
    Picks up to 50 pending summary rows and retries LLM generation.
    Failures are left with resumo_pendente=True for the next cycle.
    """
    logger.info("conversation_summary_retry_job_started")
    try:
        async with AsyncSessionLocal() as db:
            resolved = await retry_pending_summaries(db, batch_size=50)
        logger.info(
            "conversation_summary_retry_job_completed",
            resolved=resolved,
            actor="sistema/rotina_automatica",
        )
    except Exception as exc:
        logger.error(
            "conversation_summary_retry_job_failed",
            error=str(exc),
            actor="sistema/rotina_automatica",
            exc_info=True,
        )
