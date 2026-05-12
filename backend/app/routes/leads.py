import uuid
from datetime import datetime
from typing import Optional

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.dto.lead_mapper import (
    map_counts_to_metrics,
    map_lead_to_detail,
    map_leads_to_cursor_response,
    map_leads_to_list_response,
)
from app.application.services.lead_state_machine import (
    InvalidStateTransitionError,
    LeadStateMachine,
)
from app.domain.entities.enums import LeadStatus
from app.infrastructure.cache.decorator import cached
from app.infrastructure.security.dependencies import (
    RequiresRole,
    get_current_user,
    get_db,
)
from app.infrastructure.security.pii_encryption import hmac_hash
from app.models.briefing import BriefingResponse, BriefingUpdate, calculate_completude
from app.models.interacao import InteracaoListResponse
from app.models.lead import Lead
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.presentation.schemas.leads import (
    LeadCreateRequest,
    LeadDetailDTO,
    LeadMetricsDTO,
    LeadPatchRequest,
    LeadUpdateRequest,
    ManualLeadCreate,
)
from app.services import lead_service

logger = structlog.get_logger()
router = APIRouter(
    prefix="/leads",
    tags=["Leads"],
)


# ── GET /leads ─────────────────────────────────────────────────────────────


@router.get(
    "",
    summary="Listar leads",
    description=(
        "Retorna leads paginados. Quando `cursor` é informado usa paginação keyset "
        "(cursor-based) e retorna `LeadCursorListResponseDTO`; caso contrário usa "
        "offset-based e retorna `LeadListResponseDTO`. "
        "Consultores visualizam apenas seus próprios leads; admin e agência visualizam todos."
    ),
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Perfil sem permissão", "model": HTTPErrorResponse},
    },
)
async def list_leads(
    # Filtros
    status: Optional[str] = Query(None, description="Filtro por status do lead"),
    score: Optional[str] = Query(None, description="Filtro por score (quente, morno, frio)"),
    search: Optional[str] = Query(None, description="Busca textual em nome ou telefone"),
    consultor_id: Optional[uuid.UUID] = Query(None, description="Filtro por consultor assignado"),
    data_inicio: Optional[datetime] = Query(None, description="Filtro: leads criados a partir desta data (ISO 8601)"),
    data_fim: Optional[datetime] = Query(None, description="Filtro: leads criados até esta data (ISO 8601)"),
    # Ordenação
    order_by: str = Query("criado_em", description="Campo de ordenação: criado_em | atualizado_em | score | status"),
    order_dir: str = Query("desc", description="Direção: asc | desc"),
    # Paginação offset (modo legado)
    page: int = Query(1, ge=1, description="Número da página (modo offset)"),
    limit: int = Query(20, ge=1, le=100, description="Itens por página (máx. 100)"),
    # Paginação cursor-based
    cursor: Optional[str] = Query(None, description="Cursor opaco para paginação keyset. Quando informado, ignora `page`."),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    # RBAC: consultor sees only own leads; admin/agencia sees all.
    effective_consultor_id = consultor_id
    if current_user.perfil == "consultor":
        effective_consultor_id = current_user.id

    if order_by not in ("criado_em", "atualizado_em", "score", "status"):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"order_by inválido: '{order_by}'. Use: criado_em, atualizado_em, score, status",
        )
    if order_dir not in ("asc", "desc"):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="order_dir deve ser 'asc' ou 'desc'",
        )

    if cursor is not None:
        try:
            items, next_cursor = await lead_service.list_leads_cursor(
                db,
                limit=limit,
                cursor=cursor,
                status=status,
                score=score,
                search=search,
                consultor_id=effective_consultor_id,
                data_inicio=data_inicio,
                data_fim=data_fim,
                order_by=order_by,
                order_dir=order_dir,
            )
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=str(exc),
            ) from exc
        return map_leads_to_cursor_response(items, next_cursor)

    leads, total = await lead_service.list_leads(
        db,
        status=status,
        score=score,
        search=search,
        page=page,
        limit=limit,
        consultor_id=effective_consultor_id,
        data_inicio=data_inicio,
        data_fim=data_fim,
        order_by=order_by,
        order_dir=order_dir,
    )
    return map_leads_to_list_response(leads, total=total, page=page, limit=limit)


# ── GET /leads/metrics ─────────────────────────────────────────────────────


@router.get(
    "/metrics",
    response_model=LeadMetricsDTO,
    summary="Métricas do dashboard de leads",
    description="Retorna contagens agregadas de leads por status para o dashboard administrativo. Cache de 60s.",
    dependencies=[Depends(RequiresRole("admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Perfil sem permissão", "model": HTTPErrorResponse},
    },
)
@cached(ttl=60)
async def get_lead_metrics(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    counts = await lead_service.get_lead_metrics(db)
    return map_counts_to_metrics(counts)


# ── GET /leads/my-active ───────────────────────────────────────────────────


@router.get(
    "/my-active",
    response_model=LeadDetailDTO,
    summary="Lead ativo do cliente logado",
    description=(
        "Retorna o lead associado ao telefone do usuário autenticado (perfil cliente). "
        "Se não existir, cria automaticamente um novo lead."
    ),
    responses={
        400: {"description": "Usuário sem telefone cadastrado", "model": HTTPErrorResponse},
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
    },
)
async def get_my_active_lead(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if not current_user.telefone:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Usuário não possui telefone cadastrado para vincular a uma viagem",
        )

    from sqlalchemy import select
    from sqlalchemy.orm import selectinload

    phone_hash = hmac_hash(current_user.telefone)
    result = await db.execute(
        select(Lead)
        .where(Lead.telefone_hash == phone_hash)
        .options(
            selectinload(Lead.briefing),
            selectinload(Lead.consultor),
            selectinload(Lead.propostas),
            selectinload(Lead.interacoes),
        )
    )
    lead = result.scalar_one_or_none()

    if not lead:
        lead = await lead_service.get_or_create_by_phone(
            db, current_user.telefone, current_user.nome
        )
        # reload with relationships
        lead = await lead_service.get_lead_by_id(db, lead.id)

    return map_lead_to_detail(lead)


# ── POST /leads ────────────────────────────────────────────────────────────


@router.post(
    "",
    response_model=LeadDetailDTO,
    summary="Criar ou atualizar lead (upsert por telefone)",
    description=(
        "Cria um novo lead. Se o telefone já existir, atualiza os dados do lead "
        "existente (upsert). Retorna 201 para criação e 200 para atualização. "
        "Use POST /leads/manual para criação com 409 em duplicata."
    ),
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Perfil sem permissão", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação no body", "model": HTTPErrorResponse},
    },
)
async def create_lead(
    lead_in: LeadCreateRequest,
    response: Response,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Upsert by phone — idempotent creation as required by the spec."""
    phone_hash = hmac_hash(lead_in.telefone)

    from sqlalchemy import select

    existing = (
        await db.execute(select(Lead).where(Lead.telefone_hash == phone_hash))
    ).scalar_one_or_none()

    if existing:
        # Update nome if provided and not set
        if lead_in.nome and not existing.nome:
            existing.nome = lead_in.nome
            await db.commit()
        lead = await lead_service.get_lead_by_id(db, existing.id)
        response.status_code = status.HTTP_200_OK
        return map_lead_to_detail(lead)

    lead = await lead_service.get_or_create_by_phone(db, lead_in.telefone, lead_in.nome)
    lead = await lead_service.get_lead_by_id(db, lead.id)
    return map_lead_to_detail(lead)


# ── POST /leads/manual ─────────────────────────────────────────────────────


@router.post(
    "/manual",
    response_model=LeadDetailDTO,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    summary="Criar lead manualmente",
    description="Criação manual de lead via App Agência com briefing inicial. Retorna 409 em caso de telefone duplicado (use force_create=true para forçar).",
)
async def create_manual_lead(
    lead_in: ManualLeadCreate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    try:
        if current_user.perfil == "consultor" and not lead_in.consultor_id:
            lead_in.consultor_id = current_user.id

        lead = await lead_service.create_manual_lead(db, lead_in)
        lead = await lead_service.get_lead_by_id(db, lead.id)
        return map_lead_to_detail(lead)
    except ValueError as e:
        if "DUPLICATE_LEAD" in str(e):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Este telefone já possui um lead ativo no sistema.",
            )
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


# ── GET /leads/{lead_id} ───────────────────────────────────────────────────


@router.get(
    "/{lead_id}",
    response_model=LeadDetailDTO,
    summary="Detalhes de um lead",
    description=(
        "Retorna os dados completos de um lead, incluindo briefing estruturado, "
        "últimas 10 interações e propostas vinculadas."
    ),
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para este lead", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
    },
)
async def get_lead(
    lead_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado"
        )

    if current_user.perfil == "consultor" and lead.consultor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado ao lead"
        )

    return map_lead_to_detail(lead)


# ── PUT /leads/{lead_id} ───────────────────────────────────────────────────


@router.put(
    "/{lead_id}",
    response_model=LeadDetailDTO,
    summary="Atualizar lead (replace)",
    description=(
        "Atualiza dados ou status de um lead. Transições de status são validadas pela máquina de estados. "
        "Ao atingir 'qualificado', o score é recalculado automaticamente com base no briefing."
    ),
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para este lead", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
        409: {"description": "Conflito de dados (ex: telefone duplicado)", "model": HTTPErrorResponse},
        422: {"description": "Transição de estado inválida ou erro de validação", "model": HTTPErrorResponse},
    },
)
async def update_lead(
    lead_id: uuid.UUID,
    lead_in: LeadUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado"
        )

    return await _apply_lead_update(db, lead, lead_in.model_dump(exclude_none=True))


# ── PATCH /leads/{lead_id} ─────────────────────────────────────────────────


@router.patch(
    "/{lead_id}",
    response_model=LeadDetailDTO,
    summary="Atualizar lead parcialmente (PATCH)",
    description=(
        "Atualiza parcialmente um lead: status, consultor assignado e/ou nome. "
        "Apenas os campos informados são alterados. Transições de status são validadas."
    ),
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para este lead", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
        422: {"description": "Transição de estado inválida ou erro de validação", "model": HTTPErrorResponse},
    },
)
async def patch_lead(
    lead_id: uuid.UUID,
    lead_in: LeadPatchRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado"
        )

    if current_user.perfil == "consultor" and lead.consultor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado ao lead"
        )

    return await _apply_lead_update(db, lead, lead_in.model_dump(exclude_none=True))


async def _apply_lead_update(db, lead: Lead, data: dict) -> LeadDetailDTO:
    """Shared update logic for PUT and PATCH endpoints."""
    if "status" in data:
        new_status = LeadStatus(data["status"])
        try:
            LeadStateMachine.validate_transition(lead.status, new_status)
            await lead_service.update_lead_status(
                db, lead, new_status, triggered_by="user_manual"
            )
        except InvalidStateTransitionError as exc:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=str(exc),
            ) from exc

        if new_status == LeadStatus.qualificado:
            from app.services.lead_service import calculate_score_from_briefing
            lead.score = calculate_score_from_briefing(lead.briefing)
            logger.info(
                "lead_auto_scored",
                lead_id=str(lead.id),
                score=lead.score.value if lead.score else None,
            )

        data.pop("status")

    for field, value in data.items():
        setattr(lead, field, value)

    await db.commit()
    await db.refresh(lead)
    # Reload with all relationships for the response
    lead = await lead_service.get_lead_by_id(db, lead.id)
    return map_lead_to_detail(lead)


# ── DELETE /leads/{lead_id} ────────────────────────────────────────────────


@router.delete(
    "/{lead_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Arquivar lead (soft delete)",
    description=(
        "Marca um lead como arquivado (soft delete). O campo `deletado_em` recebe o "
        "timestamp atual. O registro permanece no banco para auditoria."
    ),
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para este lead", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
    },
)
async def archive_lead(
    lead_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado"
        )

    # Scope Check
    if current_user.perfil == "consultor" and lead.consultor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado ao lead"
        )
    await lead_service.soft_delete(db, lead)


# ── GET /leads/{lead_id}/interacoes ───────────────────────────────────────


@router.get(
    "/{lead_id}/interacoes",
    response_model=InteracaoListResponse,
    summary="Histórico de interações do lead",
    description="Retorna todas as mensagens trocadas entre o cliente e a IA para um lead específico.",
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para este lead", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
    },
)
async def get_interacoes(
    lead_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado"
        )

    # Scope Check
    if current_user.perfil == "consultor" and lead.consultor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado ao lead"
        )
    from app.models.interacao import InteracaoResponse

    items = [InteracaoResponse.model_validate(i) for i in lead.interacoes]
    return InteracaoListResponse(items=items, total=len(items))


# ── GET /leads/{lead_id}/briefing ─────────────────────────────────────────


@router.get(
    "/{lead_id}/briefing",
    response_model=BriefingResponse,
    summary="Briefing estruturado do lead",
    description="Retorna os dados do briefing coletados automaticamente pela IA durante as conversas.",
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para este lead", "model": HTTPErrorResponse},
        404: {"description": "Lead ou briefing não encontrado", "model": HTTPErrorResponse},
    },
)
async def get_briefing(
    lead_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead or not lead.briefing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Briefing não encontrado"
        )

    # Scope Check
    if current_user.perfil == "consultor" and lead.consultor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado ao lead"
        )
    return BriefingResponse.model_validate(lead.briefing)


# ── PUT /leads/{lead_id}/briefing ─────────────────────────────────────────


@router.put(
    "/{lead_id}/briefing",
    response_model=BriefingResponse,
    summary="Atualizar briefing",
    description="Permite ao consultor editar manualmente campos do briefing e recalcula o percentual de completude.",
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para este lead", "model": HTTPErrorResponse},
        404: {"description": "Lead ou briefing não encontrado", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação nos dados do briefing", "model": HTTPErrorResponse},
    },
)
async def update_briefing(
    lead_id: uuid.UUID,
    briefing_in: BriefingUpdate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead or not lead.briefing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Briefing não encontrado"
        )

    # Scope Check
    if current_user.perfil == "consultor" and lead.consultor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado ao lead"
        )

    briefing = lead.briefing
    for field, value in briefing_in.model_dump(exclude_none=True).items():
        setattr(briefing, field, value)
    briefing.completude_pct = calculate_completude(briefing.__dict__)
    await db.commit()
    await db.refresh(briefing)
    return BriefingResponse.model_validate(briefing)
