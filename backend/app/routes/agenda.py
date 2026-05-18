"""
Agenda routes — spec.md §5.4 + parity gap §3.5
==============================================
Endpoints:
  GET    /agenda?data=YYYY-MM-DD          — list agendamentos by day (NEW)
  GET    /agenda/disponibilidade?data=    — list available slots
  GET    /agenda/slots?data=              — DEPRECATED alias of /disponibilidade
  GET    /agenda/{id}                     — detail
  POST   /agenda                          — create (curadoria or bloqueio)
  PATCH  /agenda/{id}                     — partial update (NEW)
  PUT    /agenda/{id}                     — DEPRECATED alias of PATCH (status only)
  DELETE /agenda/{id}                     — soft-cancel (NEW)

Query parameters
----------------
The canonical date param is **`data`** (PT-BR). The legacy **`date`** param
is still accepted but emits a structured deprecation warning and will be
removed in the next sprint.

Concurrency
-----------
The original POST flow uses pg_advisory_xact_lock + SELECT FOR UPDATE to
prevent overbooking. PATCH reuses the same lock when `data` or `hora`
changes. DELETE never holds the lock — cancelling cannot collide.

Block (`tipo='bloqueio'`)
-------------------------
A block reserves a slot WITHOUT a lead. It counts as 'occupied' for both
disponibilidade calculations and create/patch conflict checks. DB CHECK
constraints enforce: bloqueio rows have lead_id IS NULL and a non-null
motivo_bloqueio; curation rows must have a lead_id.
"""
from __future__ import annotations

import hashlib
import uuid
from datetime import date, datetime, time, timezone
from typing import Optional

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, Request, Response, status
from sqlalchemy import select, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, get_db
from app.domain.entities.enums import AgendamentoStatus, AgendamentoTipo, LeadStatus
from app.infrastructure.security.dependencies import RequiresRole
from app.infrastructure.security.scope_check import check_lead_access
from app.models.agendamento import Agendamento
from app.presentation.schemas.agendamento_schema import (
    AgendamentoCreate,
    AgendamentoListResponse,
    AgendamentoPatch,
    AgendamentoResponse,
    AgendamentoUpdate,
    CancelAgendamentoRequest,
    DisponibilidadeResponse,
    SlotDisponivel,
)
from app.models.user import User
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.services import lead_service, fcm_service, audit_service
from app.services.fcm_service import send_push_notification

logger = structlog.get_logger()

router = APIRouter(
    prefix="/agenda",
    tags=["Agenda"],
    dependencies=[Depends(RequiresRole("consultor", "admin"))],
)

# ── Business config ─────────────────────────────────────────────────────────
MAX_POR_DIA = 7
HORA_ABERTURA = time(9, 0)
HORA_FECHAMENTO = time(16, 0)
SLOT_STEP_MINUTOS = 60
DURACAO_CURADORIA_MINUTOS = 60


# ── Slot helpers ────────────────────────────────────────────────────────────
def _generate_slots() -> list[time]:
    """Return the canonical 09:00..15:00 hourly slots."""
    slots: list[time] = []
    current = HORA_ABERTURA
    while current < HORA_FECHAMENTO:
        slots.append(current)
        next_hour = (current.hour * 60 + current.minute + SLOT_STEP_MINUTOS) // 60
        current = time(next_hour, 0)
    return slots


_SLOTS_PADRAO = _generate_slots()


def _hora_alinhada_com_slot(hora: time) -> bool:
    return (
        hora.minute == 0
        and hora.second == 0
        and HORA_ABERTURA.hour <= hora.hour < HORA_FECHAMENTO.hour
    )


def _blocos_se_sobrepoe(inicio1: time, inicio2: time) -> bool:
    s1 = inicio1.hour * 60 + inicio1.minute
    e1 = s1 + DURACAO_CURADORIA_MINUTOS
    s2 = inicio2.hour * 60 + inicio2.minute
    e2 = s2 + DURACAO_CURADORIA_MINUTOS
    return not (e1 <= s2 or s1 >= e2)


def _slot_disponivel(
    slot: time,
    agendamentos: list[Agendamento],
) -> bool:
    """Slot is available if (a) capacity not exhausted AND (b) no overlap."""
    if len(agendamentos) >= MAX_POR_DIA:
        return False
    return all(not _blocos_se_sobrepoe(slot, ag.hora) for ag in agendamentos)


def _slot_lock_key(data: date, hora_str: str) -> int:
    """Stable hash for pg_advisory_xact_lock keyed by data+hora."""
    raw = f"{data.isoformat()}_{hora_str}".encode()
    return int(hashlib.sha256(raw).hexdigest(), 16) % (2**63)


async def _buscar_agendamentos_do_dia(
    db: AsyncSession,
    data: date,
    lock_for_update: bool = False,
) -> list[Agendamento]:
    """Active agendamentos (non-cancelled) for a given date.

    Includes bloqueios so they count as occupied slots.
    """
    stmt = select(Agendamento).where(
        Agendamento.data == data,
        Agendamento.status != AgendamentoStatus.cancelado,
    )
    if lock_for_update:
        stmt = stmt.with_for_update()
    result = await db.execute(stmt)
    return list(result.scalars().all())


def _resolve_data_query(
    data: Optional[date],
    date: Optional[date],  # noqa: A002 — must match query name
) -> date:
    """Accept canonical `?data=` and legacy `?date=`; emit deprecation log."""
    if data is None and date is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="data_required",
        )
    if data is None and date is not None:
        logger.warning(
            "deprecated_query_param",
            param="date",
            replacement="data",
            recommendation="migrate to ?data= within next sprint",
        )
        return date
    return data  # type: ignore[return-value]


# ── GET /agenda ─────────────────────────────────────────────────────────────
@router.get(
    "",
    response_model=AgendamentoListResponse,
    summary="Listar agendamentos do dia",
    description=(
        "Retorna a lista de agendamentos (curadorias + bloqueios) do dia. "
        "Diferente de `/disponibilidade`, que retorna slots livres. "
        "Consultor sempre vê apenas os próprios; admin pode filtrar por consultor_id."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Perfil sem permissão", "model": HTTPErrorResponse},
        422: {"description": "Data ausente ou inválida", "model": HTTPErrorResponse},
    },
)
async def list_agendamentos_by_date(
    data: Optional[date] = Query(None, description="Data (YYYY-MM-DD) — canônico em PT"),
    date: Optional[date] = Query(  # noqa: A002 — public query param name
        None,
        description="DEPRECATED — use `data`.",
        deprecated=True,
    ),
    consultor_id: Optional[uuid.UUID] = Query(
        None,
        description="Admin only — filtrar por outro consultor.",
    ),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AgendamentoListResponse:
    target_data = _resolve_data_query(data, date)

    user_perfil = getattr(current_user, "perfil", None)
    if user_perfil == "admin":
        target_consultor = consultor_id  # may be None → all
    else:
        target_consultor = current_user.id  # consultor sees own only

    stmt = select(Agendamento).where(Agendamento.data == target_data)
    if target_consultor is not None:
        stmt = stmt.where(Agendamento.consultor_id == target_consultor)
    stmt = stmt.order_by(Agendamento.hora.asc())
    rows = list((await db.execute(stmt)).scalars().all())

    return AgendamentoListResponse(
        items=[AgendamentoResponse.model_validate(r) for r in rows],
        total=len(rows),
        data=target_data,
    )


# ── GET /agenda/disponibilidade ─────────────────────────────────────────────
@router.get(
    "/disponibilidade",
    response_model=DisponibilidadeResponse,
    summary="Consultar disponibilidade de horários",
    description=(
        "Retorna os slots de horário disponíveis para agendamento de curadoria em uma data. "
        "Slots ocupados por agendamentos confirmados/pendentes ou bloqueios manuais ficam "
        "marcados como `disponivel=false`."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Perfil sem permissão", "model": HTTPErrorResponse},
        422: {"description": "Data inválida", "model": HTTPErrorResponse},
    },
)
async def get_disponibilidade(
    data: Optional[date] = Query(None, description="Data (YYYY-MM-DD) — canônico"),
    date: Optional[date] = Query(  # noqa: A002
        None, description="DEPRECATED — use `data`.", deprecated=True
    ),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> DisponibilidadeResponse:
    target_data = _resolve_data_query(data, date)

    if target_data.weekday() >= 5:  # Sat/Sun
        return DisponibilidadeResponse(slots=[])

    agendamentos = await _buscar_agendamentos_do_dia(db, target_data)
    slots = [
        SlotDisponivel(
            data=target_data,
            hora=f"{slot.hour:02d}:00",
            disponivel=_slot_disponivel(slot, agendamentos),
        )
        for slot in _SLOTS_PADRAO
    ]
    return DisponibilidadeResponse(slots=slots)


# ── GET /agenda/slots (deprecated alias) ────────────────────────────────────
@router.get(
    "/slots",
    response_model=DisponibilidadeResponse,
    deprecated=True,
    summary="DEPRECATED — alias de /agenda/disponibilidade",
    description=(
        "Mantido por retro-compatibilidade com o front Flutter. "
        "Migre para `/agenda/disponibilidade` na próxima sprint."
    ),
)
async def get_slots_alias(
    data: Optional[date] = Query(None),
    date: Optional[date] = Query(None, deprecated=True),  # noqa: A002
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> DisponibilidadeResponse:
    logger.warning(
        "deprecated_endpoint",
        path="/agenda/slots",
        replacement="/agenda/disponibilidade",
    )
    return await get_disponibilidade(data=data, date=date, db=db, current_user=current_user)


# ── POST /agenda ────────────────────────────────────────────────────────────
@router.post(
    "",
    response_model=AgendamentoResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Criar agendamento (curadoria ou bloqueio)",
    description=(
        "Cria um agendamento de curadoria (`tipo=online|presencial` exige `lead_id`) "
        "ou um bloqueio manual de horário (`tipo=bloqueio` exige `motivo_bloqueio` e "
        "proíbe `lead_id`). Aplica trava pessimista (pg_advisory_xact_lock) e verifica "
        "capacidade diária + sobreposição."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para o lead", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
        409: {"description": "Conflito de horário ou capacidade esgotada", "model": HTTPErrorResponse},
        422: {"description": "Data/hora inválida", "model": HTTPErrorResponse},
    },
)
async def create_agendamento(
    body: AgendamentoCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AgendamentoResponse:
    lead = None
    # 1. Date / time validation (also applies to bloqueio — same window).
    if body.data.weekday() >= 5:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="agendamentos_apenas_em_dias_uteis",
        )
    if not _hora_alinhada_com_slot(body.hora):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="horario_fora_dos_slots_09_15_step_1h",
        )

    # 2. Lead access check (skip for bloqueio).
    if body.tipo != AgendamentoTipo.bloqueio:
        if body.lead_id is None:  # belt-and-suspenders; pydantic should catch
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="curadoria_requires_lead_id",
            )
        lead = await lead_service.get_lead_by_id(db, body.lead_id)
        if not lead:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Lead não encontrado"
            )
        check_lead_access(current_user, lead)

    # 3. Concurrency lock + slot conflict check.
    hora_str = body.hora.strftime("%H:%M")
    lock_key = _slot_lock_key(body.data, hora_str)
    await db.execute(text("SELECT pg_advisory_xact_lock(:key)"), {"key": lock_key})

    agendamentos = await _buscar_agendamentos_do_dia(db, body.data, lock_for_update=True)

    if len(agendamentos) >= MAX_POR_DIA:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"capacidade_diaria_esgotada_{MAX_POR_DIA}",
        )

    if not _slot_disponivel(body.hora, agendamentos):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="slot_ocupado_ou_conflitante",
        )

    # 4. Persist.
    try:
        ag = Agendamento(
            lead_id=body.lead_id,
            data=body.data,
            hora=body.hora,
            tipo=body.tipo,
            motivo_bloqueio=body.motivo_bloqueio,
            notas=body.notas,
            consultor_id=current_user.id,
        )
        db.add(ag)
        
        # Sincronização de status do Lead (Pipeline CRM §3.3)
        if lead:
            await lead_service.update_lead_status(
                db, lead, LeadStatus.agendado, triggered_by="agendamento_criado"
            )
        
        await db.commit()
        await db.refresh(ag)
        
        # 5. Notificações FCM (Task 3.6)
        if lead:
            client_token = await lead_service._get_client_fcm_token(db, lead)
            if client_token:
                try:
                    await send_push_notification(
                        fcm_token=client_token,
                        title="Novo agendamento!",
                        body=f"Sua consultoria de {body.tipo.value} foi agendada para {body.data.strftime('%d/%m/%Y')} às {body.hora.strftime('%H:%M')}.",
                        data={"type": "agendamento_criado", "agendamento_id": str(ag.id)}
                    )
                except Exception as exc:
                    logger.warning("agenda_fcm_client_failed", error=str(exc))
                    
            # Notificar consultor se houver token
            if current_user.fcm_token:
                try:
                    await send_push_notification(
                        fcm_token=current_user.fcm_token,
                        title="Novo lead agendado",
                        body=f"Lead {lead.nome or lead.telefone} agendado para {body.data.strftime('%d/%m/%Y')}.",
                        data={"type": "lead_agendado", "lead_id": str(lead.id)}
                    )
                except Exception as exc:
                    logger.warning("agenda_fcm_consultor_failed", error=str(exc))
    except IntegrityError as exc:
        await db.rollback()
        logger.warning("agendamento_integrity_error", error=str(exc.orig))
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="erro_integridade_slot_pode_ter_sido_ocupado",
        )

    logger.info(
        "agendamento_created",
        agendamento_id=str(ag.id),
        tipo=body.tipo.value,
        lead_id=str(body.lead_id) if body.lead_id else None,
        consultor_id=str(current_user.id),
    )
    return AgendamentoResponse.model_validate(ag)


# ── GET /agenda/{id} ────────────────────────────────────────────────────────
@router.get(
    "/{agendamento_id}",
    response_model=AgendamentoResponse,
    summary="Detalhes de um agendamento",
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Agendamento não encontrado", "model": HTTPErrorResponse},
    },
)
async def get_agendamento(
    agendamento_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AgendamentoResponse:
    result = await db.execute(select(Agendamento).where(Agendamento.id == agendamento_id))
    ag = result.scalar_one_or_none()
    if not ag:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Agendamento não encontrado"
        )
    if ag.lead_id is not None:
        lead = await lead_service.get_lead_by_id(db, ag.lead_id)
        if lead:
            check_lead_access(current_user, lead)
    return AgendamentoResponse.model_validate(ag)


# ── Helpers shared by PATCH/PUT/DELETE ──────────────────────────────────────
async def _load_agendamento_or_404(
    db: AsyncSession, agendamento_id: uuid.UUID
) -> Agendamento:
    result = await db.execute(select(Agendamento).where(Agendamento.id == agendamento_id))
    ag = result.scalar_one_or_none()
    if not ag:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Agendamento não encontrado"
        )
    return ag


async def _assert_can_edit(
    db: AsyncSession, current_user: User, ag: Agendamento
) -> None:
    """Consultor only edits own; admin edits anything; bloqueio dono only."""
    user_perfil = getattr(current_user, "perfil", None)
    if user_perfil == "admin":
        return
    if ag.consultor_id == current_user.id:
        # For curadoria, also re-run lead access (e.g. lead was reassigned)
        if ag.lead_id is not None:
            lead = await lead_service.get_lead_by_id(db, ag.lead_id)
            if lead:
                check_lead_access(current_user, lead)
        return
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN, detail="apenas_dono_ou_admin"
    )


# ── PATCH /agenda/{id} ──────────────────────────────────────────────────────
@router.patch(
    "/{agendamento_id}",
    response_model=AgendamentoResponse,
    summary="Atualização parcial de agendamento",
    description=(
        "Atualiza campos individuais. Revalida slot apenas se `data` ou `hora` mudarem. "
        "**Não** aceita `status=cancelado` — use DELETE. **Não** dispara efeitos colaterais "
        "(notificações etc.) — somente persiste."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Agendamento não encontrado", "model": HTTPErrorResponse},
        409: {"description": "Conflito de slot ao mover", "model": HTTPErrorResponse},
        422: {"description": "Payload inválido", "model": HTTPErrorResponse},
    },
)
async def patch_agendamento(
    agendamento_id: uuid.UUID,
    body: AgendamentoPatch,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AgendamentoResponse:
    ag = await _load_agendamento_or_404(db, agendamento_id)
    await _assert_can_edit(db, current_user, ag)

    if ag.status == AgendamentoStatus.cancelado:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="agendamento_ja_cancelado",
        )
    if ag.status == AgendamentoStatus.realizado:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="agendamento_ja_realizado_imutavel",
        )

    payload = body.model_dump(exclude_unset=True)

    # If date or time changes, re-run slot availability check.
    new_data = payload.get("data", ag.data)
    new_hora = payload.get("hora", ag.hora)
    moving = ("data" in payload) or ("hora" in payload)

    if moving:
        if new_data.weekday() >= 5:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="agendamentos_apenas_em_dias_uteis",
            )
        if not _hora_alinhada_com_slot(new_hora):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="horario_fora_dos_slots_09_15_step_1h",
            )
        hora_str = new_hora.strftime("%H:%M")
        await db.execute(
            text("SELECT pg_advisory_xact_lock(:key)"),
            {"key": _slot_lock_key(new_data, hora_str)},
        )
        do_dia = await _buscar_agendamentos_do_dia(db, new_data, lock_for_update=True)
        # exclude self from conflict check
        do_dia = [a for a in do_dia if a.id != ag.id]
        if not _slot_disponivel(new_hora, do_dia):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="slot_destino_ocupado_ou_conflitante",
            )

    # Apply changes.
    for field, value in payload.items():
        setattr(ag, field, value)

    try:
        await db.commit()
        await db.refresh(ag)
    except IntegrityError as exc:
        await db.rollback()
        logger.warning("agendamento_patch_integrity", error=str(exc.orig))
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="erro_integridade_ao_atualizar",
        )

    logger.info(
        "agendamento_patched",
        agendamento_id=str(ag.id),
        fields=list(payload.keys()),
        consultor_id=str(current_user.id),
    )
    return AgendamentoResponse.model_validate(ag)


# ── PUT /agenda/{id} (deprecated alias) ─────────────────────────────────────
@router.put(
    "/{agendamento_id}",
    response_model=AgendamentoResponse,
    deprecated=True,
    summary="DEPRECATED — use PATCH",
    description="Mantido para compatibilidade. Migre para PATCH /agenda/{id}.",
)
async def update_agendamento_legacy(
    agendamento_id: uuid.UUID,
    body: AgendamentoUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AgendamentoResponse:
    logger.warning(
        "deprecated_endpoint",
        path="PUT /agenda/{id}",
        replacement="PATCH /agenda/{id}",
    )
    if body.status == AgendamentoStatus.cancelado:
        # Old contract used PUT to cancel; redirect to DELETE semantics.
        return await cancel_agendamento(
            agendamento_id=agendamento_id,
            payload=None,
            db=db,
            current_user=current_user,
        )

    ag = await _load_agendamento_or_404(db, agendamento_id)
    await _assert_can_edit(db, current_user, ag)
    ag.status = body.status
    await db.commit()
    await db.refresh(ag)

    logger.info(
        "agendamento_updated_legacy",
        agendamento_id=str(ag.id),
        new_status=body.status.value,
        consultor_id=str(current_user.id),
    )
    return AgendamentoResponse.model_validate(ag)


# ── DELETE /agenda/{id} (soft-cancel) ───────────────────────────────────────
@router.delete(
    "/{agendamento_id}",
    summary="Cancelar (soft-delete) um agendamento",
    description=(
        "Marca o agendamento como `status=cancelado`, grava `cancelado_em` e o motivo opcional. "
        "Libera o slot para reagendamento. Bloqueado se o agendamento já foi realizado."
    ),
    responses={
        204: {"description": "Cancelado com sucesso"},
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Agendamento não encontrado", "model": HTTPErrorResponse},
        409: {"description": "Já cancelado ou já realizado", "model": HTTPErrorResponse},
    },
)
async def cancel_agendamento(
    agendamento_id: uuid.UUID,
    payload: Optional[CancelAgendamentoRequest] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Response:
    ag = await _load_agendamento_or_404(db, agendamento_id)
    await _assert_can_edit(db, current_user, ag)

    if ag.status == AgendamentoStatus.cancelado:
        # Idempotent: already cancelled returns 204.
        return Response(status_code=status.HTTP_204_NO_CONTENT)
    if ag.status == AgendamentoStatus.realizado:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="cannot_cancel_realized",
        )

    previous_status = ag.status
    ag.status = AgendamentoStatus.cancelado
    ag.cancelado_em = datetime.now(timezone.utc)
    if payload is not None and payload.motivo:
        ag.motivo_cancelamento = payload.motivo

    await db.commit()

    await audit_service.log_event(
        db,
        event_type="agendamento_cancelado",
        resource_type="agendamento",
        resource_id=ag.id,
        user_id=current_user.id,
        user_email=current_user.email,
        description=f"Agendamento cancelado por {current_user.perfil}. Motivo: {ag.motivo_cancelamento or 'N/A'}",
        payload={"previous_status": str(previous_status)}
    )

    logger.info(
        "agendamento_cancelled",
        agendamento_id=str(ag.id),
        previous_status=str(previous_status),
        had_motivo=bool(payload and payload.motivo),
        consultor_id=str(current_user.id),
        was_confirmed=(previous_status == AgendamentoStatus.confirmado),
    )
    
    # 5. Notificação FCM de Cancelamento (Task 3.6)
    if previous_status in (AgendamentoStatus.pendente, AgendamentoStatus.confirmado):
        if ag.lead_id:
            lead = await lead_service.get_lead_by_id(db, ag.lead_id)
            if lead:
                client_token = await lead_service._get_client_fcm_token(db, lead)
                if client_token:
                    try:
                        await send_push_notification(
                            fcm_token=client_token,
                            title="Agendamento cancelado",
                            body=f"O agendamento do dia {ag.data.strftime('%d/%m/%Y')} foi cancelado.",
                            data={"type": "agendamento_cancelado", "agendamento_id": str(ag.id)}
                        )
                    except Exception as exc:
                        logger.warning("agenda_cancel_fcm_failed", error=str(exc))

    return Response(status_code=status.HTTP_204_NO_CONTENT)
