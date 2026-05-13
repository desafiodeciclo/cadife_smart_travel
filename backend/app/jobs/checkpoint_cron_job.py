"""
Scheduled Job — Travel Checkpoint Date Triggers
================================================
Runs once per day (03:00 UTC) to activate date-based checkpoints:
  - VIAGEM_EM_ANDAMENTO: when departure date <= today
  - VIAGEM_CONCLUIDA:    when return date + 1 day <= today

Idempotent by design — the unique constraint (lead_id, checkpoint) in the DB
absorbs duplicate activations silently, so re-runs never create duplicate records.
"""

import structlog
from app.infrastructure.persistence.database import AsyncSessionLocal
from app.services.checkpoint_service import check_travel_date_checkpoints

logger = structlog.get_logger()


async def run_checkpoint_cron() -> None:
    logger.info("checkpoint_cron_started")
    try:
        async with AsyncSessionLocal() as db:
            activated = await check_travel_date_checkpoints(db)
        logger.info("checkpoint_cron_completed", activated=activated, actor="sistema/rotina_automatica")
    except Exception as exc:
        logger.error("checkpoint_cron_failed", error=str(exc), exc_info=True)
