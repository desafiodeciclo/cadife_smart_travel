"""
Suitcase Routes — Presentation Layer
====================================
API endpoints for managing suitcase items and suggestions.
Implements ownership validation and offline-first sync support.
"""

import uuid
from typing import List, Optional

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import DestinationType
from app.infrastructure.security.dependencies import get_current_user, get_db, RequiresRole
from app.presentation.schemas.suitcase_schema import (
    SuitcaseGroupedResponse,
    SuitcaseItemCreate,
    SuitcaseItemResponse,
    SuitcaseItemUpdate,
    SuitcaseSuggestionResponse,
)
from app.services import suitcase_service, lead_service

logger = structlog.get_logger()
router = APIRouter(prefix="/leads/{lead_id}/suitcase", tags=["Suitcase"])


async def validate_suitcase_ownership(
    lead_id: uuid.UUID,
    db: AsyncSession,
    current_user
):
    """
    Ensures the lead exists and the current user has access to it.
    Clients can only access their own lead.
    """
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lead não encontrado"
        )
    
    # RBAC: If role is 'cliente', must match phone/email or be linked
    if current_user.perfil == "cliente":
        # Check if this lead belongs to the current user
        # In this system, user and lead are linked via phone/email or explicitly
        # For simplicity in this feat, we check if current_user.id matches lead.user_id if it exists
        # Or if the lead was created for this user's phone.
        from app.infrastructure.security.pii_encryption import hmac_hash
        user_phone_hash = hmac_hash(current_user.telefone) if current_user.telefone else None
        
        if lead.telefone_hash != user_phone_hash:
             raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado à mala de outro usuário"
            )
    
    return lead


@router.get("", response_model=SuitcaseGroupedResponse)
async def get_suitcase(
    lead_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """
    Returns all items in the suitcase grouped by category.
    """
    await validate_suitcase_ownership(lead_id, db, current_user)
    return await suitcase_service.get_grouped_suitcase(db, lead_id)


@router.post("/items", response_model=SuitcaseItemResponse, status_code=status.HTTP_201_CREATED)
async def add_suitcase_item(
    lead_id: uuid.UUID,
    item_in: SuitcaseItemCreate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """
    Adds a new item to the suitcase.
    """
    await validate_suitcase_ownership(lead_id, db, current_user)
    
    item = await suitcase_service.add_item(
        db,
        lead_id=lead_id,
        user_id=current_user.id,
        nome=item_in.nome,
        categoria=item_in.categoria,
        quantidade=item_in.quantidade
    )
    
    logger.info("suitcase_item_added", lead_id=str(lead_id), item_id=str(item.id))
    return item


@router.patch("/items/{item_id}", response_model=SuitcaseItemResponse)
async def update_suitcase_item(
    lead_id: uuid.UUID,
    item_id: uuid.UUID,
    item_in: SuitcaseItemUpdate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """
    Updates an existing item (e.g., marks as packed).
    """
    await validate_suitcase_ownership(lead_id, db, current_user)
    
    # Verify item belongs to this lead
    item = await suitcase_service.get_item_by_id(db, item_id)
    if not item or item.lead_id != lead_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item não encontrado nesta mala"
        )
        
    updated_item = await suitcase_service.update_item(
        db,
        item_id=item_id,
        **item_in.model_dump(exclude_none=True)
    )
    
    logger.info("suitcase_item_updated", lead_id=str(lead_id), item_id=str(item_id))
    return updated_item


@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_suitcase_item(
    lead_id: uuid.UUID,
    item_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """
    Removes an item from the suitcase.
    """
    await validate_suitcase_ownership(lead_id, db, current_user)
    
    item = await suitcase_service.get_item_by_id(db, item_id)
    if not item or item.lead_id != lead_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item não encontrado nesta mala"
        )
        
    await suitcase_service.delete_item(db, item_id)
    logger.info("suitcase_item_deleted", lead_id=str(lead_id), item_id=str(item_id))


@router.get("/suggestions", response_model=List[SuitcaseSuggestionResponse])
async def get_suitcase_suggestions(
    lead_id: uuid.UUID,
    tipo_destino: Optional[DestinationType] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """
    Returns suggested items based on destination type.
    If tipo_destino is not provided, tries to infer from lead briefing.
    """
    lead = await validate_suitcase_ownership(lead_id, db, current_user)
    
    target_destination = tipo_destino
    if not target_destination and lead.briefing:
        # Simple inference logic: if "praia" in destination name or preferences
        destino_str = (lead.briefing.destino or "").lower()
        if "praia" in destino_str or "mar" in destino_str:
            target_destination = DestinationType.praia
        elif "neve" in destino_str or "frio" in destino_str or "europa" in destino_str:
            target_destination = DestinationType.frio
        elif "aventura" in destino_str or "trilha" in destino_str:
            target_destination = DestinationType.aventura
        else:
            target_destination = DestinationType.urbano

    if not target_destination:
        target_destination = DestinationType.urbano
        
    return await suitcase_service.get_suggestions(db, target_destination.value)
