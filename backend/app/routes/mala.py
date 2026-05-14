"""
Mala — Canonical PT routes (parity gap §3.11)
==============================================
Canonical Portuguese paths for the suitcase resource. Mirrors the legacy
EN router (`routes/suitcase.py`) but uses /leads/{lead_id}/mala (with
sub-paths /itens and /sugestoes) to align with `specs/spec.md` §5.6.

Both routers register against the same `suitcase_service`, so behavior is
identical. The EN router is marked deprecated; this PT router is canonical.

Path mapping (EN → PT):
  /leads/{id}/suitcase             → /leads/{id}/mala
  /leads/{id}/suitcase/items       → /leads/{id}/mala/itens
  /leads/{id}/suitcase/items/{id}  → /leads/{id}/mala/itens/{id}
  /leads/{id}/suitcase/suggestions → /leads/{id}/mala/sugestoes
"""

import uuid
from typing import List, Optional

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import DestinationType
from app.infrastructure.security.dependencies import (
    get_current_user,
    get_db,
)
from app.presentation.schemas.suitcase_schema import (
    SuitcaseGroupedResponse,
    SuitcaseItemCreate,
    SuitcaseItemResponse,
    SuitcaseItemUpdate,
    SuitcaseSuggestionResponse,
)
from app.services import lead_service, suitcase_service

logger = structlog.get_logger()
router = APIRouter(prefix="/leads/{lead_id}/mala", tags=["Mala"])


async def _validate_mala_ownership(
    lead_id: uuid.UUID,
    db: AsyncSession,
    current_user,
):
    """Same ownership rules as legacy /suitcase router (kept identical)."""
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lead não encontrado",
        )

    if current_user.perfil == "cliente":
        from app.infrastructure.security.pii_encryption import hmac_hash

        user_phone_hash = (
            hmac_hash(current_user.telefone) if current_user.telefone else None
        )
        if lead.telefone_hash != user_phone_hash:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Acesso negado à mala de outro usuário",
            )
    return lead


@router.get(
    "",
    response_model=SuitcaseGroupedResponse,
    summary="Listar mala agrupada (canônico PT)",
    description=(
        "Retorna todos os itens da mala agrupados por categoria. "
        "Equivalente ao path EN deprecated `/leads/{lead_id}/suitcase`."
    ),
)
async def get_mala(
    lead_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    await _validate_mala_ownership(lead_id, db, current_user)
    return await suitcase_service.get_grouped_suitcase(db, lead_id)


@router.post(
    "/itens",
    response_model=SuitcaseItemResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Adicionar item à mala (canônico PT)",
    description=(
        "Adiciona um novo item à mala. "
        "Equivalente ao path EN deprecated `/leads/{lead_id}/suitcase/items`."
    ),
)
async def add_mala_item(
    lead_id: uuid.UUID,
    item_in: SuitcaseItemCreate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    await _validate_mala_ownership(lead_id, db, current_user)

    item = await suitcase_service.add_item(
        db,
        lead_id=lead_id,
        user_id=current_user.id,
        nome=item_in.nome,
        categoria=item_in.categoria,
        quantidade=item_in.quantidade,
    )
    logger.info("mala_item_added", lead_id=str(lead_id), item_id=str(item.id))
    return item


@router.patch(
    "/itens/{item_id}",
    response_model=SuitcaseItemResponse,
    summary="Atualizar item da mala (canônico PT)",
    description=(
        "Atualiza um item existente (ex.: marca como empacotado). "
        "Equivalente ao path EN deprecated `/leads/{lead_id}/suitcase/items/{item_id}`."
    ),
)
async def update_mala_item(
    lead_id: uuid.UUID,
    item_id: uuid.UUID,
    item_in: SuitcaseItemUpdate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    await _validate_mala_ownership(lead_id, db, current_user)

    item = await suitcase_service.get_item_by_id(db, item_id)
    if not item or item.lead_id != lead_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item não encontrado nesta mala",
        )

    updated_item = await suitcase_service.update_item(
        db, item_id=item_id, **item_in.model_dump(exclude_none=True)
    )
    logger.info("mala_item_updated", lead_id=str(lead_id), item_id=str(item_id))
    return updated_item


@router.delete(
    "/itens/{item_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remover item da mala (canônico PT)",
    description=(
        "Remove um item da mala. "
        "Equivalente ao path EN deprecated `/leads/{lead_id}/suitcase/items/{item_id}`."
    ),
)
async def delete_mala_item(
    lead_id: uuid.UUID,
    item_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    await _validate_mala_ownership(lead_id, db, current_user)

    item = await suitcase_service.get_item_by_id(db, item_id)
    if not item or item.lead_id != lead_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item não encontrado nesta mala",
        )
    await suitcase_service.delete_item(db, item_id)
    logger.info("mala_item_deleted", lead_id=str(lead_id), item_id=str(item_id))


@router.get(
    "/sugestoes",
    response_model=List[SuitcaseSuggestionResponse],
    summary="Sugestões de itens para a mala (canônico PT)",
    description=(
        "Retorna sugestões com base no tipo de destino. Se não fornecido, "
        "tenta inferir a partir do briefing do lead. "
        "Equivalente ao path EN deprecated `/leads/{lead_id}/suitcase/suggestions`."
    ),
)
async def get_mala_sugestoes(
    lead_id: uuid.UUID,
    tipo_destino: Optional[DestinationType] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await _validate_mala_ownership(lead_id, db, current_user)

    target_destination = tipo_destino
    if not target_destination and lead.briefing:
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
