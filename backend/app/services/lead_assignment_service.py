"""
Lead Assignment Service — Round-robin auto-assignment.
========================================================
Picks the next active consultor for a new lead, in a fair rotation.
See `specs/active/B-feat-lead-auto-assignment-round-robin.json`.

Strategy:
  1. Lock the singleton cursor row (SELECT FOR UPDATE) to serialize.
  2. Query consultores ativos (perfil in [consultor, agencia], is_active=true).
  3. Pick the next user after `last_assigned_user_id` in (name, id) order.
     Tiebreaker for severe imbalance: when the rotation candidate has
     significantly more active leads than the least-loaded peer, fall back
     to the least-loaded one.
  4. Update cursor and return the user.

If no active consultor exists, returns None (caller decides to leave the
lead orphan + log a warning).
"""

from __future__ import annotations

import uuid
from typing import Optional

import structlog
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import LeadStatus, UserPerfil
from app.infrastructure.persistence.models.lead_assignment_cursor_model import (
    LeadAssignmentCursorModel,
)
from app.infrastructure.persistence.models.lead_model import LeadModel
from app.models.user import User

logger = structlog.get_logger()

# Tiebreaker threshold: if the round-robin pick has more than this many extra
# active leads compared to the least-loaded consultor, prefer the least-loaded.
LOAD_IMBALANCE_THRESHOLD = 5


async def _active_consultor_loads(
    db: AsyncSession,
) -> list[tuple[User, int]]:
    """Return [(user, active_leads_count)] for active consultor/agencia users."""
    inactive_statuses = (LeadStatus.fechado.value, LeadStatus.perdido.value)

    stmt = (
        select(
            User,
            func.count(LeadModel.id)
            .filter(
                LeadModel.status.notin_(inactive_statuses),
                LeadModel.deletado_em.is_(None),
            )
            .label("active_leads"),
        )
        .outerjoin(LeadModel, LeadModel.consultor_id == User.id)
        .where(
            User.perfil.in_([UserPerfil.consultor, UserPerfil.agencia]),
            User.is_active.is_(True),
        )
        .group_by(User.id)
        .order_by(User.nome, User.id)
    )
    rows = (await db.execute(stmt)).all()
    return [(row[0], int(row[1] or 0)) for row in rows]


async def pick_next_consultor(db: AsyncSession) -> Optional[User]:
    """
    Pick the next consultor for a new lead via round-robin.

    Caller is responsible for committing the surrounding transaction; this
    function locks the cursor row but does not commit on its own.
    """
    # 1. Lock cursor row to serialize concurrent assignments.
    cursor_stmt = (
        select(LeadAssignmentCursorModel)
        .where(LeadAssignmentCursorModel.id == LeadAssignmentCursorModel.SINGLETON_ID)
        .with_for_update()
    )
    cursor = (await db.execute(cursor_stmt)).scalar_one_or_none()
    if cursor is None:
        # Row missing (e.g. migration not applied or seed lost). Create it.
        cursor = LeadAssignmentCursorModel(
            id=LeadAssignmentCursorModel.SINGLETON_ID,
            last_assigned_user_id=None,
        )
        db.add(cursor)
        await db.flush()

    # 2. Load active consultores with their current load.
    loads = await _active_consultor_loads(db)
    if not loads:
        logger.warning("no_active_consultor_available")
        return None

    # 3. Round-robin pick: next user after the cursor in deterministic order.
    last_id = cursor.last_assigned_user_id
    candidate: Optional[User] = None
    if last_id is None:
        candidate = loads[0][0]
    else:
        for idx, (user, _) in enumerate(loads):
            if user.id == last_id:
                candidate = loads[(idx + 1) % len(loads)][0]
                break
        if candidate is None:
            # Last-assigned user no longer in the pool (deactivated/deleted).
            candidate = loads[0][0]

    # 4. Tiebreaker: if the rotation pick is heavily loaded vs the least-loaded
    # peer, prefer the least-loaded to smooth imbalance.
    min_load = min(load for _, load in loads)
    candidate_load = next(load for u, load in loads if u.id == candidate.id)
    if candidate_load - min_load > LOAD_IMBALANCE_THRESHOLD:
        least_loaded_user = next(u for u, load in loads if load == min_load)
        logger.info(
            "lead_assignment_load_rebalance",
            rotation_pick_id=str(candidate.id),
            rotation_pick_load=candidate_load,
            least_loaded_id=str(least_loaded_user.id),
            least_loaded_load=min_load,
        )
        candidate = least_loaded_user

    # 5. Update cursor.
    cursor.last_assigned_user_id = candidate.id
    await db.flush()

    logger.info(
        "lead_auto_assigned_pick",
        consultor_id=str(candidate.id),
        strategy="round_robin",
    )
    return candidate


async def auto_assign_orphans(db: AsyncSession) -> dict:
    """
    Sweep all orphan leads (consultor_id IS NULL, not archived, not deleted)
    and assign them in batch via pick_next_consultor.

    Returns {"assigned": N, "skipped": M, "no_consultor_available": bool}.
    """
    orphan_stmt = select(LeadModel).where(
        LeadModel.consultor_id.is_(None),
        LeadModel.deletado_em.is_(None),
    )
    orphans = list((await db.execute(orphan_stmt)).scalars().all())

    assigned = 0
    skipped = 0
    no_consultor = False
    assignments: list[tuple[uuid.UUID, uuid.UUID]] = []  # (lead_id, consultor_id)

    for lead in orphans:
        consultor = await pick_next_consultor(db)
        if consultor is None:
            no_consultor = True
            skipped += 1
            continue
        lead.consultor_id = consultor.id
        assigned += 1
        assignments.append((lead.id, consultor.id))
        logger.info(
            "lead_auto_assigned",
            lead_id=str(lead.id),
            consultor_id=str(consultor.id),
            strategy="round_robin",
            source="orphan_sweep",
        )

    await db.commit()
    return {
        "assigned": assigned,
        "skipped": skipped,
        "no_consultor_available": no_consultor,
        "assignments": assignments,
    }
