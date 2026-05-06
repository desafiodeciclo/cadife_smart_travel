import hashlib
import uuid
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, get_db
from app.models.agendamento import (
    Agendamento,
    AgendamentoCreate,
    AgendamentoResponse,
    AgendamentoStatus,
    AgendamentoUpdate,
    DisponibilidadeResponse,
    SlotDisponivel,
)

router = APIRouter(prefix="/agenda", tags=["Agenda"])

HORARIOS_DISPONIVEIS = ["09:00", "10:00", "11:00", "13:00", "14:00", "15:00"]
MAX_POR_DIA = 6


def _slot_lock_key(data: date, hora_str: str) -> int:
    """Derives a stable PostgreSQL bigint advisory lock key from (data, hora)."""
    raw = f"{data.isoformat()}_{hora_str}".encode()
    return int(hashlib.sha256(raw).hexdigest(), 16) % (2**63)


@router.get("/disponibilidade", response_model=DisponibilidadeResponse)
async def get_disponibilidade(
    data_inicio: date = Query(...),
    data_fim: date = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    from datetime import timedelta
    slots = []
    current = data_inicio
    while current <= data_fim:
        if current.weekday() < 5:  # Seg-Sex
            result = await db.execute(
                select(Agendamento).where(
                    Agendamento.data == current,
                    Agendamento.status != AgendamentoStatus.cancelado,
                )
            )
            agendados = result.scalars().all()
            agendados_horas = {str(a.hora)[:5] for a in agendados}

            for hora in HORARIOS_DISPONIVEIS:
                slots.append(SlotDisponivel(
                    data=current,
                    hora=hora,
                    disponivel=hora not in agendados_horas and len(agendados) < MAX_POR_DIA,
                ))
        current += timedelta(days=1)

    return DisponibilidadeResponse(slots=slots)


@router.post("", response_model=AgendamentoResponse, status_code=status.HTTP_201_CREATED)
async def create_agendamento(
    body: AgendamentoCreate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    hora_str = str(body.hora)[:5]
    if hora_str not in HORARIOS_DISPONIVEIS:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Horário fora do período de atendimento",
        )

    # Pessimistic lock — serialises concurrent requests for the same (data, hora) slot.
    # pg_advisory_xact_lock blocks until the lock is available and releases automatically
    # when the transaction commits or rolls back (including session close after exceptions).
    lock_key = _slot_lock_key(body.data, hora_str)
    await db.execute(text("SELECT pg_advisory_xact_lock(:key)"), {"key": lock_key})

    # SELECT FOR UPDATE: read the current slot rows with an exclusive row-level lock,
    # preventing dirty reads from any concurrent transaction that already holds rows.
    result = await db.execute(
        select(Agendamento)
        .where(
            Agendamento.data == body.data,
            Agendamento.hora == body.hora,
            Agendamento.status != AgendamentoStatus.cancelado,
        )
        .with_for_update()
    )
    slot_existente = result.scalars().first()

    if slot_existente is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Horário já reservado — tente outro horário disponível",
        )

    # Separate non-locking count for the daily cap (MAX_POR_DIA).
    # Lock granularity is per-slot; different slots on the same day are independent.
    count_result = await db.execute(
        select(Agendamento).where(
            Agendamento.data == body.data,
            Agendamento.status != AgendamentoStatus.cancelado,
        )
    )
    total_dia = len(count_result.scalars().all())

    if total_dia >= MAX_POR_DIA:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Agenda lotada: máximo de {MAX_POR_DIA} atendimentos atingido para esta data",
        )

    try:
        agendamento = Agendamento(
            lead_id=body.lead_id,
            data=body.data,
            hora=body.hora,
            tipo=body.tipo,
            consultor_id=body.consultor_id,
        )
        db.add(agendamento)
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Horário já reservado — tente outro horário disponível",
        )

    await db.refresh(agendamento)
    return AgendamentoResponse.model_validate(agendamento)


@router.get("/{agendamento_id}", response_model=AgendamentoResponse)
async def get_agendamento(
    agendamento_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = await db.execute(select(Agendamento).where(Agendamento.id == agendamento_id))
    ag = result.scalar_one_or_none()
    if not ag:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Agendamento não encontrado")
    return AgendamentoResponse.model_validate(ag)


@router.put("/{agendamento_id}", response_model=AgendamentoResponse)
async def update_agendamento(
    agendamento_id: uuid.UUID,
    body: AgendamentoUpdate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = await db.execute(select(Agendamento).where(Agendamento.id == agendamento_id))
    ag = result.scalar_one_or_none()
    if not ag:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Agendamento não encontrado")
    ag.status = body.status
    await db.commit()
    await db.refresh(ag)
    return AgendamentoResponse.model_validate(ag)
