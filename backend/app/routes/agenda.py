import uuid
from datetime import date, time, timedelta

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, get_db
from app.domain.entities.enums import AgendamentoStatus
from app.infrastructure.security.dependencies import RequiresRole
from app.infrastructure.security.scope_check import check_lead_access
from app.models.agendamento import (
    Agendamento,
    AgendamentoCreate,
    AgendamentoResponse,
    AgendamentoUpdate,
    DisponibilidadeResponse,
    SlotDisponivel,
)
from app.models.user import User
from app.services import lead_service

logger = structlog.get_logger()

router = APIRouter(
    prefix="/agenda",
    tags=["Agenda"],
    dependencies=[Depends(RequiresRole("consultor", "admin"))],
)

MAX_POR_DIA = 7
HORA_ABERTURA = time(9, 0)
HORA_FECHAMENTO = time(16, 0)
SLOT_STEP_MINUTOS = 60
DURACAO_CURADORIA_MINUTOS = 60


def _generate_slots() -> list[time]:
    """Retorna slots de início possíveis entre 09:00 e 15:00 (step 1h)."""
    slots: list[time] = []
    current = HORA_ABERTURA
    while current < HORA_FECHAMENTO:
        slots.append(current)
        current = (current.hour * 60 + current.minute + SLOT_STEP_MINUTOS) // 60
        current = time(current, 0)
    return slots


_SLOTS_PADRAO = _generate_slots()


def _hora_alinhada_com_slot(hora: time) -> bool:
    """Verifica se a hora está alinhada com um dos slots permitidos.

    Slots válidos: 09:00, 10:00, 11:00, 12:00, 13:00, 14:00, 15:00.
    Qualquer hora com minutos != 0 (ex: 10:30) ou fora da range é rejeitada.
    """
    return hora.minute == 0 and hora.second == 0 and hora.microsecond == 0 \
        and HORA_ABERTURA.hour <= hora.hour < HORA_FECHAMENTO.hour


async def _buscar_agendamentos_do_dia(
    db: AsyncSession,
    data: date,
) -> list[Agendamento]:
    result = await db.execute(
        select(Agendamento).where(
            Agendamento.data == data,
            Agendamento.status != AgendamentoStatus.cancelado,
        )
    )
    return list(result.scalars().all())


def _blocos_se_sobrepoe(inicio1: time, inicio2: time) -> bool:
    """Verifica se dois blocos de curadoria de 60min se sobrepõem."""
    s1 = inicio1.hour * 60 + inicio1.minute
    e1 = s1 + DURACAO_CURADORIA_MINUTOS
    s2 = inicio2.hour * 60 + inicio2.minute
    e2 = s2 + DURACAO_CURADORIA_MINUTOS
    return not (e1 <= s2 or s1 >= e2)


def _slot_disponivel(
    slot: time,
    agendamentos: list[Agendamento],
) -> bool:
    if len(agendamentos) >= MAX_POR_DIA:
        return False
    return all(
        not _blocos_se_sobrepoe(slot, ag.hora)
        for ag in agendamentos
    )


@router.get("/disponibilidade", response_model=DisponibilidadeResponse)
async def get_disponibilidade(
    data: date = Query(..., description="Data para consulta de disponibilidade (YYYY-MM-DD)"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> DisponibilidadeResponse:
    """Retorna slots de disponibilidade para curadoria em uma data específica.

    Regras: Seg–Sex, 09h–16h, máximo 7 atendimentos/dia.
    Cada curadoria ocupa um bloco de 60min; blocos sobrepostos não são permitidos.
    Agendamentos com status 'cancelado' não bloqueiam slots.
    """
    logger.info(
        "agenda_disponibilidade_checked",
        data=str(data),
        user_id=str(current_user.id),
    )

    if data.weekday() >= 5:  # fim de semana
        return DisponibilidadeResponse(slots=[])

    agendamentos = await _buscar_agendamentos_do_dia(db, data)
    slots = [
        SlotDisponivel(
            data=data,
            hora=f"{slot.hour:02d}:00",
            disponivel=_slot_disponivel(slot, agendamentos),
        )
        for slot in _SLOTS_PADRAO
    ]
    return DisponibilidadeResponse(slots=slots)


@router.post(
    "", response_model=AgendamentoResponse, status_code=status.HTTP_201_CREATED
)
async def create_agendamento(
    body: AgendamentoCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AgendamentoResponse:
    """Cria um novo agendamento de curadoria com validação completa de conflitos.

    Validações:
      - Dia útil (Seg–Sex)
      - Horário alinhado com slots permitidos (09:00–15:00)
      - Capacidade diária máxima (7 atendimentos)
      - Sem sobreposição de blocos de 60min com agendamentos existentes
      - Lead deve existir no banco
    """
    if body.data.weekday() >= 5:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Agendamentos permitidos apenas de segunda a sexta-feira",
        )

    if not _hora_alinhada_com_slot(body.hora):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Horário fora dos slots permitidos (09:00–15:00, intervalo 1h)",
        )

    # Validar existência do lead
    lead = await lead_service.get_lead_by_id(db, body.lead_id)
    if not lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lead não encontrado",
        )

    check_lead_access(current_user, lead)

    agendamentos = await _buscar_agendamentos_do_dia(db, body.data)

    if len(agendamentos) >= MAX_POR_DIA:
        logger.warning(
            "agendamento_conflict",
            data=str(body.data),
            hora=str(body.hora),
            reason="max_capacity",
            user_id=str(current_user.id),
        )
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Capacidade diária esgotada: máximo de {MAX_POR_DIA} atendimentos por dia",
        )

    if not _slot_disponivel(body.hora, agendamentos):
        logger.warning(
            "agendamento_conflict",
            data=str(body.data),
            hora=str(body.hora),
            reason="interval_overlap",
            user_id=str(current_user.id),
        )
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Conflito de horário: sobreposição com agendamento existente",
        )

    agendamento = Agendamento(
        lead_id=body.lead_id,
        data=body.data,
        hora=body.hora,
        tipo=body.tipo,
        consultor_id=current_user.id,
    )
    db.add(agendamento)
    await db.commit()
    await db.refresh(agendamento)

    logger.info(
        "agendamento_created",
        agendamento_id=str(agendamento.id),
        lead_id=str(body.lead_id),
        data=str(body.data),
        hora=str(body.hora),
        user_id=str(current_user.id),
    )
    return AgendamentoResponse.model_validate(agendamento)


@router.get("/{agendamento_id}", response_model=AgendamentoResponse)
async def get_agendamento(
    agendamento_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AgendamentoResponse:
    """Retorna detalhes de um agendamento específico."""
    result = await db.execute(select(Agendamento).where(Agendamento.id == agendamento_id))
    ag = result.scalar_one_or_none()
    if not ag:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Agendamento não encontrado")

    lead = await lead_service.get_lead_by_id(db, ag.lead_id)
    if lead:
        check_lead_access(current_user, lead)

    return AgendamentoResponse.model_validate(ag)


@router.put("/{agendamento_id}", response_model=AgendamentoResponse)
async def update_agendamento(
    agendamento_id: uuid.UUID,
    body: AgendamentoUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AgendamentoResponse:
    """Atualiza o status de um agendamento."""
    result = await db.execute(select(Agendamento).where(Agendamento.id == agendamento_id))
    ag = result.scalar_one_or_none()
    if not ag:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Agendamento não encontrado")

    lead = await lead_service.get_lead_by_id(db, ag.lead_id)
    if lead:
        check_lead_access(current_user, lead)

    ag.status = body.status
    await db.commit()
    await db.refresh(ag)

    logger.info(
        "agendamento_updated",
        agendamento_id=str(ag.id),
        new_status=body.status.value if hasattr(body.status, "value") else str(body.status),
        user_id=str(current_user.id),
    )
    return AgendamentoResponse.model_validate(ag)
