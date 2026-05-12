"""
Scheduled Job — AYA Disabled Alert
====================================
Alerts consultants when AYA has been disabled for a lead for longer than
AYA_ALERT_HOURS (default 48h), reminding them to reactivate it.

Runs every hour via APScheduler. Creates its own DB session.
"""

from datetime import datetime, timedelta, timezone

import structlog
from sqlalchemy import select

from app.infrastructure.config.settings import get_settings
from app.infrastructure.persistence.database import AsyncSessionLocal
from app.infrastructure.persistence.models.lead_model import LeadModel
from app.models.notification_queue import NotificationQueue
from app.models.user import User

logger = structlog.get_logger()


async def alert_aya_disabled_leads() -> None:
    """
    Finds leads where aya_ativo=False and the last update was more than
    AYA_ALERT_HOURS ago, then sends a push notification to the consultant.
    """
    settings = get_settings()
    cutoff = datetime.now(timezone.utc) - timedelta(hours=settings.AYA_ALERT_HOURS)

    logger.info("aya_alert_job_started", alert_hours=settings.AYA_ALERT_HOURS)

    try:
        async with AsyncSessionLocal() as db:
            stmt = (
                select(LeadModel)
                .where(
                    LeadModel.aya_ativo.is_(False),
                    LeadModel.is_archived.is_(False),
                    LeadModel.atualizado_em < cutoff,
                    LeadModel.consultor_id.isnot(None),
                )
            )
            result = await db.execute(stmt)
            leads = list(result.scalars().all())

            if not leads:
                logger.info("aya_alert_job_no_leads")
                return

            consultor_ids = {lead.consultor_id for lead in leads}
            consultores_result = await db.execute(
                select(User).where(
                    User.id.in_(consultor_ids),
                    User.fcm_token.isnot(None),
                )
            )
            consultores = {u.id: u for u in consultores_result.scalars().all()}

            count = 0
            for lead in leads:
                consultor = consultores.get(lead.consultor_id)
                if not consultor or not consultor.fcm_token:
                    continue

                nome = lead.nome or "Cliente"
                hours_off = int((datetime.now(timezone.utc) - lead.atualizado_em).total_seconds() / 3600)

                job = NotificationQueue(
                    lead_id=lead.id,
                    status="pending",
                    retry_count=0,
                    max_retries=3,
                    retry_delay_seconds=60,
                    next_retry_at=None,
                    payload={
                        "title": "AYA desativada há muito tempo",
                        "body": f"{nome} está sem atendimento IA há {hours_off}h. Considere reativar a AYA.",
                        "data": {"type": "aya_disabled_alert", "lead_id": str(lead.id)},
                        "fcm_tokens": [consultor.fcm_token],
                    },
                )
                db.add(job)
                count += 1

            if count:
                await db.commit()

            logger.info(
                "aya_alert_job_completed",
                alerts_sent=count,
                actor="sistema/rotina_automatica",
            )

    except Exception as exc:
        logger.error(
            "aya_alert_job_failed",
            error=str(exc),
            actor="sistema/rotina_automatica",
            exc_info=True,
        )
