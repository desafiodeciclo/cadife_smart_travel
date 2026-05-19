import math
import uuid
from datetime import datetime, timezone
from typing import Any, Optional

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.presentation.schemas.checkpoints import (
    CheckpointActivateRequest,
    CheckpointListResponse,
    CheckpointResponse,
)
from app.services import checkpoint_service
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
from app.domain.entities.enums import LeadStatus, TipoMensagem
from app.infrastructure.cache.decorator import cached
from app.infrastructure.security.dependencies import (
    RequiresRole,
    get_current_user,
    get_db,
)
from app.infrastructure.security.pii_encryption import hmac_hash
from app.domain.services.briefing_calculator import calculate_completude
from app.presentation.schemas.briefing_schema import BriefingResponse, BriefingUpdate
from app.presentation.schemas.conversation_summary_schema import (
    ConversationSummaryListResponse,
    ConversationSummaryResponse,
)
from app.presentation.schemas.interacao_schema import InteracaoListResponse
from app.infrastructure.persistence.repositories.conversation_summary_repository import (
    ConversationSummaryRepository,
)
from app.models.lead import Lead
from app.models.user import User
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.presentation.schemas.leads import (
    AyaToggleRequest,
    AyaToggleResponseDTO,
    LeadCreateRequest,
    LeadCursorListResponseDTO,
    LeadDetailDTO,
    LeadListResponseDTO,
    LeadMetricsDTO,
    LeadPatchRequest,
    LeadUpdateRequest,
    ManualLeadCreate,
)
from app.services import lead_service
from app.infrastructure.persistence.models.aya_toggle_history_model import AyaToggleHistoryModel
from app.infrastructure.config.settings import get_settings as get_infra_settings

logger = structlog.get_logger()
router = APIRouter(
    prefix="/leads",
    tags=["Leads"],
)

# ── GET /leads (Offset-based + Cursor-based + Filtros) ─────────────────────

@router.get(
    "",
    summary="Listar leads com paginação (offset ou cursor) e filtros",
    description=(
        "Retorna leads ativos com paginação offset-based (page/size) ou cursor-based, "
        "filtros por status, score, consultor assignado, período de data e busca textual. "
        "Use `page` para paginação tradicional; use `cursor` para navegação sem page-drift."
    ),
    response_model=None,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        200: {
            "description": "Lista paginada de leads",
            "content": {
                "application/json": {
                    "schema": {
                        "oneOf": [
                            LeadListResponseDTO.model_json_schema(),
                            LeadCursorListResponseDTO.model_json_schema(),
                        ]
                    }
                }
            },
        },
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
    },
)
async def list_leads(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
    page: Optional[int] = Query(None, ge=1, description="Número da página (modo offset-based)"),
    size: int = Query(10, ge=1, le=100, description="Itens por página"),
    limit: int = Query(20, ge=1, le=100, description="Alias para size (cursor-based)"),
    cursor: Optional[str] = Query(None, description="Cursor para paginação cursor-based"),
    status: Optional[str] = Query(None),
    score: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    consultor_id: Optional[uuid.UUID] = Query(None),
    data_inicio: Optional[datetime] = Query(None),
    data_fim: Optional[datetime] = Query(None),
    order_by: str = Query("criado_em"),
    order_dir: str = Query("desc"),
) -> Any:
    # ── Offset-based pagination (page/size) ────────────────────────────────
    if page is not None:
        items, total = await lead_service.list_leads(
            db,
            status=status,
            score=score,
            search=search,
            page=page,
            limit=size,
            consultor_id=consultor_id,
            data_inicio=data_inicio,
            data_fim=data_fim,
            order_by=order_by,
            order_dir=order_dir,
        )
        return map_leads_to_list_response(items, total, page, size)

    # ── Cursor-based pagination (cursor/limit) ─────────────────────────────
    items, next_cursor = await lead_service.list_leads_cursor(
        db,
        limit=limit,
        cursor=cursor,
        status=status,
        score=score,
        search=search,
        consultor_id=consultor_id,
        data_inicio=data_inicio,
        data_fim=data_fim,
        order_by=order_by,
        order_dir=order_dir,
    )
    return map_leads_to_cursor_response(items, next_cursor)


# ── GET /leads/{id} ────────────────────────────────────────────────────────

@router.get(
    "/{lead_id}",
    summary="Obter detalhes completos de um lead",
    description=(
        "Retorna o lead com todos os relacionamentos carregados: briefing completo, "
        "histórico de score, últimas 10 interações, propostas e dados do consultor assignado."
    ),
    response_model=LeadDetailDTO,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
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
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")
    return map_lead_to_detail(lead)


# ── GET /leads/{id}/checkpoints ────────────────────────────────────────────

@router.get(
    "/{lead_id}/checkpoints",
    response_model=CheckpointListResponse,
    summary="Listar checkpoints de um lead",
    description=(
        "Retorna lista de checkpoints (marcos de viagem) ativados para este lead, "
        "ordenados por data de ativação. Usados no acompanhamento de status da viagem."
    ),
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
    },
)
async def list_lead_checkpoints(
    lead_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
) -> CheckpointListResponse:
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")
    records = await checkpoint_service.get_checkpoints(db, lead_id)
    return CheckpointListResponse(
        checkpoints=[CheckpointResponse.model_validate(r) for r in records],
        total=len(records),
    )


# ── GET /leads/metrics ─────────────────────────────────────────────────────

@router.get(
    "/metrics",
    response_model=LeadMetricsDTO,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
)
async def get_lead_metrics(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    counts = await lead_service.get_lead_metrics(db)
    return map_counts_to_metrics(counts)


# ── POST /leads (Upsert) ───────────────────────────────────────────────────

@router.post(
    "",
    # ... metadata ...
)
async def create_lead(
    lead_in: LeadCreateRequest,
    response: Response,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    phone_hash = hmac_hash(lead_in.telefone)
    existing = (await db.execute(select(Lead).where(Lead.telefone_hash == phone_hash))).scalar_one_or_none()

    if existing:
        if lead_in.nome and not existing.nome:
            existing.nome = lead_in.nome
            await db.commit()
        lead = await lead_service.get_lead_by_id(db, existing.id)
        response.status_code = status.HTTP_200_OK
        return map_lead_to_detail(lead)

    lead = await lead_service.get_or_create_by_phone(db, lead_in.telefone, lead_in.nome)
    lead = await lead_service.get_lead_by_id(db, lead.id)
    return map_lead_to_detail(lead)

# ── LOGICA DE UPDATE UNIFICADA ─────────────────────────────────────────────

async def _apply_lead_update(db: AsyncSession, lead: Lead, data: dict) -> LeadDetailDTO:
    """Lógica compartilhada para PUT e PATCH, integrando scoring automático."""
    if "status" in data:
        new_status = LeadStatus(data["status"])
        try:
            LeadStateMachine.validate_transition(lead.status, new_status)
            await lead_service.update_lead_status(db, lead, new_status, triggered_by="user_manual")
        except InvalidStateTransitionError as exc:
            raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))

        # Integração das duas branches: Se qualificado, calcula e persiste o score histórico
        if new_status == LeadStatus.qualificado:
            # Chama a persistência de histórico (branch developer) 
            # que utiliza o cálculo do briefing (branch feat)
            await lead_service.persist_score(db, lead, motivo="auto")
            logger.info(
                "lead_auto_scored",
                lead_id=str(lead.id),
                status=lead.status.value,
                score_numerico=lead.score_numerico,
                score_label=lead.score.value if lead.score else None,
            )
        data.pop("status")

    for field, value in data.items():
        setattr(lead, field, value)

    await db.commit()
    await db.refresh(lead)
    lead = await lead_service.get_lead_by_id(db, lead.id)
    return map_lead_to_detail(lead)

# ── PATCH /leads/{id} ──────────────────────────────────────────────────────

@router.patch(
    "/{lead_id}",
    summary="Atualizar lead parcialmente",
    description=(
        "Permite atualizar status, consultor assignado, nome e score de um lead. "
        "Transições de status são validadas pela máquina de estados (ex: NOVO → FECHADO é proibido). "
        "Se o status mudar para QUALIFICADO, o score numérico é recalculado e persistido automaticamente."
    ),
    response_model=LeadDetailDTO,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
        422: {"description": "Transição de status inválida", "model": HTTPErrorResponse},
    },
)
async def patch_lead(
    lead_id: uuid.UUID,
    body: LeadPatchRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")
    return await _apply_lead_update(db, lead, body.model_dump(exclude_unset=True))


# ── DELETE /leads/{id} (Soft Delete) ───────────────────────────────────────

@router.delete(
    "/{lead_id}",
    summary="Remover lead (soft-delete)",
    description=(
        "Realiza soft-delete do lead, preenchendo o campo 'deletado_em' e arquivando-o. "
        "O lead nunca é removido fisicamente do banco, garantindo auditoria e rastreabilidade completa."
    ),
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
    },
)
async def delete_lead(
    lead_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")
    await lead_service.soft_delete(db, lead)
    return None


# ── NOVOS ENDPOINTS (Aya e Checkpoints) ───────────────────────────────────

@router.patch(
    "/{lead_id}/aya-toggle",
    response_model=AyaToggleResponseDTO,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
)
async def toggle_aya(
    lead_id: uuid.UUID,
    body: AyaToggleRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
) -> AyaToggleResponseDTO:
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")

    lead.aya_ativo = body.ativo
    history = AyaToggleHistoryModel(
        lead_id=lead_id, ativo=body.ativo, motivo=body.motivo, alterado_por=current_user.id
    )
    db.add(history)
    await db.commit()

    settings = get_infra_settings()
    recentes = await lead_service.get_recent_interacoes(db, lead_id, limit=settings.AYA_CONTEXT_MSGS)

    return AyaToggleResponseDTO(
        lead_id=lead_id,
        aya_ativo=body.ativo,
        motivo=body.motivo,
        alterado_em=datetime.now(timezone.utc),
        contexto_msgs_count=len(recentes),
    )

@router.post(
    "/{lead_id}/checkpoints",
    response_model=CheckpointResponse,
    dependencies=[Depends(RequiresRole("consultor", "admin"))],
)
async def activate_checkpoint(
    lead_id: uuid.UUID,
    body: CheckpointActivateRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    # Lógica vinda da branch feat/lead-database-registration-flow
    record = await checkpoint_service.activate_checkpoint(
        db, lead_id, body.checkpoint, str(current_user.id)
    )
    return CheckpointResponse.model_validate(record)


# ── GET /leads/my-active ───────────────────────────────────────────────────

@router.get(
    "/my-active",
    summary="Lead ativo do cliente autenticado",
    description="Retorna o lead em andamento associado ao cliente autenticado.",
    response_model=LeadDetailDTO,
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        404: {"description": "Nenhum lead ativo encontrado", "model": HTTPErrorResponse},
    },
)
async def get_my_active_lead(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    terminal_statuses = [LeadStatus.fechado.value, LeadStatus.perdido.value]
    stmt = (
        select(Lead)
        .where(
            Lead.client_id == current_user.id,
            Lead.is_archived.is_(False),
            Lead.status.notin_(terminal_statuses),
        )
        .order_by(Lead.atualizado_em.desc())
        .limit(1)
    )
    result = await db.execute(stmt)
    raw_lead = result.scalar_one_or_none()
    if not raw_lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Nenhum lead ativo encontrado para o utilizador atual.",
        )
    lead = await lead_service.get_lead_by_id(db, raw_lead.id)
    return map_lead_to_detail(lead)


# ── POST /leads/manual ─────────────────────────────────────────────────────

@router.post(
    "/manual",
    summary="Criar lead manualmente",
    description="Permite a criação manual de leads que não vieram do canal WhatsApp.",
    response_model=LeadDetailDTO,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        201: {"description": "Lead criado com sucesso"},
        409: {"description": "Lead com este telefone já existe", "model": HTTPErrorResponse},
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
    },
)
async def create_manual_lead(
    body: ManualLeadCreate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if body.consultor_id is None:
        body = body.model_copy(update={"consultor_id": current_user.id})
    try:
        lead = await lead_service.create_manual_lead(db, body)
    except ValueError as exc:
        msg = str(exc)
        if msg.startswith("DUPLICATE_LEAD:"):
            lead_id = msg.split(":")[1]
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Lead com este telefone já existe. ID: {lead_id}",
            )
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=msg)
    lead = await lead_service.get_lead_by_id(db, lead.id)
    return map_lead_to_detail(lead)


class ManualInteracaoRequest(BaseModel):
    descricao: str
    tipo: Optional[str] = "nota_manual"

    model_config = {"extra": "forbid"}


class ReassignRequest(BaseModel):
    consultant_id: uuid.UUID

    model_config = {"extra": "forbid"}


# ── POST /leads/{id}/interacao ─────────────────────────────────────────────


@router.post(
    "/{lead_id}/interacao",
    summary="Registrar interação manual",
    description="Adiciona nota ou registo manual de interação fora do sistema (ex: telefonema, reunião) na timeline do lead.",
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        201: {"description": "Interação registada com sucesso"},
        403: {"description": "Sem permissão sobre este lead", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
    },
)
async def create_interacao(
    lead_id: uuid.UUID,
    body: ManualInteracaoRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")

    is_owner = lead.consultor_id == current_user.id
    is_admin = current_user.perfil in ("admin", "agencia")
    if not is_owner and not is_admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Sem permissão sobre este lead")

    tipo_enum = TipoMensagem.nota_manual
    try:
        tipo_enum = TipoMensagem(body.tipo)
    except ValueError:
        pass

    interacao = await lead_service.save_interacao(
        db,
        lead_id=lead_id,
        msg_cliente=body.descricao,
        msg_ia=None,
        tipo=tipo_enum,
    )
    return {"message": "Interação registada com sucesso", "interaction_id": str(interacao.id)}


# ── PATCH /leads/{id}/reassign ─────────────────────────────────────────────

@router.patch(
    "/{lead_id}/reassign",
    summary="Reatribuir lead a outro consultor",
    description="Permite a reatribuição de um lead a outro consultor. Requer perfil admin ou agencia.",
    response_model=LeadDetailDTO,
    dependencies=[Depends(RequiresRole("admin", "agencia"))],
    responses={
        200: {"description": "Lead reatribuído com sucesso"},
        400: {"description": "Consultor inválido ou inativo", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para reatribuir", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
    },
)
async def reassign_lead(
    lead_id: uuid.UUID,
    body: ReassignRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")

    result = await db.execute(
        select(User).where(User.id == body.consultant_id, User.is_active.is_(True))
    )
    new_consultor = result.scalar_one_or_none()
    if not new_consultor:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Consultor não encontrado ou inativo",
        )

    old_consultor_id = lead.consultor_id
    lead.consultor_id = body.consultant_id
    await db.commit()

    await lead_service.save_interacao(
        db,
        lead_id=lead_id,
        msg_cliente=None,
        msg_ia=(
            f"[SISTEMA] Lead reatribuído de {old_consultor_id} para {body.consultant_id} "
            f"por {current_user.id} ({current_user.perfil})."
        ),
        tipo=TipoMensagem.nota_manual,
    )

    lead = await lead_service.get_lead_by_id(db, lead_id)
    return map_lead_to_detail(lead)


# ── GET /leads/{id}/conversation-summary ──────────────────────────────────

@router.get(
    "/{lead_id}/conversation-summary",
    summary="Resumo de conversa mais recente",
    description="Retorna o último resumo de conversa gerado para o lead.",
    response_model=ConversationSummaryResponse,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
    responses={
        404: {"description": "Nenhum resumo encontrado", "model": HTTPErrorResponse},
    },
)
async def get_latest_conversation_summary(
    lead_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")

    repo = ConversationSummaryRepository(db)
    summary = await repo.get_latest_by_lead(lead_id)
    if not summary:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Nenhum resumo de conversa encontrado para este lead.",
        )
    return ConversationSummaryResponse.model_validate(summary)


# ── GET /leads/{id}/conversation-summaries ────────────────────────────────

@router.get(
    "/{lead_id}/conversation-summaries",
    summary="Histórico de resumos de conversa",
    description="Retorna listagem paginada de todos os resumos de conversa do lead.",
    response_model=ConversationSummaryListResponse,
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia"))],
)
async def list_conversation_summaries(
    lead_id: uuid.UUID,
    page: int = Query(default=1, ge=1),
    size: int = Query(default=10, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")

    repo = ConversationSummaryRepository(db)
    items, total = await repo.list_by_lead(lead_id, page=page, limit=size)
    pages = math.ceil(total / size) if total else 0
    return ConversationSummaryListResponse(
        items=[ConversationSummaryResponse.model_validate(i) for i in items],
        total=total,
        page=page,
        limit=size,
        pages=pages,
    )