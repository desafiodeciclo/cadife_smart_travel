"""
CheckpointService — Travel Lifecycle Checkpoints
=================================================
Handles activation (manual and automatic) and retrieval of travel_checkpoints.

Idempotency contract: the unique constraint (lead_id, checkpoint) in the DB
guarantees that calling activate_checkpoint() twice for the same pair is safe —
the second call raises HTTP 409 and is a no-op.
"""

import uuid
from datetime import date, timezone, datetime
from typing import Optional

import structlog
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import TravelCheckpoint
from app.models.lead import Lead
from app.models.briefing import Briefing
from app.models.travel_checkpoint import TravelCheckpointRecord

logger = structlog.get_logger()

SISTEMA = "sistema"


async def activate_checkpoint(
    db: AsyncSession,
    lead_id: uuid.UUID,
    checkpoint: TravelCheckpoint,
    ativado_por: str,
    commit: bool = True,
) -> TravelCheckpointRecord:
    """
    Insert a checkpoint record. Raises HTTP 409 if the checkpoint already exists.
    Fires FCM notifications to client and assigned consultor asynchronously.

    When *commit=False* the record is flushed inside a savepoint so a duplicate-
    key IntegrityError only rolls back the savepoint — not the caller's outer
    transaction.  The caller is responsible for the final db.commit().
    """
    record = TravelCheckpointRecord(
        lead_id=lead_id,
        checkpoint=checkpoint,
        ativado_por=ativado_por,
    )

    if commit:
        # Default path: own flush → commit → refresh cycle.
        db.add(record)
        try:
            await db.flush()
        except IntegrityError:
            await db.rollback()
            logger.info(
                "checkpoint_already_active",
                lead_id=str(lead_id),
                checkpoint=checkpoint.value,
            )
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Checkpoint {checkpoint.value} já foi ativado para este lead.",
            )
        await db.commit()
        await db.refresh(record)
    else:
        # UoW path: use a savepoint so an IntegrityError (duplicate) is absorbed
        # without poisoning the outer transaction that owns the session.
        try:
            async with db.begin_nested():  # SAVEPOINT
                db.add(record)
                await db.flush()
        except IntegrityError:
            logger.info(
                "checkpoint_already_active",
                lead_id=str(lead_id),
                checkpoint=checkpoint.value,
            )
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Checkpoint {checkpoint.value} já foi ativado para este lead.",
            )
        # No commit — caller's transaction covers this record.

    logger.info(
        "checkpoint_activated",
        lead_id=str(lead_id),
        checkpoint=checkpoint.value,
        ativado_por=ativado_por,
    )

    # Fire-and-forget FCM — spawn with own session so the notification is not
    # tied to the caller's (potentially already-committed) session.
    from app.infrastructure.persistence.session_utils import spawn_with_own_session
    spawn_with_own_session(
        _notify_checkpoint, lead_id, checkpoint,
        task_name="checkpoint_notify",
    )

    return record


async def get_checkpoints(
    db: AsyncSession, lead_id: uuid.UUID
) -> list[TravelCheckpointRecord]:
    """Return all activated checkpoints for a lead, ordered by activation time."""
    result = await db.execute(
        select(TravelCheckpointRecord)
        .where(TravelCheckpointRecord.lead_id == lead_id)
        .order_by(TravelCheckpointRecord.ativado_em)
    )
    return list(result.scalars().all())


async def _notify_checkpoint(
    db: AsyncSession,
    lead_id: uuid.UUID,
    checkpoint: TravelCheckpoint,
) -> None:
    """Send FCM push to client and consultor when a checkpoint is activated."""
    from app.services.fcm_service import send_push_notification

    label = _checkpoint_label(checkpoint)
    title = "Progresso da sua viagem"
    body = f"Novo marco atingido: {label}"

    try:
        result = await db.execute(
            select(Lead).where(Lead.id == lead_id)
        )
        lead = result.scalar_one_or_none()
        if not lead:
            return

        from app.services.user_service import get_user_by_id

        # Notify consultor
        if lead.consultor_id:
            consultor = await get_user_by_id(db, str(lead.consultor_id))
            if consultor and consultor.fcm_token:
                await send_push_notification(
                    fcm_token=consultor.fcm_token,
                    title=f"Checkpoint: {label}",
                    body=f"Lead {lead.nome or lead.id} — {label}",
                    data={"type": "checkpoint", "checkpoint": checkpoint.value, "lead_id": str(lead_id)},
                )

        # Notify client (user whose phone matches the lead)
        from sqlalchemy import text
        client_result = await db.execute(
            text("SELECT fcm_token FROM users WHERE telefone = :phone AND perfil = 'cliente' LIMIT 1"),
            {"phone": lead.telefone},
        )
        row = client_result.fetchone()
        if row and row[0]:
            await send_push_notification(
                fcm_token=row[0],
                title=title,
                body=body,
                data={"type": "checkpoint", "checkpoint": checkpoint.value, "lead_id": str(lead_id)},
            )
    except Exception as exc:
        logger.error("checkpoint_fcm_error", lead_id=str(lead_id), error=str(exc))


def _checkpoint_label(checkpoint: TravelCheckpoint) -> str:
    labels = {
        TravelCheckpoint.briefing_coletado: "Briefing coletado",
        TravelCheckpoint.curadoria_iniciada: "Curadoria iniciada",
        TravelCheckpoint.proposta_enviada: "Proposta enviada",
        TravelCheckpoint.proposta_aprovada: "Proposta aprovada",
        TravelCheckpoint.viagem_confirmada: "Viagem confirmada",
        TravelCheckpoint.viagem_em_andamento: "Viagem em andamento",
        TravelCheckpoint.viagem_concluida: "Viagem concluída",
    }
    return labels.get(checkpoint, checkpoint.value)


# ── Cronjob helpers (step 4.1) ──────────────────────────────────────────────

async def check_travel_date_checkpoints(db: AsyncSession) -> dict[str, int]:
    """
    Daily cron: activate VIAGEM_EM_ANDAMENTO and VIAGEM_CONCLUIDA based on
    briefing departure/return dates. Safe to run multiple times — unique
    constraint absorbs duplicates silently.

    Returns counts of newly activated checkpoints for observability.
    """
    today = date.today()
    activated = {
        TravelCheckpoint.viagem_em_andamento.value: 0,
        TravelCheckpoint.viagem_concluida.value: 0,
    }

    result = await db.execute(
        select(Lead, Briefing)
        .join(Briefing, Briefing.lead_id == Lead.id)
        .where(
            Lead.is_archived.is_(False),
            Lead.deletado_em.is_(None),
        )
    )
    pairs = result.all()

    for lead, briefing in pairs:
        if briefing.data_ida and briefing.data_ida <= today:
            try:
                await activate_checkpoint(db, lead.id, TravelCheckpoint.viagem_em_andamento, SISTEMA)
                activated[TravelCheckpoint.viagem_em_andamento.value] += 1
            except HTTPException:
                pass  # already activated — idempotent

        if briefing.data_volta:
            from datetime import timedelta
            day_after_return = briefing.data_volta + timedelta(days=1)
            if day_after_return <= today:
                try:
                    await activate_checkpoint(db, lead.id, TravelCheckpoint.viagem_concluida, SISTEMA)
                    activated[TravelCheckpoint.viagem_concluida.value] += 1
                except HTTPException:
                    pass  # already activated — idempotent

    logger.info("checkpoint_cron_done", activated=activated, date=str(today))
    return activated
