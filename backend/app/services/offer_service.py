import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import Optional, List, Dict, Tuple

import structlog
from fastapi import HTTPException, status
from sqlalchemy import func, select, or_, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.domain.entities.enums import LeadStatus, OfferStatus, LeadOrigem
from app.models.lead import Lead
from app.models.offer import Offer
from app.models.lead_offer import LeadOffer
from app.presentation.schemas.offer_schema import OfferCreateRequest, OfferUpdateRequest
from app.services import lead_service
from app.services.fcm_service import send_push_notification as send_notification

logger = structlog.get_logger()


def calculate_final_price(base_price: Decimal, discounts: Optional[Dict[str, float]]) -> Decimal:
    """Calculate final price based on discounts dictionary (percentage values)."""
    final_price = base_price
    if discounts:
        for discount_percent in discounts.values():
            discount_amount = (base_price * Decimal(str(discount_percent))) / Decimal("100")
            final_price -= discount_amount
    return final_price.quantize(Decimal("0.01"))


async def create_offer(
    db: AsyncSession,
    data: OfferCreateRequest,
    agency_id: uuid.UUID,
) -> Offer:
    """Create a new offer in draft status."""
    
    # Validação de datas
    if data.return_date <= data.departure_date:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Data de retorno deve ser posterior à saída"
        )
    if data.booking_deadline > data.departure_date:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Prazo de inscrição deve ser antes da data de saída"
        )
    if data.booking_deadline < datetime.now(timezone.utc):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Prazo de inscrição deve ser no futuro"
        )

    duration = (data.return_date - data.departure_date).days
    final_price = calculate_final_price(data.base_price, data.discounts)

    offer = Offer(
        agency_id=agency_id,
        title=data.title,
        description=data.description,
        destination=data.destination,
        destination_image_url=data.destination_image_url,
        departure_date=data.departure_date,
        return_date=data.return_date,
        booking_deadline=data.booking_deadline,
        duration_days=duration,
        accommodations=data.accommodations,
        included_services=data.included_services,
        travelers=data.travelers,
        available_spots=data.available_spots,
        base_price=data.base_price,
        final_price=final_price,
        discounts=data.discounts,
        highlights=data.highlights,
        amenities=data.amenities,
        status=OfferStatus.draft,
    )
    
    db.add(offer)
    await db.commit()
    await db.refresh(offer)
    
    logger.info("offer_created", offer_id=str(offer.id), agency_id=str(agency_id))
    return offer


async def list_offers(
    db: AsyncSession,
    destination: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    min_date: Optional[datetime] = None,
    max_date: Optional[datetime] = None,
    travelers: Optional[int] = None,
    duration_min: Optional[int] = None,
    duration_max: Optional[int] = None,
    search: Optional[str] = None,
    agency_id: Optional[uuid.UUID] = None,
    status_filter: Optional[OfferStatus] = None,
    page: int = 1,
    limit: int = 10,
) -> Tuple[List[Offer], int]:
    """List offers with multiple filters and pagination."""
    
    query = select(Offer).where(Offer.is_deleted.is_(False))
    
    if agency_id:
        query = query.where(Offer.agency_id == agency_id)
    else:
        # Public listing: only published and with spots
        query = query.where(Offer.status == OfferStatus.published)
        query = query.where(Offer.available_spots > Offer.spots_reserved)

    if status_filter:
        query = query.where(Offer.status == status_filter)

    if destination:
        query = query.where(Offer.destination.ilike(f"%{destination}%"))
    
    if min_price is not None:
        query = query.where(Offer.final_price >= Decimal(str(min_price)))
    if max_price is not None:
        query = query.where(Offer.final_price <= Decimal(str(max_price)))
        
    if min_date:
        query = query.where(Offer.departure_date >= min_date)
    if max_date:
        query = query.where(Offer.departure_date <= max_date)
        
    if travelers:
        query = query.where(Offer.travelers == travelers)
        
    if duration_min:
        query = query.where(Offer.duration_days >= duration_min)
    if duration_max:
        query = query.where(Offer.duration_days <= duration_max)
        
    if search:
        query = query.where(
            or_(
                Offer.title.ilike(f"%{search}%"),
                Offer.destination.ilike(f"%{search}%")
            )
        )

    # Count total
    count_query = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_query)).scalar_one()

    # Apply pagination and sorting
    query = query.order_by(Offer.published_at.desc().nullslast(), Offer.created_at.desc())
    query = query.offset((page - 1) * limit).limit(limit)
    
    result = await db.execute(query)
    offers = list(result.scalars().all())
    
    # Increment views for the listed offers (background tracking)
    if not agency_id and offers:
        offer_ids = [o.id for o in offers]
        await db.execute(
            update(Offer)
            .where(Offer.id.in_(offer_ids))
            .values(views=Offer.views + 1)
        )
        await db.commit()

    return offers, total


async def get_offer_by_id(db: AsyncSession, offer_id: uuid.UUID, increment_view: bool = False) -> Optional[Offer]:
    """Get offer by ID and optionally increment views."""
    result = await db.execute(
        select(Offer).where(Offer.id == offer_id, Offer.is_deleted.is_(False))
    )
    offer = result.scalar_one_or_none()
    
    if offer and increment_view:
        offer.views += 1
        await db.commit()
        await db.refresh(offer)
        
    return offer


async def update_offer(
    db: AsyncSession,
    offer: Offer,
    data: OfferUpdateRequest,
    agency_id: uuid.UUID,
) -> Offer:
    """Update offer if it's in draft status and owned by the agency."""
    
    if offer.agency_id != agency_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Permissão negada")
    
    if offer.status != OfferStatus.draft:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Apenas rascunhos podem ser editados")

    update_data = data.model_dump(exclude_none=True)
    
    if "base_price" in update_data or "discounts" in update_data:
        base_price = Decimal(str(update_data.get("base_price", offer.base_price)))
        discounts = update_data.get("discounts", offer.discounts)
        update_data["final_price"] = calculate_final_price(base_price, discounts)

    for field, value in update_data.items():
        if hasattr(offer, field):
            setattr(offer, field, value)

    offer.updated_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(offer)
    return offer


async def toggle_publish(db: AsyncSession, offer: Offer, agency_id: uuid.UUID) -> Offer:
    """Toggle between published and draft status."""
    if offer.agency_id != agency_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Permissão negada")
    
    if offer.status not in [OfferStatus.draft, OfferStatus.published]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Status inválido para publicação")

    if offer.status == OfferStatus.draft:
        offer.status = OfferStatus.published
        offer.published_at = datetime.now(timezone.utc)
    else:
        offer.status = OfferStatus.draft
        offer.published_at = None

    offer.updated_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(offer)
    return offer


async def soft_delete_offer(db: AsyncSession, offer: Offer, agency_id: uuid.UUID) -> None:
    """Mark offer as archived (soft delete)."""
    if offer.agency_id != agency_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Permissão negada")
    
    offer.status = OfferStatus.archived
    offer.is_deleted = True
    offer.updated_at = datetime.now(timezone.utc)
    await db.commit()


async def express_interest(
    db: AsyncSession,
    offer: Offer,
    user_id: uuid.UUID,
    user_name: str,
    user_email: str,
    user_phone: Optional[str] = None,
) -> dict:
    """Create a lead and register interest in an offer."""
    
    # 1. Validar vagas disponíveis
    if offer.available_spots <= offer.spots_reserved:
        raise HTTPException(status_code=400, detail="Não há vagas disponíveis nesta oferta")

    # 2. Validar interesse duplicado
    stmt = select(LeadOffer).where(
        LeadOffer.offer_id == offer.id,
        LeadOffer.client_id == user_id
    )
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="Você já expressou interesse nesta oferta")

    # 4. Criar ou obter lead — telefone obrigatório (campo NOT NULL com hash único)
    if not user_phone:
        raise HTTPException(
            status_code=400,
            detail="Telefone obrigatório para expressar interesse. Atualize seu perfil antes de continuar.",
        )
    lead = await lead_service.get_or_create_by_phone(db, user_phone, user_name)
    
    # Recarregar lead com briefing
    result = await db.execute(
        select(Lead).where(Lead.id == lead.id).options(selectinload(Lead.briefing))
    )
    lead = result.scalar_one()

    # 5. Atualizar lead com dados da oferta
    lead.client_id = user_id
    lead.offer_id = offer.id
    lead.status = LeadStatus.qualificado
    lead.score_numerico = 75
    lead.origem = LeadOrigem.offer_interest
    lead.budget = offer.final_price
    
    # Atualizar briefing se necessário
    if lead.briefing:
        lead.briefing.destino = offer.destination
        lead.briefing.notas = f"Interesse na oferta: {offer.title}\n{offer.description[:200]}..."

    # 4. Registrar interesse na tabela de rastreamento
    interest = LeadOffer(
        offer_id=offer.id,
        client_id=user_id,
        lead_id=lead.id,
        agency_id=offer.agency_id
    )
    db.add(interest)

    # 5. Incrementar contador na oferta
    offer.interests += 1
    
    await db.commit()
    await db.refresh(lead)

    # 6. Notificar agência (via FCM se disponível)
    try:
        await send_notification(
            user_id=str(offer.agency_id),
            title="Novo interesse em oferta!",
            body=f"{user_name} se interessou na oferta '{offer.title}'",
            data={
                "type": "offer_interest",
                "offer_id": str(offer.id),
                "lead_id": str(lead.id),
            }
        )
    except Exception as e:
        logger.warning("failed_to_send_notification", error=str(e), agency_id=str(offer.agency_id))

    return {
        "status": "success",
        "message": "Interesse registrado! A agência entrará em contato em breve.",
        "lead_id": str(lead.id),
        "lead_status": lead.status.value,
    }
