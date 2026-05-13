# Presentation Schemas — Pydantic schemas for API validation (request/response).
from app.presentation.schemas.leads import (
    LeadCreateRequest,
    LeadDetailDTO,
    LeadListItemDTO,
    LeadListResponseDTO,
    LeadMetricsDTO,
    LeadUpdateRequest,
)
from .lead_schema import LeadCreateSchema, LeadUpdateSchema, LeadResponseSchema
from .briefing_schema import BriefingSchema, BriefingResponse
from .offer_schema import (
    OfferCreateRequest as OfferCreate,
    OfferUpdateRequest as OfferUpdate,
    OfferResponse,
    OfferResponse as OfferListItem,
    OffersListResponse as OfferListResponse,
)

__all__ = [
    "LeadCreateRequest",
    "LeadUpdateRequest",
    "LeadListItemDTO",
    "LeadDetailDTO",
    "LeadListResponseDTO",
    "LeadMetricsDTO",
    "LeadCreateSchema",
    "LeadUpdateSchema",
    "LeadResponseSchema",
    "BriefingSchema",
    "BriefingResponse",
    "OfferCreate",
    "OfferUpdate",
    "OfferResponse",
    "OfferListItem",
    "OfferListResponse",
]
