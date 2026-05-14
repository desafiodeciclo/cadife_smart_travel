"""
Proposta Versao Service — append-only snapshot history (gap §3.4.4).

Single responsibility: persist a JSON snapshot of a `Proposta` at the moment
of every business-relevant mutation, plus expose listing for the front.

The number_versao is generated server-side via `MAX(numero_versao) + 1` on
insert, scoped to the proposta_id. There is a UNIQUE (proposta_id, numero_versao)
constraint so concurrent snapshots on the same proposta will fail with
IntegrityError on the loser; service retries once.
"""

from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any, Literal, Optional

import structlog
from fastapi.encoders import jsonable_encoder
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.proposta import Proposta, PropostaVersao

logger = structlog.get_logger()

MotivoLiteral = Literal[
    "criacao", "edicao", "envio", "aprovacao", "recusa", "cancelamento"
]


def _iso_or_str(value) -> Optional[str]:
    """Return ISO format for datetime, pass-through for str, None otherwise."""
    if value is None:
        return None
    if isinstance(value, datetime):
        return value.isoformat()
    if isinstance(value, str):
        return value
    return str(value)


def _serialize_proposta(proposta: Proposta) -> dict[str, Any]:
    """Build a JSON-safe dict snapshot of all relevant Proposta columns."""
    snap = {
        "id": str(proposta.id),
        "lead_id": str(proposta.lead_id),
        "descricao": proposta.descricao,
        "valor_estimado": (
            str(proposta.valor_estimado)
            if isinstance(proposta.valor_estimado, Decimal)
            else proposta.valor_estimado
        ),
        "status": (
            proposta.status.value
            if hasattr(proposta.status, "value")
            else proposta.status
        ),
        "consultor_id": (
            str(proposta.consultor_id) if proposta.consultor_id is not None else None
        ),
        "expiration_hours": proposta.expiration_hours,
        "criado_em": _iso_or_str(proposta.criado_em),
        "enviado_em": _iso_or_str(getattr(proposta, "enviado_em", None)),
        "deletado_em": _iso_or_str(getattr(proposta, "deletado_em", None)),
    }
    return jsonable_encoder(snap)


async def _next_numero_versao(db: AsyncSession, proposta_id: uuid.UUID) -> int:
    last = await db.scalar(
        select(func.max(PropostaVersao.numero_versao)).where(
            PropostaVersao.proposta_id == proposta_id
        )
    )
    return (last or 0) + 1


async def snapshot(
    db: AsyncSession,
    proposta: Proposta,
    motivo: MotivoLiteral,
    by: Optional[uuid.UUID] = None,
    *,
    autocommit: bool = False,
) -> PropostaVersao:
    """Insert a versao row. Caller is responsible for committing the outer TX
    unless `autocommit=True` is passed.

    Retries once on IntegrityError (conflict on numero_versao under concurrent
    snapshot of the same proposta).
    """
    for attempt in (1, 2):
        next_num = await _next_numero_versao(db, proposta.id)
        versao = PropostaVersao(
            proposta_id=proposta.id,
            numero_versao=next_num,
            snapshot_json=_serialize_proposta(proposta),
            motivo=motivo,
            created_by=by,
        )
        db.add(versao)
        try:
            if autocommit:
                await db.commit()
                await db.refresh(versao)
            else:
                await db.flush()
            logger.info(
                "proposta_versao_snapshotted",
                proposta_id=str(proposta.id),
                numero_versao=next_num,
                motivo=motivo,
                by=str(by) if by else None,
            )
            return versao
        except IntegrityError as exc:
            await db.rollback()
            if attempt == 2:
                logger.warning(
                    "proposta_versao_conflict_after_retry",
                    proposta_id=str(proposta.id),
                    error=str(exc.orig) if hasattr(exc, "orig") else str(exc),
                )
                raise
            # else loop and retry
    # Unreachable
    raise RuntimeError("snapshot retry loop exhausted")


async def list_by_proposta(
    db: AsyncSession, proposta_id: uuid.UUID
) -> list[PropostaVersao]:
    stmt = (
        select(PropostaVersao)
        .where(PropostaVersao.proposta_id == proposta_id)
        .order_by(PropostaVersao.numero_versao.desc())
    )
    return list((await db.execute(stmt)).scalars().all())
