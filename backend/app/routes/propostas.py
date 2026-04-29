import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, get_db
from app.infrastructure.security.dependencies import RequiresRole
from app.domain.entities.enums import LeadStatus, PropostaStatus
from app.models.proposta import Proposta, PropostaCreate, PropostaResponse, PropostaUpdate
from app.services import lead_service

router = APIRouter(
    prefix="/propostas",
    tags=["Propostas"],
    dependencies=[Depends(RequiresRole("consultor", "admin"))],
)


def _check_lead_access(current_user, lead) -> None:
    """Raise 403 if the current user is not allowed to access the lead."""
    if current_user.perfil == "consultor" and lead.consultor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso negado ao lead",
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
    current_user=Depends(get_current_user),
):
    # 1. Validate lead exists
    lead = await lead_service.get_lead_by_id(db, body.lead_id)
    if not lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lead não encontrado",
        )

    # 2. Scope check: consultor can only create proposals for their own leads
    _check_lead_access(current_user, lead)

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
    )
    db.add(proposta)
    await db.commit()
    await db.refresh(proposta)
    return PropostaResponse.model_validate(proposta)


@router.get("/{proposta_id}", response_model=PropostaResponse)
async def get_proposta(
    proposta_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
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
        _check_lead_access(current_user, lead)

    return PropostaResponse.model_validate(proposta)


@router.put("/{proposta_id}", response_model=PropostaResponse)
async def update_proposta(
    proposta_id: uuid.UUID,
    body: PropostaUpdate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
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
        _check_lead_access(current_user, lead)

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
