"""
Itinerary Routes — Presentation Layer
======================================
Endpoints para gerenciamento do itinerário de viagem de um lead.

Routes:
  PUT  /leads/{leadId}/notes/{date}   — Upsert de nota diária (idempotente)
  GET  /leads/{leadId}/itinerary      — Itinerário consolidado agrupado por data
"""

import uuid
from datetime import date, datetime
from typing import Optional

import structlog
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import ItineraryItemType
from app.infrastructure.persistence.models.itinerary_daily_note_model import (
    ItineraryDailyNoteModel,
)
from app.infrastructure.persistence.models.itinerary_model import ItineraryItemModel
from app.infrastructure.security.dependencies import RequiresRole, get_current_user, get_db
from app.models.lead import Lead
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.services import lead_service

logger = structlog.get_logger()
router = APIRouter(tags=["Itinerário"])


# ── Schemas ────────────────────────────────────────────────────────────────


class DailyNoteRequest(BaseModel):
    notes: str

    model_config = {"extra": "forbid"}


class DailyNoteResponse(BaseModel):
    id: uuid.UUID
    lead_id: uuid.UUID
    date: date
    notes: Optional[str]
    updated_at: datetime

    model_config = {"from_attributes": True}


class ItineraryItemResponse(BaseModel):
    id: uuid.UUID
    tipo: ItineraryItemType
    titulo: str
    descricao: Optional[str] = None
    local: Optional[str] = None
    endereco: Optional[str] = None
    horario_inicio: datetime
    horario_fim: Optional[datetime] = None
    notas: Optional[str] = None

    model_config = {"from_attributes": True}


class ItineraryDayResponse(BaseModel):
    date: date
    note: Optional[str] = None
    items: list[ItineraryItemResponse] = []


class ItineraryResponse(BaseModel):
    lead_id: uuid.UUID
    days: list[ItineraryDayResponse]


# ── PUT /leads/{leadId}/notes/{date} ──────────────────────────────────────


@router.put(
    "/leads/{lead_id}/notes/{note_date}",
    response_model=DailyNoteResponse,
    summary="Criar ou atualizar nota diária do itinerário",
    description=(
        "Upsert idempotente de nota geral para um dia específico do itinerário. "
        "Se já existir nota para (lead_id, date), atualiza o texto; caso contrário, insere."
    ),
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        200: {"description": "Nota atualizada"},
        201: {"description": "Nota criada"},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
    },
)
async def upsert_daily_note(
    lead_id: uuid.UUID,
    note_date: date,
    body: DailyNoteRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")

    result = await db.execute(
        select(ItineraryDailyNoteModel).where(
            ItineraryDailyNoteModel.lead_id == lead_id,
            ItineraryDailyNoteModel.date == note_date,
        )
    )
    note = result.scalar_one_or_none()

    if note:
        note.notes = body.notes
        await db.commit()
        await db.refresh(note)
        logger.info("itinerary_note_updated", lead_id=str(lead_id), date=str(note_date))
    else:
        note = ItineraryDailyNoteModel(
            id=uuid.uuid4(),
            lead_id=lead_id,
            date=note_date,
            notes=body.notes,
        )
        db.add(note)
        await db.commit()
        await db.refresh(note)
        logger.info("itinerary_note_created", lead_id=str(lead_id), date=str(note_date))

    return DailyNoteResponse.model_validate(note)


# ── GET /leads/{leadId}/itinerary ─────────────────────────────────────────


@router.get(
    "/leads/{lead_id}/itinerary",
    response_model=ItineraryResponse,
    summary="Itinerário consolidado do lead",
    description=(
        "Retorna todos os eventos do itinerário agrupados por data em ordem cronológica. "
        "Cada dia inclui a nota diária correspondente e a lista de atividades daquele dia."
    ),
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia", "cliente"))],
    responses={
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
    },
)
async def get_itinerary(
    lead_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")

    items_result = await db.execute(
        select(ItineraryItemModel)
        .where(ItineraryItemModel.lead_id == lead_id)
        .order_by(ItineraryItemModel.horario_inicio)
    )
    items = list(items_result.scalars().all())

    notes_result = await db.execute(
        select(ItineraryDailyNoteModel)
        .where(ItineraryDailyNoteModel.lead_id == lead_id)
        .order_by(ItineraryDailyNoteModel.date)
    )
    daily_notes = {n.date: n.notes for n in notes_result.scalars().all()}

    days_map: dict[date, list[ItineraryItemModel]] = {}
    for item in items:
        day = item.horario_inicio.date()
        days_map.setdefault(day, []).append(item)

    all_dates = sorted(set(list(days_map.keys()) + list(daily_notes.keys())))

    days = [
        ItineraryDayResponse(
            date=d,
            note=daily_notes.get(d),
            items=[ItineraryItemResponse.model_validate(i) for i in days_map.get(d, [])],
        )
        for d in all_dates
    ]

    return ItineraryResponse(lead_id=lead_id, days=days)
