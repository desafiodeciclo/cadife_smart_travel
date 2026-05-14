"""
Consultor metrics service — aggregates KPIs for the logged consultant.

Cache strategy: 5-minute TTL via Redis, keyed by user_id. Invalidated on
lead/proposta status changes (best-effort — TTL is the safety net).
"""

from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone

import structlog
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import LeadStatus, PropostaStatus
from app.infrastructure.persistence.models.lead_model import LeadModel
from app.infrastructure.persistence.models.proposta_model import PropostaModel
from app.presentation.schemas.consultor_profile_schema import ConsultorMetricsResponse

logger = structlog.get_logger()

CACHE_TTL_SECONDS = 300
_CACHE_KEY = "metrics:user:{user_id}"


def _cache_key(user_id: uuid.UUID) -> str:
    return _CACHE_KEY.format(user_id=str(user_id))


async def _try_get_redis():
    """Lazy import + best-effort Redis. Returns None if unavailable."""
    try:
        from app.infrastructure.cache.redis_client import get_redis

        return get_redis()
    except Exception:  # pragma: no cover — fallback is functional
        return None


async def consultor_metrics(
    db: AsyncSession, user_id: uuid.UUID
) -> ConsultorMetricsResponse:
    """Returns aggregated KPIs for the given consultor.

    Counts leads attributed to consultor_id (excluding soft-deleted) and
    propostas the consultor authored. Uses Redis cache when available.
    """
    redis = await _try_get_redis()
    key = _cache_key(user_id)

    if redis is not None:
        try:
            cached = await redis.get(key)
            if cached:
                payload = json.loads(cached)
                return ConsultorMetricsResponse.model_validate(payload)
        except Exception as exc:  # pragma: no cover
            logger.warning("metrics_cache_read_failed", error=str(exc))

    # ── Compute from DB ────────────────────────────────────────────────────
    # Lead-side counts in a single query (avoids N round-trips).
    qualified_statuses = (
        LeadStatus.qualificado.value,
        LeadStatus.agendado.value,
        LeadStatus.proposta.value,
        LeadStatus.fechado.value,
    )

    lead_stmt = select(
        func.count().label("total"),
        func.count()
        .filter(LeadModel.status.in_(qualified_statuses))
        .label("qualificados"),
        func.count()
        .filter(LeadModel.status == LeadStatus.fechado.value)
        .label("fechados"),
    ).where(
        LeadModel.consultor_id == user_id,
        LeadModel.deletado_em.is_(None),
    )
    lead_row = (await db.execute(lead_stmt)).one()

    proposta_stmt = select(func.count()).where(
        PropostaModel.consultor_id == user_id,
        PropostaModel.status.in_(
            (
                PropostaStatus.enviada.value,
                PropostaStatus.aprovada.value,
                PropostaStatus.recusada.value,
            )
        ),
    )
    propostas_enviadas = (await db.execute(proposta_stmt)).scalar_one()

    total = int(lead_row.total or 0)
    fechados = int(lead_row.fechados or 0)
    response = ConsultorMetricsResponse(
        leads_total=total,
        leads_qualificados=int(lead_row.qualificados or 0),
        propostas_enviadas=int(propostas_enviadas),
        vendas_fechadas=fechados,
        taxa_conversao=(fechados / total) if total else 0.0,
        gerado_em=datetime.now(timezone.utc),
    )

    if redis is not None:
        try:
            await redis.setex(
                key, CACHE_TTL_SECONDS, response.model_dump_json()
            )
        except Exception as exc:  # pragma: no cover
            logger.warning("metrics_cache_write_failed", error=str(exc))

    logger.info(
        "metrics_computed",
        user_id=str(user_id),
        leads_total=total,
        vendas=fechados,
    )
    return response


async def invalidate_metrics_cache(user_id: uuid.UUID) -> None:
    """Best-effort cache invalidation. Called from lead/proposta service hooks."""
    redis = await _try_get_redis()
    if redis is None:
        return
    try:
        await redis.delete(_cache_key(user_id))
        logger.info("metrics_cache_invalidated", user_id=str(user_id))
    except Exception as exc:  # pragma: no cover
        logger.warning("metrics_cache_invalidate_failed", error=str(exc))
