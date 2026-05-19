import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional, List, Dict

from pydantic import BaseModel, ConfigDict, Field

from app.domain.entities.enums import OfferStatus


class OfferResponse(BaseModel):
    """Resposta ao listar oferta (minimal)"""
    id: uuid.UUID
    title: str
    destination: str
    destination_image_url: Optional[str]
    departure_date: datetime
    return_date: datetime
    duration_days: int
    base_price: Decimal
    final_price: Decimal
    currency: str
    travelers: int
    available_spots: int
    spots_reserved: int
    status: OfferStatus
    highlights: List[str]
    amenities: List[str]
    views: int
    interests: int
    conversions: int

    model_config = ConfigDict(from_attributes=True)


class OfferDetailResponse(OfferResponse):
    """Response com detalhes completos"""
    description: str
    accommodations: List[str]
    included_services: List[str]
    booking_deadline: datetime
    discounts: Optional[Dict[str, float]]
    created_at: datetime
    published_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)


class OfferCreateRequest(BaseModel):
    """Request para criar oferta"""
    title: str = Field(..., min_length=5, max_length=100)
    description: str = Field(..., min_length=20, max_length=2000)
    destination: str = Field(..., min_length=3)
    destination_image_url: Optional[str] = None
    departure_date: datetime
    return_date: datetime
    booking_deadline: datetime
    accommodations: List[str] = Field(..., min_length=1)
    included_services: List[str] = Field(..., min_length=1)
    travelers: int = Field(..., ge=1)
    available_spots: int = Field(..., ge=1)
    base_price: Decimal = Field(..., gt=0)
    discounts: Optional[Dict[str, float]] = None
    highlights: List[str] = Field(..., min_length=1)
    amenities: List[str] = Field(default_factory=list)


class OfferUpdateRequest(BaseModel):
    """Request para atualizar oferta"""
    title: Optional[str] = Field(None, min_length=5, max_length=100)
    description: Optional[str] = Field(None, min_length=20, max_length=2000)
    destination: Optional[str] = None
    destination_image_url: Optional[str] = None
    base_price: Optional[Decimal] = Field(None, gt=0)
    available_spots: Optional[int] = Field(None, ge=0)
    status: Optional[OfferStatus] = None
    discounts: Optional[Dict[str, float]] = None


class OffersListResponse(BaseModel):
    """Lista de ofertas com paginação"""
    offers: List[OfferResponse]
    total: int
    page: int
    pages: int
    filters_applied: Optional[Dict] = None


class OfferPublishResponse(BaseModel):
    """Resposta do toggle de publicação de oferta"""
    status: str
    message: str
    new_status: str
    offer_id: uuid.UUID

    model_config = ConfigDict(from_attributes=True)


class OfferDeleteResponse(BaseModel):
    """Resposta de remoção (soft-delete) de oferta"""
    status: str
    message: str
    offer_id: uuid.UUID

    model_config = ConfigDict(from_attributes=True)
