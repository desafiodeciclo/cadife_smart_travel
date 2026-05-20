"""
Admin Routes — FastAPI router for admin user and lead management.
====================================================================
All endpoints require JWT authentication and ADMIN role.
"""

import uuid
from typing import Optional

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.security.dependencies import RequiresRole, get_current_user, get_db
from app.presentation.schemas.admin_schema import (
    AdminAutoAssignOrphansResponse,
    AdminLeadReassignRequest,
    AdminLeadReassignResponse,
    AdminUserCreate,
    AdminUserListResponse,
    AdminUserResponse,
    AdminUserUpdate,
    AgenciaMetricsResponse,
)
from app.services import lead_assignment_service
from app.domain.entities.enums import UserPerfil
from app.models.lead import Lead
from app.models.user import User
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.services import admin_service
from app.services.user_service import get_user_by_id
from app.services.lead_service import get_lead_by_id

logger = structlog.get_logger()
router = APIRouter(prefix="/admin", tags=["Admin"])


def _map_user_to_response(user: User, metrics) -> AdminUserResponse:
    return AdminUserResponse(
        id=user.id,
        nome=user.nome,
        email=user.email,
        telefone=user.telefone,
        perfil=user.perfil,
        is_active=user.is_active,
        criado_em=user.criado_em,
        metrics=metrics,
    )


@router.post(
    "/users",
    response_model=AdminUserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Criar consultor",
    description="Cria um novo consultor com senha temporária e envia e-mail de boas-vindas.",
    dependencies=[Depends(RequiresRole("admin"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        409: {"description": "E-mail já cadastrado", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação", "model": HTTPErrorResponse},
    },
)
async def create_user(
    body: AdminUserCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        user, _ = await admin_service.create_consultor(
            db=db,
            nome=body.nome,
            email=body.email,
            telefone=body.telefone,
            role=body.role,
        )
    except ValueError as exc:
        error = str(exc)
        if "DUPLICATE_EMAIL" in error:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="E-mail já cadastrado",
            )
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail=error,
        )

    return _map_user_to_response(user, admin_service.AdminUserMetrics())


@router.get(
    "/users",
    response_model=AdminUserListResponse,
    summary="Listar consultores",
    description="Lista todos os consultores com status (ativo/inativo) e métricas resumidas.",
    dependencies=[Depends(RequiresRole("admin"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
    },
)
async def list_users(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    results = await admin_service.list_consultores(db)
    items = [
        _map_user_to_response(r["user"], r["metrics"])
        for r in results
    ]
    return AdminUserListResponse(items=items, total=len(items))


@router.get(
    "/metrics",
    response_model=AgenciaMetricsResponse,
    summary="Métricas agregadas da agência",
    description=(
        "Agregação global de leads (todos os consultores), receita realizada via "
        "propostas aprovadas em leads fechados, e janela de 30 dias para "
        "novos/fechados/perdidos."
    ),
    dependencies=[Depends(RequiresRole("admin"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
    },
)
async def get_agency_metrics(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AgenciaMetricsResponse:
    return await admin_service.agency_metrics(db)


@router.patch(
    "/users/{user_id}",
    response_model=AdminUserResponse,
    summary="Editar consultor",
    description="Edita dados do consultor ou desativa a conta (is_active = false).",
    dependencies=[Depends(RequiresRole("admin"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Consultor não encontrado", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação", "model": HTTPErrorResponse},
    },
)
async def update_user(
    user_id: uuid.UUID,
    body: AdminUserUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    user = await get_user_by_id(db, str(user_id))
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consultor não encontrado",
        )

    updated = await admin_service.update_consultor(
        db=db,
        user=user,
        nome=body.nome,
        email=body.email,
        telefone=body.telefone,
        is_active=body.is_active,
    )
    return _map_user_to_response(updated, admin_service.AdminUserMetrics())


@router.delete(
    "/users/{user_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Desativar consultor (soft delete)",
    description=(
        "Desativa a conta do consultor. "
        "Pode reatribuir leads ativos para outro consultor via query param."
    ),
    dependencies=[Depends(RequiresRole("admin"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Consultor não encontrado", "model": HTTPErrorResponse},
        422: {"description": "Consultor de destino inválido", "model": HTTPErrorResponse},
    },
)
async def delete_user(
    user_id: uuid.UUID,
    reassign_to: Optional[uuid.UUID] = Query(None, description="ID do consultor para reatribuir leads ativos"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    user = await get_user_by_id(db, str(user_id))
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Consultor não encontrado",
        )

    try:
        await admin_service.soft_delete_consultor(db, user, reassign_to_id=reassign_to)
    except ValueError as exc:
        error = str(exc)
        if "TARGET_CONSULTOR_NOT_FOUND" in error:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="Consultor de destino não encontrado ou inativo",
            )
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail=error,
        )
    return None


@router.post(
    "/leads/auto-assign-orphans",
    response_model=AdminAutoAssignOrphansResponse,
    summary="Atribuir leads órfãos via round-robin",
    description=(
        "Varre todos os leads com consultor_id IS NULL (não arquivados, não "
        "deletados) e atribui em batch ao próximo consultor ativo via "
        "round-robin. Retorna contagem de atribuídos e pulados."
    ),
    dependencies=[Depends(RequiresRole("admin"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
    },
)
async def auto_assign_orphan_leads(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AdminAutoAssignOrphansResponse:
    result = await lead_assignment_service.auto_assign_orphans(db)
    return AdminAutoAssignOrphansResponse(
        assigned=result["assigned"],
        skipped=result["skipped"],
        no_consultor_available=result["no_consultor_available"],
    )


@router.patch(
    "/leads/{lead_id}/reassign",
    response_model=AdminLeadReassignResponse,
    summary="Reatribuir lead",
    description="Reatribui um lead para outro consultor com notificação push para ambos.",
    dependencies=[Depends(RequiresRole("admin"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação (mesmo consultor ou destino inválido)", "model": HTTPErrorResponse},
    },
)
async def reassign_lead(
    lead_id: uuid.UUID,
    body: AdminLeadReassignRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    lead = await get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lead não encontrado",
        )

    try:
        result = await admin_service.reassign_lead(db, lead, body.new_consultor_id)
    except ValueError as exc:
        error = str(exc)
        if "SAME_CONSULTOR" in error:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="O lead já pertence ao consultor de destino",
            )
        if "TARGET_CONSULTOR_NOT_FOUND" in error:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="Consultor de destino não encontrado ou inativo",
            )
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail=error,
        )

    return AdminLeadReassignResponse(
        lead_id=result["lead_id"],
        old_consultor_id=result["old_consultor_id"],
        new_consultor_id=result["new_consultor_id"],
    )
