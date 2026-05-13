import structlog
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.security.dependencies import get_db, get_current_user
from app.schemas.lead import LeadStatus, LeadsListResponse
from app.services import lead_service
from app.models.user import User

logger = structlog.get_logger()
router = APIRouter(prefix="/leads", tags=["Leads"])

@router.get("/", response_model=LeadsListResponse)
async def list_leads(
    page: int = Query(1, ge=1, description="Número da página"),
    size: int = Query(10, ge=1, le=100, description="Itens por página"),
    status: Optional[LeadStatus] = Query(None, description="Filtrar por status"),
    search: Optional[str] = Query(None, description="Busca textual por nome ou telefone"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Retorna uma lista paginada de leads com suporte a filtros.
    Acesso restrito a usuários autenticados.
    """
    logger.info("listing_leads", user_id=str(current_user.id), page=page, size=size, status=status)
    
    try:
        return await lead_service.get_leads_paginated(
            db, 
            page=page, 
            size=size, 
            status=status,
            search=search
        )
    except Exception as e:
        logger.error("leads_listing_failed", error=str(e))
        raise e
