import uuid
from decimal import Decimal
from typing import Optional

import structlog
from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import OfferCategoria, OfferStatus
from app.infrastructure.security.dependencies import (
    RequiresRole,
    get_current_user,
    get_db,
)
from app.presentation.schemas.offer_schema import (
    OfferCreate,
    OfferInterestResponse,
    OfferListItem,
    OfferListResponse,
    OfferResponse,
    OfferUpdate,
)
from app.models.user import User
from app.services import offer_service

logger = structlog.get_logger()
router = APIRouter(prefix="/offers", tags=["Offers"])


def _form_to_offer_create(
    titulo: str = Form(..., min_length=3, max_length=255),
    destino: str = Form(..., min_length=2, max_length=255),
    descricao: Optional[str] = Form(None),
    categoria: OfferCategoria = Form(OfferCategoria.outros),
    preco_base: Optional[Decimal] = Form(None),
    servicos_inclusos: Optional[str] = Form(None),
    data_saida_sugerida: Optional[str] = Form(None),
    duracao_dias: Optional[int] = Form(None),
) -> OfferCreate:
    """Convert form fields to an OfferCreate schema."""
    from datetime import date as dt_date

    data: dict = {
        "titulo": titulo,
        "destino": destino,
        "descricao": descricao,
        "categoria": categoria,
        "preco_base": preco_base,
        "servicos_inclusos": [],
        "data_saida_sugerida": dt_date.fromisoformat(data_saida_sugerida) if data_saida_sugerida else None,
        "duracao_dias": duracao_dias,
    }
    if servicos_inclusos:
        data["servicos_inclusos"] = [s.strip() for s in servicos_inclusos.split(",") if s.strip()]
    return OfferCreate.model_validate(data)


def _form_to_offer_update(
    titulo: Optional[str] = Form(None),
    destino: Optional[str] = Form(None),
    descricao: Optional[str] = Form(None),
    categoria: Optional[OfferCategoria] = Form(None),
    preco_base: Optional[Decimal] = Form(None),
    servicos_inclusos: Optional[str] = Form(None),
    imagens: Optional[str] = Form(None),
    data_saida_sugerida: Optional[str] = Form(None),
    duracao_dias: Optional[int] = Form(None),
) -> OfferUpdate:
    """Convert form fields to an OfferUpdate schema."""
    from datetime import date as dt_date

    data: dict = {}
    if titulo is not None:
        data["titulo"] = titulo
    if destino is not None:
        data["destino"] = destino
    if descricao is not None:
        data["descricao"] = descricao
    if categoria is not None:
        data["categoria"] = categoria
    if preco_base is not None:
        data["preco_base"] = preco_base
    if servicos_inclusos is not None:
        data["servicos_inclusos"] = [s.strip() for s in servicos_inclusos.split(",") if s.strip()]
    if imagens is not None:
        data["imagens"] = [s.strip() for s in imagens.split(",") if s.strip()]
    if data_saida_sugerida is not None:
        data["data_saida_sugerida"] = dt_date.fromisoformat(data_saida_sugerida)
    if duracao_dias is not None:
        data["duracao_dias"] = duracao_dias
    return OfferUpdate.model_validate(data)


@router.post(
    "",
    response_model=OfferResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
)
async def create_offer(
    data: dict = Depends(_form_to_offer_create),
    images: list[UploadFile] = File(default_factory=list),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new travel offer with optional image uploads."""
    offer = await offer_service.create_offer(
        db, data=data, images=images, user_id=current_user.id
    )
    return OfferResponse.model_validate(offer)


@router.get(
    "",
    response_model=OfferListResponse,
)
async def list_offers(
    status: Optional[OfferStatus] = Query(None),
    categoria: Optional[OfferCategoria] = Query(None),
    preco_min: Optional[Decimal] = Query(None, ge=0),
    preco_max: Optional[Decimal] = Query(None, ge=0),
    search: Optional[str] = Query(None, description="Busca por título ou destino"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List offers with filters and pagination."""
    # Clients only see published offers
    effective_status = status
    if current_user.perfil == "cliente":
        effective_status = OfferStatus.publicada

    items, total = await offer_service.list_offers(
        db,
        status=effective_status,
        categoria=categoria,
        preco_min=preco_min,
        preco_max=preco_max,
        search=search,
        page=page,
        limit=limit,
    )

    pages = (total + limit - 1) // limit
    return OfferListResponse(
        items=[OfferListItem.model_validate(o) for o in items],
        total=total,
        page=page,
        limit=limit,
        pages=pages,
    )


@router.get(
    "/{offer_id}",
    response_model=OfferResponse,
)
async def get_offer(
    offer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a single offer by ID."""
    offer = await offer_service.get_offer_by_id(db, offer_id)
    if not offer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Oferta não encontrada"
        )
    if current_user.perfil == "cliente" and offer.status != OfferStatus.publicada:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Oferta não disponível",
        )
    return OfferResponse.model_validate(offer)


@router.patch(
    "/{offer_id}",
    response_model=OfferResponse,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
)
async def update_offer(
    offer_id: uuid.UUID,
    data: dict = Depends(_form_to_offer_update),
    images: list[UploadFile] = File(default_factory=list),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update an offer. RBAC: creator or admin only."""
    offer = await offer_service.get_offer_by_id(db, offer_id)
    if not offer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Oferta não encontrada"
        )

    if current_user.perfil != "admin" and offer.criado_por != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sem permissão para editar esta oferta",
        )

    updated = await offer_service.update_offer(db, offer, data, images=images or None)
    return OfferResponse.model_validate(updated)


@router.patch(
    "/{offer_id}/publish",
    response_model=OfferResponse,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
)
async def toggle_publish(
    offer_id: uuid.UUID,
    publish: bool = Query(..., description="True to publish, False to unpublish"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Publish or unpublish an offer. RBAC: creator or admin only."""
    offer = await offer_service.get_offer_by_id(db, offer_id)
    if not offer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Oferta não encontrada"
        )

    if current_user.perfil != "admin" and offer.criado_por != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sem permissão para alterar esta oferta",
        )

    updated = await offer_service.publish_offer(db, offer, publish)
    return OfferResponse.model_validate(updated)


@router.delete(
    "/{offer_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
)
async def delete_offer(
    offer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Soft-delete an offer. RBAC: creator or admin only."""
    offer = await offer_service.get_offer_by_id(db, offer_id)
    if not offer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Oferta não encontrada"
        )

    if current_user.perfil != "admin" and offer.criado_por != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sem permissão para excluir esta oferta",
        )

    await offer_service.soft_delete_offer(db, offer)


@router.post(
    "/{offer_id}/interest",
    response_model=OfferInterestResponse,
    dependencies=[Depends(RequiresRole("cliente"))],
)
async def express_interest(
    offer_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Client expresses interest in an offer → auto-creates a lead."""
    offer = await offer_service.get_offer_by_id(db, offer_id)
    if not offer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Oferta não encontrada"
        )
    if offer.status != OfferStatus.publicada:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Oferta não está publicada",
        )

    lead = await offer_service.create_lead_from_interest(
        db,
        offer=offer,
        user_id=current_user.id,
        user_phone=current_user.telefone,
        user_name=current_user.nome,
    )

    return OfferInterestResponse(
        message="Interesse registrado com sucesso",
        lead_id=lead.id,
        offer_id=offer.id,
    )
