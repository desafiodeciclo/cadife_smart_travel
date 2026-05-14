"""
Sale Goals service — monthly target/achieved counters per consultor.

Behaviors:
  - list_recent(): returns goals for the last N months, backfilling 0/0 for
    missing periods so the front always renders a continuous timeline.
  - upsert_target(): admin sets the target for (user, year, month). Idempotent.
  - increment_achieved(): atomic +1 on the (user, current year/month) row.
    Called from `routes/propostas.py` when a proposta is approved.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime, timezone
from typing import Optional

import structlog
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.persistence.models.sale_goal_model import SaleGoalModel
from app.presentation.schemas.consultor_profile_schema import (
    SaleGoalResponse,
    SaleGoalsListResponse,
)

logger = structlog.get_logger()


def _enumerate_periods(start: date, end: date) -> list[tuple[int, int]]:
    """Yields (year, month) tuples from `start` (inclusive) to `end` (inclusive),
    where both dates are expected to be the first of their month."""
    out: list[tuple[int, int]] = []
    y, m = start.year, start.month
    while (y, m) <= (end.year, end.month):
        out.append((y, m))
        m += 1
        if m > 12:
            m = 1
            y += 1
    return out


async def list_recent(
    db: AsyncSession, user_id: uuid.UUID, months: int = 3
) -> SaleGoalsListResponse:
    months = max(1, min(months, 12))
    today = date.today().replace(day=1)
    # start = today - (months - 1) months
    sm = today.month - (months - 1)
    sy = today.year
    while sm <= 0:
        sm += 12
        sy -= 1
    start = date(sy, sm, 1)

    stmt = select(SaleGoalModel).where(SaleGoalModel.user_id == user_id)
    rows = list((await db.execute(stmt)).scalars().all())
    indexed = {(r.period_year, r.period_month): r for r in rows}

    periods = _enumerate_periods(start, today)
    # Newest first
    periods.reverse()

    goals: list[SaleGoalResponse] = []
    for (year, month) in periods:
        existing = indexed.get((year, month))
        if existing:
            goals.append(SaleGoalResponse.model_validate(existing))
        else:
            goals.append(
                SaleGoalResponse(
                    period_year=year, period_month=month, target=0, achieved=0
                )
            )
    return SaleGoalsListResponse(goals=goals)


async def upsert_target(
    db: AsyncSession,
    user_id: uuid.UUID,
    period_year: int,
    period_month: int,
    target: int,
) -> SaleGoalModel:
    """Sets target for (user, period). Creates row if missing. Idempotent."""
    stmt = select(SaleGoalModel).where(
        SaleGoalModel.user_id == user_id,
        SaleGoalModel.period_year == period_year,
        SaleGoalModel.period_month == period_month,
    )
    row = (await db.execute(stmt)).scalar_one_or_none()
    if row:
        row.target = target
        row.updated_at = datetime.now(timezone.utc)
    else:
        row = SaleGoalModel(
            user_id=user_id,
            period_year=period_year,
            period_month=period_month,
            target=target,
            achieved=0,
        )
        db.add(row)
    await db.commit()
    await db.refresh(row)
    logger.info(
        "goal_target_updated",
        user_id=str(user_id),
        period=f"{period_year}-{period_month:02d}",
        target=target,
    )
    return row


async def increment_achieved(
    db: AsyncSession,
    user_id: uuid.UUID,
    period_year: Optional[int] = None,
    period_month: Optional[int] = None,
) -> SaleGoalModel:
    """Atomic +1 on `achieved` for the (user, year, month). Defaults to current month.

    Uses INSERT ... ON CONFLICT ... DO UPDATE to make the operation safe under
    concurrent approvals (Postgres only). For SQLite tests, falls back to a
    SELECT-then-UPDATE inside the same transaction.
    """
    today = date.today()
    py = period_year or today.year
    pm = period_month or today.month

    bind = db.bind if hasattr(db, "bind") else None
    dialect_name = (
        bind.dialect.name if bind is not None else db.get_bind().dialect.name
    )

    if dialect_name == "postgresql":
        stmt = (
            pg_insert(SaleGoalModel)
            .values(
                user_id=user_id,
                period_year=py,
                period_month=pm,
                target=0,
                achieved=1,
            )
            .on_conflict_do_update(
                index_elements=["user_id", "period_year", "period_month"],
                set_={
                    "achieved": SaleGoalModel.achieved + 1,
                    "updated_at": datetime.now(timezone.utc),
                },
            )
            .returning(SaleGoalModel)
        )
        result = await db.execute(stmt)
        await db.commit()
        row = result.scalar_one()
    else:
        # SQLite fallback (tests).
        stmt = select(SaleGoalModel).where(
            SaleGoalModel.user_id == user_id,
            SaleGoalModel.period_year == py,
            SaleGoalModel.period_month == pm,
        )
        row = (await db.execute(stmt)).scalar_one_or_none()
        if row:
            row.achieved += 1
            row.updated_at = datetime.now(timezone.utc)
        else:
            row = SaleGoalModel(
                user_id=user_id,
                period_year=py,
                period_month=pm,
                target=0,
                achieved=1,
            )
            db.add(row)
        await db.commit()
        await db.refresh(row)

    logger.info(
        "goal_achieved_incremented",
        user_id=str(user_id),
        period=f"{py}-{pm:02d}",
        new_achieved=row.achieved,
    )
    return row
