import math
import uuid
from typing import Optional

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.security.dependencies import RequiresRole, get_current_user, get_db
from app.models.briefing import BriefingResponse, BriefingUpdate, calculate_completude
from app.models.interacao import InteracaoListResponse
from app.models.lead import LeadCreate, LeadListItem, LeadListResponse, LeadResponse, LeadUpdate
from app.application.services.lead_state_machine import InvalidStateTransitionError, LeadStateMachine
from app.domain.entities.enums import LeadStatus
from app.services import lead_service

logger = structlog.get_logger()
router = APIRouter(
    prefix="/leads",
    tags=["Leads"],
)


@router.get("", response_model=LeadListResponse, dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))])
async def list_leads(
    status: Optional[str] = Query(None),
    score: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    # RBAC: Se o usuário for 'consultor', ele só vê os próprios leads.
    # Se for 'admin' ou 'agencia', vê todos.
    consultor_id = None
    if current_user.perfil == "consultor":
        consultor_id = current_user.id

    leads, total = await lead_service.list_leads(
        db, status=status, score=score, search=search, page=page, limit=limit, consultor_id=consultor_id
    )
    pages = math.ceil(total / limit) if total else 1
    items = []
    for lead in leads:
        completude = lead.briefing.completude_pct if lead.briefing else None
        items.append(LeadListItem(
            id=lead.id,
            nome=lead.nome,
            telefone=lead.telefone,
            origem=lead.origem,
            status=lead.status,
            score=lead.score,
            criado_em=lead.criado_em,
            atualizado_em=lead.atualizado_em,
            completude_pct=completude,
        ))
    return LeadListResponse(items=items, total=total, page=page, limit=limit, pages=pages)


@router.get("/my-active", response_model=LeadResponse)
async def get_my_active_lead(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """
    Retorna o lead associado ao usuário logado (cliente).
    Se não existir, cria um novo lead baseado no telefone do usuário.
    """
    if not current_user.telefone:
         raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Usuário não possui telefone cadastrado para vincular a uma viagem"
        )
    
    from sqlalchemy import select
    from sqlalchemy.orm import selectinload
    from app.models.lead import Lead
    from app.infrastructure.security.pii_encryption import hmac_hash

    phone_hash = hmac_hash(current_user.telefone)
    result = await db.execute(
        select(Lead)
        .where(Lead.telefone_hash == phone_hash)
        .options(selectinload(Lead.consultor))
    )
    lead = result.scalar_one_or_none()
    
    if not lead:
        lead = await lead_service.get_or_create_by_phone(db, current_user.telefone, current_user.nome)
        # Refresh to ensure relationships are handled correctly if needed, 
        # but get_or_create doesn't load consultor since it's new.

    response = LeadResponse.model_validate(lead)
    if lead.consultor:
        response.consultor_nome = lead.consultor.nome
        response.consultor_avatar = lead.consultor.avatar_url
        
    return response


@router.post("", response_model=LeadResponse, status_code=status.HTTP_201_CREATED, dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))])
async def create_lead(
    lead_in: LeadCreate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    from sqlalchemy import select
    from app.models.lead import Lead
    existing = await db.execute(select(Lead).where(Lead.telefone == lead_in.telefone))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Telefone já cadastrado")

    lead = await lead_service.get_or_create_by_phone(db, lead_in.telefone, lead_in.nome)
    return LeadResponse.model_validate(lead)


@router.get("/{lead_id}", response_model=LeadResponse, dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))])
async def get_lead(
    lead_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")

    # Scope Check
    if current_user.perfil == "consultor" and lead.consultor_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado ao lead")

    return LeadResponse.model_validate(lead)


@router.put("/{lead_id}", response_model=LeadResponse, dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))])
async def update_lead(
    lead_id: uuid.UUID,
    lead_in: LeadUpdate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")

    data = lead_in.model_dump(exclude_none=True)

    # ── State Machine validation ──────────────────────────────────────────
    if "status" in data:
        new_status = LeadStatus(data["status"])
        try:
            LeadStateMachine.validate_transition(lead.status, new_status)
            await lead_service.update_lead_status(db, lead, new_status, triggered_by="user_manual")
        except InvalidStateTransitionError as exc:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=str(exc),
            ) from exc

        # ── Auto-score trigger on transition to QUALIFICADO ───────────────────
        if new_status == LeadStatus.qualificado:
            from app.services.lead_service import calculate_score_from_briefing
            lead.score = calculate_score_from_briefing(lead.briefing)
            logger.info(
                "lead_auto_scored",
                lead_id=str(lead.id),
                status=lead.status.value,
                score=lead.score.value if lead.score else None,
            )

        # Status removed from data as it's already handled by service
        data.pop("status")

    for field, value in data.items():
        setattr(lead, field, value)

    await db.commit()
    await db.refresh(lead)
    return LeadResponse.model_validate(lead)


@router.delete("/{lead_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))])
async def archive_lead(
    lead_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")
    await lead_service.soft_delete(db, lead)


@router.get("/{lead_id}/interacoes", response_model=InteracaoListResponse, dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))])
async def get_interacoes(
    lead_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")
    from app.models.interacao import InteracaoResponse
    items = [InteracaoResponse.model_validate(i) for i in lead.interacoes]
    return InteracaoListResponse(items=items, total=len(items))


@router.get("/{lead_id}/briefing", response_model=BriefingResponse, dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))])
async def get_briefing(
    lead_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead or not lead.briefing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Briefing não encontrado")
    return BriefingResponse.model_validate(lead.briefing)


@router.put("/{lead_id}/briefing", response_model=BriefingResponse, dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))])
async def update_briefing(
    lead_id: uuid.UUID,
    briefing_in: BriefingUpdate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead or not lead.briefing:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Briefing não encontrado")

    briefing = lead.briefing
    for field, value in briefing_in.model_dump(exclude_none=True).items():
        setattr(briefing, field, value)
    briefing.completude_pct = calculate_completude(briefing.__dict__)
    await db.commit()
    await db.refresh(briefing)
    return BriefingResponse.model_validate(briefing)

