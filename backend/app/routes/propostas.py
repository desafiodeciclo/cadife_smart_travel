import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, get_db
from app.infrastructure.security.dependencies import RequiresRole
from app.infrastructure.security.scope_check import check_lead_access
from app.domain.entities.enums import LeadStatus, PropostaStatus
from app.models.proposta import Proposta, PropostaCreate, PropostaResponse, PropostaUpdate
from app.models.user import User
from app.services import lead_service

router = APIRouter(
    prefix="/propostas",
    tags=["Propostas"],
    dependencies=[Depends(RequiresRole("consultor", "admin"))],
)


@router.post(
    "",
    response_model=PropostaResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(RequiresRole("consultor", "admin"))],
)
async def create_proposta(
    body: PropostaCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # 1. Validate lead exists
    lead = await lead_service.get_lead_by_id(db, body.lead_id)
    if not lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lead não encontrado",
        )

    # 2. Scope check: consultor can only create proposals for their own leads
    check_lead_access(current_user, lead)

    # 3. Lead status validation: must be qualificado, agendado or proposta
    if lead.status not in {
        LeadStatus.qualificado.value,
        LeadStatus.agendado.value,
        LeadStatus.proposta.value,
    }:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Lead deve estar em status qualificado, agendado ou proposta para receber uma proposta",
        )

    proposta = Proposta(
        lead_id=body.lead_id,
        descricao=body.descricao,
        valor_estimado=body.valor_estimado,
        consultor_id=current_user.id,
        expiration_hours=body.expiration_hours,
    )
    db.add(proposta)
    await db.commit()
    await db.refresh(proposta)
    return PropostaResponse.model_validate(proposta)


@router.get("", response_model=list[PropostaResponse])
async def list_propostas(
    lead_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = select(Proposta)
    if lead_id:
        query = query.where(Proposta.lead_id == lead_id)
    
    # Adicionando filtro por consultor para segurança (RBAC)
    if current_user.perfil == "consultor":
        query = query.where(Proposta.consultor_id == current_user.id)
        
    result = await db.execute(query)
    propostas = result.scalars().all()
    return [PropostaResponse.model_validate(p) for p in propostas]


@router.get("/{proposta_id}", response_model=PropostaResponse)
async def get_proposta(
    proposta_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(select(Proposta).where(Proposta.id == proposta_id))
    proposta = result.scalar_one_or_none()
    if not proposta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Proposta não encontrada",
        )

    # Scope check via the associated lead
    lead = await lead_service.get_lead_by_id(db, proposta.lead_id)
    if lead:
        check_lead_access(current_user, lead)

    return PropostaResponse.model_validate(proposta)


@router.put("/{proposta_id}", response_model=PropostaResponse)
async def update_proposta(
    proposta_id: uuid.UUID,
    body: PropostaUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(select(Proposta).where(Proposta.id == proposta_id))
    proposta = result.scalar_one_or_none()
    if not proposta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Proposta não encontrada",
        )

    # Scope check via the associated lead
    lead = await lead_service.get_lead_by_id(db, proposta.lead_id)
    if lead:
        check_lead_access(current_user, lead)

    for field, value in body.model_dump(exclude_none=True).items():
        setattr(proposta, field, value)

    # Lifecycle propagation: aprovada → lead fechado; recusada → lead proposta
    if body.status is not None:
        if body.status == PropostaStatus.aprovada:
            lead.status = LeadStatus.fechado.value
        elif body.status == PropostaStatus.recusada:
            lead.status = LeadStatus.proposta.value

    await db.commit()
    await db.refresh(proposta)
    return PropostaResponse.model_validate(proposta)
