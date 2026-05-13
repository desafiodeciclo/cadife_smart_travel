import uuid
from datetime import datetime
from typing import Optional

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import OfferStatus
from app.infrastructure.security.dependencies import (
    RequiresRole,
    get_current_user,
    get_optional_user,
    get_db,
)
from app.presentation.schemas.offer_schema import (
    OfferCreateRequest,
    OfferDetailResponse,
    OfferResponse,
    OfferUpdateRequest,
    OffersListResponse,
)
from app.models.user import User
from app.services import offer_service

logger = structlog.get_logger()
router = APIRouter(prefix="/offers", tags=["Offers"])


@router.get("", response_model=OffersListResponse)
async def list_offers(
    destination: Optional[str] = Query(None, description="Filtrar por destino"),
    min_price: Optional[float] = Query(None, ge=0),
    max_price: Optional[float] = Query(None, ge=0),
    min_date: Optional[datetime] = Query(None, description="Data de saída mínima"),
    max_date: Optional[datetime] = Query(None, description="Data de saída máxima"),
    travelers: Optional[int] = Query(None, ge=1, description="Nº de passageiros"),
    duration_min: Optional[int] = Query(None, ge=1, description="Duração mínima em dias"),
    duration_max: Optional[int] = Query(None, ge=1),
    search: Optional[str] = Query(None, description="Buscar por título ou destino"),
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    """
    Listar ofertas publicadas com filtros (Visão Cliente)
    """
    items, total = await offer_service.list_offers(
        db,
        destination=destination,
        min_price=min_price,
        max_price=max_price,
        min_date=min_date,
        max_date=max_date,
        travelers=travelers,
        duration_min=duration_min,
        duration_max=duration_max,
        search=search,
        page=page,
        limit=limit,
    )

    pages = (total + limit - 1) // limit
    return OffersListResponse(
        offers=[OfferResponse.model_validate(o) for o in items],
        total=total,
        page=page,
        pages=pages,
        filters_applied={
            "destination": destination,
            "min_price": min_price,
            "max_price": max_price,
            "travelers": travelers,
        }
    )


@router.get("/agency/my-offers", response_model=OffersListResponse)
async def get_my_offers(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    status_filter: Optional[OfferStatus] = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Listar todas as ofertas da agência/consultor autenticado
    """
    if current_user.perfil not in ["consultor", "admin", "agencia"]:
        raise HTTPException(status_code=403, detail="Apenas consultores e agências podem ver suas ofertas")

    items, total = await offer_service.list_offers(
        db,
        agency_id=current_user.id,
        status_filter=status_filter,
        page=page,
        limit=limit,
    )

    pages = (total + limit - 1) // limit
    return OffersListResponse(
        offers=[OfferResponse.model_validate(o) for o in items],
        total=total,
        page=page,
        pages=pages,
    )


@router.get("/{offer_id}", response_model=OfferDetailResponse)
async def get_offer(
    offer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_user),
):
    """
    Obter detalhes completos de uma oferta. 
    Soma 1 view se for cliente ou não autenticado.
    """
    increment_view = True if not current_user or current_user.perfil == "cliente" else False
    
    offer = await offer_service.get_offer_by_id(db, offer_id, increment_view=increment_view)
    
    if not offer:
        raise HTTPException(status_code=404, detail="Oferta não encontrada")
    
    # Se for rascunho, apenas o dono ou admin pode ver
    if offer.status == OfferStatus.draft:
        if not current_user or (current_user.perfil != "admin" and offer.agency_id != current_user.id):
             raise HTTPException(status_code=404, detail="Oferta não encontrada")

    return OfferDetailResponse.model_validate(offer)


@router.post("", response_model=OfferResponse, status_code=status.HTTP_201_CREATED)
async def create_offer(
    req: OfferCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Criar nova oferta (status: draft)
    """
    if current_user.perfil not in ["consultor", "admin", "agencia"]:
        raise HTTPException(status_code=403, detail="Apenas agências/consultores podem criar ofertas")

    offer = await offer_service.create_offer(db, req, agency_id=current_user.id)
    return OfferResponse.model_validate(offer)


@router.patch("/{offer_id}", response_model=OfferResponse)
async def update_offer(
    offer_id: uuid.UUID,
    req: OfferUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Atualizar oferta (apenas se status == draft)
    """
    offer = await offer_service.get_offer_by_id(db, offer_id)
    if not offer:
        raise HTTPException(status_code=404, detail="Oferta não encontrada")
        
    updated_offer = await offer_service.update_offer(db, offer, req, agency_id=current_user.id)
    return OfferResponse.model_validate(updated_offer)


@router.patch("/{offer_id}/publish")
async def toggle_publish_offer(
    offer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Publicar ou despublicar oferta (Toggle)
    """
    offer = await offer_service.get_offer_by_id(db, offer_id)
    if not offer:
        raise HTTPException(status_code=404, detail="Oferta não encontrada")
        
    updated = await offer_service.toggle_publish(db, offer, agency_id=current_user.id)
    
    return {
        "status": "success",
        "message": f"Oferta {updated.status.value}!",
        "new_status": updated.status.value,
        "offer_id": str(updated.id),
    }


@router.delete("/{offer_id}")
async def delete_offer(
    offer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Arquivar oferta (soft delete)
    """
    offer = await offer_service.get_offer_by_id(db, offer_id)
    if not offer:
        raise HTTPException(status_code=404, detail="Oferta não encontrada")
        
    await offer_service.soft_delete_offer(db, offer, agency_id=current_user.id)
    
    return {
        "status": "success",
        "message": "Oferta removida",
        "offer_id": str(offer_id),
    }


@router.post("/{offer_id}/interest")
async def express_interest(
    offer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Cliente expressa interesse em oferta → cria lead automaticamente
    """
    if current_user.perfil != "cliente":
        raise HTTPException(status_code=403, detail="Apenas clientes podem expressar interesse")

    offer = await offer_service.get_offer_by_id(db, offer_id)
    if not offer:
        raise HTTPException(status_code=404, detail="Oferta não encontrada")
    
    if offer.status != OfferStatus.published:
        raise HTTPException(status_code=400, detail="Oferta não disponível")

    result = await offer_service.express_interest(
        db, 
        offer=offer, 
        user_id=current_user.id,
        user_name=current_user.nome or "Cliente",
        user_email=current_user.email,
        user_phone=current_user.telefone
    )
    
    return result
