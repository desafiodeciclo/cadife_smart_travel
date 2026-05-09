"""
Proposta Expiration Service
===========================
Business logic for the proposta SLA expiration cronjob.

Identifies proposals in 'enviada' or 'em_revisao' status whose SLA
(criado_em + expiration_hours) has passed and transitions them to 'expirada'.

Optionally dispatches an HTTP webhook to notify external systems (CRM, Slack, etc.)
about each expiration batch.
"""
from __future__ import annotations

from datetime import UTC, datetime, timedelta
from typing import TypedDict

import httpx
import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import PropostaStatus
from app.models.proposta import Proposta as PropostaModel

logger = structlog.get_logger()

# Statuses that represent "open and waiting" — candidates for SLA expiry.
_EXPIRABLE_STATUSES = (PropostaStatus.enviada.value, PropostaStatus.em_revisao.value)


class ExpiredPropostaInfo(TypedDict):
    id: str
    lead_id: str
    consultor_id: str | None
    status_anterior: str
    expiration_hours: int
    criado_em: str
    expirado_em: str


async def expire_stale_propostas(
    db: AsyncSession,
    default_expiration_hours: int,
) -> list[ExpiredPropostaInfo]:
    """
    Expire all proposals whose SLA window has closed.

    Uses per-row expiration_hours when set; falls back to default_expiration_hours
    for rows created before the column was added (server_default=48 covers this).

    Returns a list of dicts with metadata for each expired proposal — used by
    the job layer to dispatch the optional webhook.
    """
    now = datetime.now(UTC)

    result = await db.execute(
        select(PropostaModel).where(PropostaModel.status.in_(_EXPIRABLE_STATUSES))
    )
    candidates = result.scalars().all()

    expired: list[ExpiredPropostaInfo] = []

    for proposta in candidates:
        hours = proposta.expiration_hours or default_expiration_hours
        criado_em_aware = (
            proposta.criado_em
            if proposta.criado_em.tzinfo is not None
            else proposta.criado_em.replace(tzinfo=UTC)
        )
        expires_at = criado_em_aware + timedelta(hours=hours)

        if now < expires_at:
            continue

        status_anterior = proposta.status
        proposta.status = PropostaStatus.expirada.value

        expired.append(
            ExpiredPropostaInfo(
                id=str(proposta.id),
                lead_id=str(proposta.lead_id),
                consultor_id=str(proposta.consultor_id) if proposta.consultor_id else None,
                status_anterior=status_anterior,
                expiration_hours=hours,
                criado_em=criado_em_aware.isoformat(),
                expirado_em=now.isoformat(),
            )
        )

    if expired:
        await db.commit()
        logger.info(
            "propostas_expiradas",
            count=len(expired),
            ids=[p["id"] for p in expired],
            actor="sistema/rotina_automatica",
        )
    else:
        logger.debug("proposta_expiration_noop", actor="sistema/rotina_automatica")

    return expired


async def dispatch_expiration_webhook(
    webhook_url: str,
    expired: list[ExpiredPropostaInfo],
) -> None:
    """
    POST a batch payload to the configured external webhook URL.

    Failures are logged but never raised — a webhook error must never abort
    the expiration run or crash the scheduler.
    """
    if not webhook_url or not expired:
        return

    payload = {
        "event": "propostas.expiradas",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "count": len(expired),
        "propostas": expired,
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(webhook_url, json=payload)
            response.raise_for_status()
        logger.info(
            "expiration_webhook_dispatched",
            count=len(expired),
            status_code=response.status_code,
        )
    except Exception as exc:
        logger.error(
            "expiration_webhook_failed",
            error=str(exc),
            count=len(expired),
            exc_info=True,
        )
