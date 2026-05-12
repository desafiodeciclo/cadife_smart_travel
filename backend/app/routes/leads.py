import uuid
from datetime import datetime
from typing import Optional

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
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
from app.domain.entities.enums import LeadStatus
from app.infrastructure.cache.decorator import cached
from app.infrastructure.security.dependencies import (
    RequiresRole,
    get_current_user,
    get_db,
)
from app.infrastructure.security.pii_encryption import hmac_hash
from app.models.briefing import BriefingResponse, BriefingUpdate, calculate_completude
from app.models.conversation_summary import (
    ConversationSummaryListResponse,
    ConversationSummaryResponse,
)
from app.models.interacao import InteracaoListResponse
from app.models.lead import Lead
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.presentation.schemas.leads import (
    AyaToggleRequest,
    AyaToggleResponseDTO,
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

# ... [Mantenha os endpoints list_leads, get_lead_metrics e get_my_active_lead conforme o original] ...

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
    from sqlalchemy import select
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
            await lead_service._persist_score(db, lead, motivo="auto")
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
    from app.infrastructure.persistence.models.aya_toggle_history_model import AyaToggleHistoryModel
    from app.infrastructure.config.settings import get_settings

    lead = await lead_service.get_lead_by_id(db, lead_id)
    if not lead:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado")

    lead.aya_ativo = body.ativo
    history = AyaToggleHistoryModel(
        lead_id=lead_id, ativo=body.ativo, motivo=body.motivo, alterado_por=current_user.id
    )
    db.add(history)
    await db.commit()

    settings = get_settings()
    recentes = await lead_service.get_recent_interacoes(db, lead_id, limit=settings.AYA_CONTEXT_MSGS)

    return AyaToggleResponseDTO(
        lead_id=lead_id,
        aya_ativo=body.ativo,
        motivo=body.motivo,
        alterado_em=datetime.now(), # Simplificado para o exemplo
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

# ... [Mantenha os demais endpoints conforme o arquivo original] ...