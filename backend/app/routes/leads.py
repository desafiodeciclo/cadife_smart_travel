import uuid
from typing import Optional

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.dto.lead_mapper import (
    map_counts_to_metrics,
    map_lead_to_detail,
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
from app.models.briefing import BriefingResponse, BriefingUpdate, calculate_completude
from app.models.interacao import InteracaoListResponse
from app.models.lead import Lead
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.presentation.schemas.leads import (
    AyaToggleRequest,
    AyaToggleResponseDTO,
    LeadCreateRequest,
    LeadDetailDTO,
    LeadListResponseDTO,
    LeadMetricsDTO,
    LeadUpdateRequest,
    ManualLeadCreate,
)
from app.services import lead_service

logger = structlog.get_logger()
router = APIRouter(
    prefix="/leads",
    tags=["Leads"],
)


# ── Cache helpers ──────────────────────────────────────────────────────────
# We apply @cached on lightweight service calls that only touch the DB.
# The decorator serialises the Pydantic response so FastAPI can re-validate it.


@router.get(
    "",
    response_model=LeadListResponseDTO,
    summary="Listar leads",
    description=(
        "Retorna leads paginados com suporte a filtros por status, score e busca textual. "
        "Consultores visualizam apenas seus próprios leads; admin e agência visualizam todos."
    ),
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Perfil sem permissão", "model": HTTPErrorResponse},
    },
)
@cached()
async def list_leads(
    status: Optional[str] = Query(None, description="Filtro por status do lead"),
    score: Optional[str] = Query(None, description="Filtro por score (quente, morno, frio)"),
    search: Optional[str] = Query(None, description="Busca textual em nome ou telefone"),
    page: int = Query(1, ge=1, description="Número da página"),
    limit: int = Query(20, ge=1, le=100, description="Itens por página (máx. 100)"),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    # RBAC: consultor sees only own leads; admin/agencia sees all.
    consultor_id = None
    if current_user.perfil == "consultor":
        consultor_id = current_user.id

    leads, total = await lead_service.list_leads(
        db,
        status=status,
        score=score,
        search=search,
        page=page,
        limit=limit,
        consultor_id=consultor_id,
    )
    return map_leads_to_list_response(leads, total=total, page=page, limit=limit)


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
    """Dashboard metrics — aggregated lead counts by status."""
    counts = await lead_service.get_lead_metrics(db)
    return map_counts_to_metrics(counts)


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
    """
    Retorna o lead associado ao usuário logado (cliente).
    Se não existir, cria um novo lead baseado no telefone do usuário.
    """
    if not current_user.telefone:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Usuário não possui telefone cadastrado para vincular a uma viagem",
        )

    from sqlalchemy import select
    from sqlalchemy.orm import selectinload
    from app.infrastructure.security.pii_encryption import hmac_hash

    phone_hash = hmac_hash(current_user.telefone)
    result = await db.execute(
        select(Lead)
        .where(Lead.telefone_hash == phone_hash)
        .options(selectinload(Lead.consultor))
    )
    lead = result.scalar_one_or_none()

    if not lead:
        lead = await lead_service.get_or_create_by_phone(
            db, current_user.telefone, current_user.nome
        )

    return map_lead_to_detail(lead)


@router.post(
    "",
    response_model=LeadDetailDTO,
    status_code=status.HTTP_201_CREATED,
    summary="Criar lead",
    description="Cria um novo lead manualmente. Caso o telefone já exista, retorna 409 Conflict.",
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Perfil sem permissão", "model": HTTPErrorResponse},
        409: {"description": "Telefone já cadastrado", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação no body", "model": HTTPErrorResponse},
    },
)
async def create_lead(
    lead_in: LeadCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    from sqlalchemy import select

    existing = await db.execute(select(Lead).where(Lead.telefone == lead_in.telefone))
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="Telefone já cadastrado"
        )

    lead = await lead_service.get_or_create_by_phone(db, lead_in.telefone, lead_in.nome)
    return map_lead_to_detail(lead)


@router.post(
    "/manual",
    response_model=LeadDetailDTO,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
)
async def create_manual_lead(
    lead_in: ManualLeadCreate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """
    Criação manual de lead via App Agência.
    Permite preenchimento de briefing inicial e atribuição de consultor.
    """
    try:
        # Se for um consultor criando, já atribuímos ele como responsável automaticamente
        if current_user.perfil == "consultor" and not lead_in.consultor_id:
            lead_in.consultor_id = current_user.id

        lead = await lead_service.create_manual_lead(db, lead_in)
        return map_lead_to_detail(lead)
    except ValueError as e:
        if "DUPLICATE_LEAD" in str(e):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Este telefone já possui um lead ativo no sistema.",
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )



@router.get(
    "/{lead_id}",
    response_model=LeadDetailDTO,
    summary="Detalhes de um lead",
    description="Retorna os dados completos de um lead específico, incluindo propostas vinculadas.",
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para este lead", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
    },
)
@cached()
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

    # Scope Check
    if current_user.perfil == "consultor" and lead.consultor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado ao lead"
        )

    return map_lead_to_detail(lead)


@router.put(
    "/{lead_id}",
    response_model=LeadDetailDTO,
    summary="Atualizar lead",
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

    # Scope Check
    if current_user.perfil == "consultor" and lead.consultor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado ao lead"
        )

    data = lead_in.model_dump(exclude_none=True)

    # ── State Machine validation ──────────────────────────────────────────
    if "status" in data:
        new_status = LeadStatus(data["status"])
        try:
            LeadStateMachine.validate_transition(lead.status, new_status)
            await lead_service.update_lead_status(
                db, lead, new_status, triggered_by="user_manual"
            )
        except InvalidStateTransitionError as exc:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
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
    return map_lead_to_detail(lead)


@router.delete(
    "/{lead_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Arquivar lead (soft delete)",
    description="Marca um lead como arquivado (soft delete). O registro permanece no banco para auditoria.",
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


@router.patch(
    "/{lead_id}/aya-toggle",
    response_model=AyaToggleResponseDTO,
    summary="Ativar ou desativar a AYA para um lead",
    description=(
        "Permite ao consultor pausar o atendimento da IA para uma conversa específica. "
        "Quando desativada (ativo=false): mensagens são persistidas no log mas não processadas pela IA. "
        "Quando reativada (ativo=true): AYA retoma com contexto das últimas mensagens. "
        "Cada toggle é registrado em aya_toggle_history para auditoria."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para este lead", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
    },
)
async def toggle_aya(
    lead_id: uuid.UUID,
    body: AyaToggleRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
    _: None = Depends(RequiresRole("consultor", "admin", "agencia")),
) -> AyaToggleResponseDTO:
    from datetime import datetime, timezone
    from app.infrastructure.persistence.models.aya_toggle_history_model import AyaToggleHistoryModel
    from app.infrastructure.config.settings import get_settings

    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")

    if current_user.perfil == "consultor" and lead.consultor_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado ao lead")

    lead.aya_ativo = body.ativo

    history = AyaToggleHistoryModel(
        lead_id=lead_id,
        ativo=body.ativo,
        motivo=body.motivo,
        alterado_por=current_user.id,
    )
    db.add(history)
    await db.commit()
    await db.refresh(history)

    settings = get_settings()
    recentes = await lead_service.get_recent_interacoes(db, lead_id, limit=settings.AYA_CONTEXT_MSGS)

    logger.info(
        "aya_toggled",
        lead_id=str(lead_id),
        aya_ativo=body.ativo,
        alterado_por=str(current_user.id),
        motivo=body.motivo,
    )

    return AyaToggleResponseDTO(
        lead_id=lead_id,
        aya_ativo=body.ativo,
        motivo=body.motivo,
        alterado_em=history.alterado_em,
        contexto_msgs_count=len(recentes),
    )


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
