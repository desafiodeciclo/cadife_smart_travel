"""
Diary Routes — Presentation Layer
================================
FastAPI routes for the Travel Diary feature.
Handles photo uploads, timeline listing, and memory management.
"""

import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.persistence.repositories.diary_repository import DiaryRepository
from app.infrastructure.persistence.repositories.lead_repository import LeadRepository
from app.infrastructure.adapters.storage.s3_adapter import S3StorageAdapter
from app.infrastructure.security.dependencies import get_current_user, get_db
from app.presentation.schemas.diary_schema import DiaryEntryRead, DiaryEntryList
from app.services.diary_service import DiaryService

router = APIRouter(tags=["Diário de Viagem"])


def get_diary_service(db: AsyncSession = Depends(get_db)) -> DiaryService:
    """Dependency provider for DiaryService."""
    diary_repo = DiaryRepository(db)
    lead_repo = LeadRepository(db)
    storage = S3StorageAdapter()
    return DiaryService(diary_repo, lead_repo, storage)


# ── Trip Specific Entries ──────────────────────────────────────────────────

@router.post(
    "/leads/{lead_id}/diary/entries",
    response_model=DiaryEntryRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_diary_entry(
    lead_id: uuid.UUID,
    nota: Optional[str] = Form(None, max_length=280),
    data_entrada: Optional[datetime] = Form(None),
    file: UploadFile = File(...),
    service: DiaryService = Depends(get_diary_service),
    current_user=Depends(get_current_user),
):
    """
    Cria uma nova entrada no diário de viagem (foto + nota).
    Apenas o dono da viagem pode adicionar memórias.
    """
    return await service.create_entry(
        user_id=current_user.id,
        lead_id=lead_id,
        photo=file,
        nota=nota,
        data_entrada=data_entrada
    )


@router.get(
    "/leads/{lead_id}/diary/entries",
    response_model=DiaryEntryList,
)
async def list_diary_entries(
    lead_id: uuid.UUID,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    service: DiaryService = Depends(get_diary_service),
    current_user=Depends(get_current_user),
):
    """
    Lista as memórias de uma viagem específica de forma paginada.
    """
    entries, total = await service.list_entries(
        lead_id=lead_id, 
        user_id=current_user.id, 
        page=page, 
        limit=limit
    )
    return {
        "entries": entries,
        "total": total,
        "page": page,
        "size": len(entries)
    }


@router.delete(
    "/leads/{lead_id}/diary/entries/{entry_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_diary_entry(
    lead_id: uuid.UUID,
    entry_id: uuid.UUID,
    service: DiaryService = Depends(get_diary_service),
    current_user=Depends(get_current_user),
):
    """
    Remove uma memória do diário. Valida se o usuário é o dono da entrada.
    """
    await service.delete_entry(entry_id=entry_id, user_id=current_user.id)


# ── Global User Timeline ──────────────────────────────────────────────────

@router.get(
    "/users/me/diary",
    response_model=DiaryEntryList,
)
async def list_my_diary(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    service: DiaryService = Depends(get_diary_service),
    current_user=Depends(get_current_user),
):
    """
    Retorna a linha do tempo completa de todas as viagens do usuário logado.
    """
    entries, total = await service.list_user_timeline(
        user_id=current_user.id, 
        page=page, 
        limit=limit
    )
    return {
        "entries": entries,
        "total": total,
        "page": page,
        "size": len(entries)
    }
