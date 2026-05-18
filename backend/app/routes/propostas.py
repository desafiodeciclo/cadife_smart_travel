"""
Propostas routes — gap §3.4 from BACKEND_FRONTEND_PARITY_GAPS.md.

Endpoints:
  POST   /propostas                     — create
  GET    /propostas                     — list (filter by lead_id, hides soft-deleted)
  GET    /propostas/{id}                — detail
  PATCH  /propostas/{id}                — partial update (NEW, no side-effects)
  PUT    /propostas/{id}                — DEPRECATED legacy (status mutation + side-effects)
  DELETE /propostas/{id}                — soft-delete (NEW, idempotent)
  POST   /propostas/{id}/enviar         — explicit send (NEW, idempotent FCM/WhatsApp)
  GET    /propostas/{id}/versoes        — snapshot history (NEW)
"""
from __future__ import annotations

import asyncio
import uuid
from datetime import datetime, timezone
from typing import Optional

import structlog
from fastapi import (
    APIRouter,
    BackgroundTasks,
    Depends,
    HTTPException,
    Request,
    Response,
    status,
)
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, get_db
from app.domain.entities.enums import LeadStatus, PropostaStatus, TravelCheckpoint
from app.infrastructure.security.dependencies import RequiresRole
from app.infrastructure.security.scope_check import check_lead_access
from app.models.proposta import Proposta
from app.presentation.schemas.proposta_schema import (
    CancelPropostaRequest,
    PropostaCreate,
    PropostaPatchRequest,
    PropostaResponse,
    PropostaUpdate,
    PropostaVersaoDTO,
    PropostaVersoesListResponse,
)
from app.models.user import User
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.services import lead_service, proposta_versao_service
from app.services.fcm_service import send_push_notification

logger = structlog.get_logger()

router = APIRouter(
    prefix="/propostas",
    tags=["Propostas"],
    dependencies=[Depends(RequiresRole("consultor", "admin"))],
)


# ── Helpers ────────────────────────────────────────────────────────────────


async def _load_proposta_or_404(
    db: AsyncSession, proposta_id: uuid.UUID, *, include_deleted: bool = False
) -> Proposta:
    stmt = select(Proposta).where(Proposta.id == proposta_id)
    if not include_deleted:
        stmt = stmt.where(Proposta.deletado_em.is_(None))
    proposta = (await db.execute(stmt)).scalar_one_or_none()
    if not proposta:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Proposta não encontrada"
        )
    return proposta


async def _assert_can_edit(
    db: AsyncSession, current_user: User, proposta: Proposta
) -> None:
    """Consultor only edits own; admin edits anything."""
    if str(current_user.perfil) == "admin":
        return
    if proposta.consultor_id == current_user.id:
        # Re-check lead scope (lead may have been reassigned)
        lead = await lead_service.get_lead_by_id(db, proposta.lead_id)
        if lead:
            check_lead_access(current_user, lead)
        return
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN, detail="apenas_dono_ou_admin"
    )


# ─────────────────────────────────────────────────────────────────────────────
# POST /propostas — create (snapshot motivo='criacao')
# ─────────────────────────────────────────────────────────────────────────────


@router.post(
    "",
    response_model=PropostaResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Criar proposta",
    description=(
        "Cria uma nova proposta vinculada a um lead. O lead deve estar nos status "
        "qualificado, agendado ou proposta. Consultores só podem criar propostas para "
        "seus próprios leads."
    ),
    responses={
        400: {"description": "Lead em status inadequado", "model": HTTPErrorResponse},
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
    lead = await lead_service.get_lead_by_id(db, body.lead_id)
    if not lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado"
        )
    check_lead_access(current_user, lead)

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
    await db.flush()  # populate proposta.id before snapshot
    await proposta_versao_service.snapshot(
        db, proposta, motivo="criacao", by=current_user.id
    )
    await db.commit()
    await db.refresh(proposta)

    # Best-effort FCM (creation only — actual "send" goes via /enviar)
    client_token = await lead_service._get_client_fcm_token(db, lead)
    if client_token:
        try:
            await send_push_notification(
                fcm_token=client_token,
                title="Proposta de viagem criada!",
                body="Verifique os detalhes no app",
                data={"type": "proposal_created", "proposal_id": str(proposta.id)},
            )
        except Exception as exc:  # noqa: BLE001 — best-effort
            logger.warning(
                "proposta_create_fcm_failed",
                proposta_id=str(proposta.id),
                error=str(exc),
            )

    return PropostaResponse.model_validate(proposta)


# ─────────────────────────────────────────────────────────────────────────────
# GET /propostas — list
# ─────────────────────────────────────────────────────────────────────────────


@router.get("", response_model=list[PropostaResponse])
async def list_propostas(
    lead_id: Optional[uuid.UUID] = None,
    include_deleted: bool = False,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = select(Proposta)
    if not include_deleted:
        query = query.where(Proposta.deletado_em.is_(None))
    if lead_id:
        query = query.where(Proposta.lead_id == lead_id)
    if str(current_user.perfil) == "consultor":
        query = query.where(Proposta.consultor_id == current_user.id)

    propostas = (await db.execute(query)).scalars().all()
    return [PropostaResponse.model_validate(p) for p in propostas]


# ─────────────────────────────────────────────────────────────────────────────
# GET /propostas/{id} — detail
# ─────────────────────────────────────────────────────────────────────────────


@router.get(
    "/{proposta_id}",
    response_model=PropostaResponse,
    summary="Detalhes de uma proposta",
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Proposta não encontrada", "model": HTTPErrorResponse},
    },
)
async def get_proposta(
    proposta_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    proposta = await _load_proposta_or_404(db, proposta_id)
    lead = await lead_service.get_lead_by_id(db, proposta.lead_id)
    if lead:
        check_lead_access(current_user, lead)
    return PropostaResponse.model_validate(proposta)


# ─────────────────────────────────────────────────────────────────────────────
# PATCH /propostas/{id} — partial update WITHOUT side-effects (gap §3.4.1)
# ─────────────────────────────────────────────────────────────────────────────


@router.patch(
    "/{proposta_id}",
    response_model=PropostaResponse,
    summary="Atualização parcial de proposta (sem side-effects)",
    description=(
        "Atualiza descricao/valor_estimado/expiration_hours sem disparar FCM, WhatsApp "
        "ou checkpoint. Bloqueado se proposta já foi enviada/aprovada/recusada/expirada. "
        "Para enviar, use POST /propostas/{id}/enviar."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Proposta não encontrada", "model": HTTPErrorResponse},
        409: {"description": "Proposta em status imutável", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação", "model": HTTPErrorResponse},
    },
)
async def patch_proposta(
    proposta_id: uuid.UUID,
    body: PropostaPatchRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    proposta = await _load_proposta_or_404(db, proposta_id)
    await _assert_can_edit(db, current_user, proposta)

    if proposta.status not in (PropostaStatus.rascunho, PropostaStatus.em_revisao):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"proposta_em_status_{proposta.status.value if hasattr(proposta.status, 'value') else proposta.status}_nao_pode_ser_editada",
        )

    # Snapshot BEFORE applying changes so the version reflects the previous state
    await proposta_versao_service.snapshot(
        db, proposta, motivo="edicao", by=current_user.id
    )

    payload = body.model_dump(exclude_unset=True)
    for field, value in payload.items():
        setattr(proposta, field, value)

    try:
        await db.commit()
        await db.refresh(proposta)
    except IntegrityError as exc:
        await db.rollback()
        logger.warning("proposta_patch_integrity", error=str(exc.orig))
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="erro_integridade_ao_atualizar",
        )

    logger.info(
        "proposta_patched",
        proposta_id=str(proposta.id),
        fields=list(payload.keys()),
        by=str(current_user.id),
    )
    return PropostaResponse.model_validate(proposta)


# ─────────────────────────────────────────────────────────────────────────────
# DELETE /propostas/{id} — soft-cancel (gap §3.4.2)
# ─────────────────────────────────────────────────────────────────────────────


@router.delete(
    "/{proposta_id}",
    summary="Soft-delete de proposta",
    description=(
        "Marca a proposta como deletada. Idempotente — se já está deletada, retorna 204. "
        "Bloqueado se status == aprovada (use admin override em PR futura se necessário)."
    ),
    responses={
        204: {"description": "Deletada com sucesso"},
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Proposta não encontrada", "model": HTTPErrorResponse},
        409: {"description": "Proposta aprovada não pode ser deletada", "model": HTTPErrorResponse},
    },
)
async def delete_proposta(
    proposta_id: uuid.UUID,
    payload: Optional[CancelPropostaRequest] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Response:
    proposta = await _load_proposta_or_404(db, proposta_id, include_deleted=True)

    if proposta.deletado_em is not None:
        # Idempotent: already deleted → 204
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    await _assert_can_edit(db, current_user, proposta)

    if proposta.status == PropostaStatus.aprovada:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="proposta_aprovada_nao_pode_ser_deletada",
        )

    # Snapshot before mutation
    await proposta_versao_service.snapshot(
        db, proposta, motivo="cancelamento", by=current_user.id
    )

    proposta.deletado_em = datetime.now(timezone.utc)
    proposta.deletado_por = current_user.id
    await db.commit()

    logger.info(
        "proposta_soft_deleted",
        proposta_id=str(proposta.id),
        by=str(current_user.id),
        had_motivo=bool(payload and payload.motivo),
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ─────────────────────────────────────────────────────────────────────────────
# POST /propostas/{id}/enviar — idempotent send (gap §3.4.3)
# ─────────────────────────────────────────────────────────────────────────────


async def _dispatch_proposta_notifications(
    proposta_id: uuid.UUID, lead_id: uuid.UUID
) -> None:
    """Background task: idempotent dispatch of FCM/WhatsApp + checkpoint.

    Reads `notificacao_enviada_em` to guard against double dispatch when the
    `/enviar` endpoint is called concurrently or retried by the front.
    """
    from app.infrastructure.persistence.database import AsyncSessionLocal
    from app.services.checkpoint_service import activate_checkpoint, SISTEMA

    async with AsyncSessionLocal() as db:
        proposta = (
            await db.execute(select(Proposta).where(Proposta.id == proposta_id))
        ).scalar_one_or_none()
        if proposta is None:
            return
        if proposta.notificacao_enviada_em is not None:
            logger.info(
                "proposta_enviar_notifications_skipped_already_dispatched",
                proposta_id=str(proposta_id),
            )
            return

        lead = await lead_service.get_lead_by_id(db, lead_id)
        token = await lead_service._get_client_fcm_token(db, lead) if lead else None
        if token:
            try:
                await send_push_notification(
                    fcm_token=token,
                    title="Sua proposta de viagem chegou!",
                    body="Toque para visualizar os detalhes.",
                    data={
                        "type": "proposal_sent",
                        "proposal_id": str(proposta_id),
                    },
                )
            except Exception as exc:  # noqa: BLE001 — best-effort
                logger.warning(
                    "proposta_enviar_fcm_failed",
                    proposta_id=str(proposta_id),
                    error=str(exc),
                )

        # Checkpoint (best-effort)
        try:
            await activate_checkpoint(
                db, lead_id, TravelCheckpoint.proposta_enviada, SISTEMA
            )
        except Exception as exc:  # noqa: BLE001
            logger.warning(
                "proposta_enviar_checkpoint_failed",
                proposta_id=str(proposta_id),
                error=str(exc),
            )

        proposta.notificacao_enviada_em = datetime.now(timezone.utc)
        await db.commit()
        logger.info(
            "proposta_enviar_notifications_dispatched",
            proposta_id=str(proposta_id),
        )


@router.post(
    "/{proposta_id}/enviar",
    response_model=PropostaResponse,
    summary="Enviar proposta ao cliente (idempotente)",
    description=(
        "Marca a proposta como enviada e dispara FCM + WhatsApp + checkpoint em "
        "background. Idempotente: chamadas subsequentes retornam 200 sem reenviar."
    ),
    responses={
        200: {"description": "Proposta enviada (ou já estava enviada)"},
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Proposta não encontrada", "model": HTTPErrorResponse},
        409: {
            "description": "Status incompatível com envio (ex: aprovada/recusada/expirada)",
            "model": HTTPErrorResponse,
        },
    },
)
async def enviar_proposta(
    proposta_id: uuid.UUID,
    background: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    proposta = await _load_proposta_or_404(db, proposta_id)
    await _assert_can_edit(db, current_user, proposta)

    # Idempotent: if already sent and notification already dispatched, just return
    if proposta.status == PropostaStatus.enviada and proposta.enviado_em:
        logger.info(
            "proposta_enviar_idempotent_noop", proposta_id=str(proposta.id)
        )
        return PropostaResponse.model_validate(proposta)

    if proposta.status not in (PropostaStatus.rascunho, PropostaStatus.em_revisao):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"cannot_send_from_status_{proposta.status.value if hasattr(proposta.status, 'value') else proposta.status}",
        )

    # Snapshot the state we are leaving (rascunho/em_revisao)
    await proposta_versao_service.snapshot(
        db, proposta, motivo="envio", by=current_user.id
    )

    proposta.status = PropostaStatus.enviada
    proposta.enviado_em = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(proposta)

    # Side-effects in background — do NOT block the HTTP response
    background.add_task(
        _dispatch_proposta_notifications, proposta.id, proposta.lead_id
    )

    logger.info(
        "proposta_enviada",
        proposta_id=str(proposta.id),
        lead_id=str(proposta.lead_id),
        by=str(current_user.id),
    )
    return PropostaResponse.model_validate(proposta)


# ─────────────────────────────────────────────────────────────────────────────
# GET /propostas/{id}/versoes — snapshot history (gap §3.4.4)
# ─────────────────────────────────────────────────────────────────────────────


@router.get(
    "/{proposta_id}/versoes",
    response_model=PropostaVersoesListResponse,
    summary="Histórico de versões de uma proposta",
    description=(
        "Retorna a lista de snapshots da proposta em ordem decrescente de versão. "
        "Cada entrada inclui o motivo (criacao/edicao/envio/aprovacao/recusa/cancelamento) "
        "e o snapshot completo do estado da proposta naquele momento."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Proposta não encontrada", "model": HTTPErrorResponse},
    },
)
async def list_versoes(
    proposta_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PropostaVersoesListResponse:
    proposta = await _load_proposta_or_404(db, proposta_id, include_deleted=True)

    # Permission: dono, admin, or cliente do lead.
    if str(current_user.perfil) == "admin":
        pass
    elif proposta.consultor_id == current_user.id:
        pass
    else:
        # Could be the lead's client — let lead_service decide
        lead = await lead_service.get_lead_by_id(db, proposta.lead_id)
        if lead is None:
            raise HTTPException(status_code=403, detail="sem_permissao")
        check_lead_access(current_user, lead)

    rows = await proposta_versao_service.list_by_proposta(db, proposta_id)
    items = [PropostaVersaoDTO.model_validate(r) for r in rows]
    return PropostaVersoesListResponse(items=items, total=len(items))


# ─────────────────────────────────────────────────────────────────────────────
# PUT /propostas/{id} — DEPRECATED legacy alias
# ─────────────────────────────────────────────────────────────────────────────


@router.put(
    "/{proposta_id}",
    response_model=PropostaResponse,
    deprecated=True,
    summary="DEPRECATED — use PATCH para edição e POST /enviar para envio",
    description=(
        "Mantido por compatibilidade com builds antigos do app. Aprovação propaga "
        "lead para fechado; recusa retorna lead para proposta."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Proposta não encontrada", "model": HTTPErrorResponse},
        422: {"description": "Status inválido", "model": HTTPErrorResponse},
    },
)
async def update_proposta_legacy(
    request: Request,
    proposta_id: uuid.UUID,
    body: PropostaUpdate,
    background: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    logger.warning(
        "deprecated_endpoint",
        path="PUT /propostas/{id}",
        replacement="PATCH /propostas/{id} (edit) + POST /propostas/{id}/enviar (send)",
    )

    proposta = await _load_proposta_or_404(db, proposta_id)
    await _assert_can_edit(db, current_user, proposta)
    lead = await lead_service.get_lead_by_id(db, proposta.lead_id)

    old_status = proposta.status
    payload = body.model_dump(exclude_none=True)

    # Decide motivo for snapshot based on status transition
    new_status = payload.get("status")
    motivo = "edicao"
    if new_status == PropostaStatus.enviada:
        motivo = "envio"
    elif new_status == PropostaStatus.aprovada:
        motivo = "aprovacao"
    elif new_status == PropostaStatus.recusada:
        motivo = "recusa"
    await proposta_versao_service.snapshot(
        db, proposta, motivo=motivo, by=current_user.id
    )

    for field, value in payload.items():
        setattr(proposta, field, value)

    if new_status is not None and lead is not None:
        if new_status == PropostaStatus.aprovada:
            await lead_service.update_lead_status(
                db, lead, LeadStatus.fechado, triggered_by="proposta_aprovada"
            )
        elif new_status == PropostaStatus.recusada:
            await lead_service.update_lead_status(
                db, lead, LeadStatus.proposta, triggered_by="proposta_recusada"
            )

    if new_status == PropostaStatus.enviada and proposta.enviado_em is None:
        proposta.enviado_em = datetime.now(timezone.utc)

    await db.commit()
    await db.refresh(proposta)

    # Checkpoint triggers + goal increment (preserving legacy behavior)
    if new_status is not None and old_status != new_status:
        from app.services.checkpoint_service import activate_checkpoint, SISTEMA

        if new_status == PropostaStatus.enviada:
            background.add_task(
                _dispatch_proposta_notifications, proposta.id, proposta.lead_id
            )
        elif new_status == PropostaStatus.aprovada:
            asyncio.ensure_future(
                activate_checkpoint(
                    db, proposta.lead_id, TravelCheckpoint.proposta_aprovada, SISTEMA
                )
            )
            if proposta.consultor_id is not None:
                try:
                    from app.services import sale_goal_service, metrics_service

                    await sale_goal_service.increment_achieved(
                        db, user_id=proposta.consultor_id
                    )
                    await metrics_service.invalidate_metrics_cache(
                        proposta.consultor_id
                    )
                except Exception as exc:  # noqa: BLE001
                    logger.warning(
                        "goal_increment_on_approve_failed",
                        proposta_id=str(proposta.id),
                        consultor_id=str(proposta.consultor_id),
                        error=str(exc),
                    )

    return PropostaResponse.model_validate(proposta)
