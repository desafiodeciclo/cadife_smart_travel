import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, get_db
from app.models.proposta import Proposta, PropostaCreate, PropostaResponse, PropostaUpdate

router = APIRouter(prefix="/propostas", tags=["Propostas"])


@router.post("", response_model=PropostaResponse, status_code=status.HTTP_201_CREATED)
async def create_proposta(
    body: PropostaCreate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
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
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Proposta não encontrada")
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
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Proposta não encontrada")

    for field, value in body.model_dump(exclude_none=True).items():
        setattr(proposta, field, value)
    await db.commit()
    await db.refresh(proposta)
    return PropostaResponse.model_validate(proposta)
