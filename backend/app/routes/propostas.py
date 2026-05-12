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
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.services import lead_service
from app.services.fcm_service import send_push_notification

router = APIRouter(
    prefix="/propostas",
    tags=["Propostas"],
    dependencies=[Depends(RequiresRole("consultor", "admin"))],
)


@router.post(
    "",
    response_model=PropostaResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Criar proposta",
    description=(
        "Cria uma nova proposta vinculada a um lead. O lead deve estar nos status qualificado, agendado ou proposta. "
        "Consultores só podem criar propostas para seus próprios leads."
    ),
    dependencies=[Depends(RequiresRole("consultor", "admin"))],
    responses={
        400: {"description": "Lead em status inadequado para proposta", "model": HTTPErrorResponse},
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para o lead", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação no body", "model": HTTPErrorResponse},
    },
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

    # Notify client about new proposal (best-effort)
    client_token = await lead_service._get_client_fcm_token(db, lead)
    if client_token:
        await send_push_notification(
            fcm_token=client_token,
            title="Proposta de viagem criada!",
            body="Verifique os detalhes no app",
            data={"type": "proposal_created", "proposal_id": str(proposta.id)},
        )

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


@router.get(
    "/{proposta_id}",
    response_model=PropostaResponse,
    summary="Detalhes de uma proposta",
    description="Retorna os dados completos de uma proposta, com verificação de acesso via lead associado.",
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para o lead vinculado", "model": HTTPErrorResponse},
        404: {"description": "Proposta não encontrada", "model": HTTPErrorResponse},
    },
)
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


@router.put(
    "/{proposta_id}",
    response_model=PropostaResponse,
    summary="Atualizar proposta",
    description=(
        "Atualiza dados ou status de uma proposta. Aprovação (aprovada) propaga o lead para fechado; "
        "recusa (recusada) retorna o lead para proposta."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para o lead vinculado", "model": HTTPErrorResponse},
        404: {"description": "Proposta não encontrada", "model": HTTPErrorResponse},
        422: {"description": "Status inválido ou erro de validação", "model": HTTPErrorResponse},
    },
)
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
    # Using update_lead_status so FCM notifications are sent to the client.
    if body.status is not None and lead is not None:
        if body.status == PropostaStatus.aprovada:
            await lead_service.update_lead_status(
                db, lead, LeadStatus.fechado, triggered_by="proposta_aprovada"
            )
        elif body.status == PropostaStatus.recusada:
            await lead_service.update_lead_status(
                db, lead, LeadStatus.proposta, triggered_by="proposta_recusada"
            )

    await db.commit()
    await db.refresh(proposta)
    return PropostaResponse.model_validate(proposta)
