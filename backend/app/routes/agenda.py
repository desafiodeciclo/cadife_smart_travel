import hashlib
import uuid
from datetime import date, time

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, text
from sqlalchemy.exc import IntegrityError
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
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.services import lead_service

logger = structlog.get_logger()

router = APIRouter(
    prefix="/agenda",
    tags=["Agenda"],
    dependencies=[Depends(RequiresRole("consultor", "admin"))],
)

# Configurações de Negócio
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
        # Calcula o próximo slot (incremento de 1h)
        next_hour = (current.hour * 60 + current.minute + SLOT_STEP_MINUTOS) // 60
        current = time(next_hour, 0)
    return slots


_SLOTS_PADRAO = _generate_slots()


def _hora_alinhada_com_slot(hora: time) -> bool:
    """Verifica se a hora está alinhada com os slots de 1h permitidos."""
    return (
        hora.minute == 0 
        and hora.second == 0 
        and HORA_ABERTURA.hour <= hora.hour < HORA_FECHAMENTO.hour
    )


async def _buscar_agendamentos_do_dia(
    db: AsyncSession,
    data: date,
    lock_for_update: bool = False
) -> list[Agendamento]:
    """Busca agendamentos ativos para o dia, opcionalmente travando as linhas."""
    stmt = select(Agendamento).where(
        Agendamento.data == data,
        Agendamento.status != AgendamentoStatus.cancelado,
    )
    if lock_for_update:
        stmt = stmt.with_for_update()
        
    result = await db.execute(stmt)
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
    """Verifica disponibilidade considerando a capacidade e sobreposição."""
    if len(agendamentos) >= MAX_POR_DIA:
        return False
    return all(
        not _blocos_se_sobrepoe(slot, ag.hora)
        for ag in agendamentos
    )


def _slot_lock_key(data: date, hora_str: str) -> int:
    """Gera uma chave estável para o pg_advisory_xact_lock baseada em data e hora."""
    raw = f"{data.isoformat()}_{hora_str}".encode()
    return int(hashlib.sha256(raw).hexdigest(), 16) % (2**63)


@router.get(
    "/disponibilidade",
    response_model=DisponibilidadeResponse,
    summary="Consultar disponibilidade de horários",
    description="Retorna os slots de horário disponíveis para agendamento de curadoria em uma data específica.",
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Perfil sem permissão", "model": HTTPErrorResponse},
        422: {"description": "Data inválida ou fora do formato", "model": HTTPErrorResponse},
    },
)
async def get_disponibilidade(
    data: date = Query(..., description="Data para consulta (YYYY-MM-DD)"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> DisponibilidadeResponse:
    """Retorna slots de disponibilidade para uma data específica."""
    if data.weekday() >= 5:  # Sábado e Domingo
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
    "",
    response_model=AgendamentoResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Criar agendamento",
    description=(
        "Cria um agendamento de curadoria com validação de conflitos, trava de concorrência (pg_advisory_xact_lock) "
        "e verificação de capacidade diária. Apenas dias úteis e horários entre 09:00–15:00 são permitidos."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Perfil sem permissão", "model": HTTPErrorResponse},
        404: {"description": "Lead não encontrado", "model": HTTPErrorResponse},
        409: {"description": "Conflito de horário ou capacidade esgotada", "model": HTTPErrorResponse},
        422: {"description": "Data/hora inválida ou fora dos slots permitidos", "model": HTTPErrorResponse},
    },
)
async def create_agendamento(
    body: AgendamentoCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AgendamentoResponse:
    """
    Cria um agendamento com validação de conflitos e trava de concorrência.
    """
    # 1. Validações de Regra de Negócio (Data/Hora)
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

    # 2. Validação de Segurança e Existência (Lead)
    lead = await lead_service.get_lead_by_id(db, body.lead_id)
    if not lead:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lead não encontrado",
        )
    check_lead_access(current_user, lead)

    # 3. Lógica de Concorrência (Locking)
    hora_str = body.hora.strftime("%H:%M")
    lock_key = _slot_lock_key(body.data, hora_str)
    
    # Bloqueia qualquer outra transação tentando o mesmo slot
    await db.execute(text("SELECT pg_advisory_xact_lock(:key)"), {"key": lock_key})

    # Busca agendamentos atuais com bloqueio de linha (FOR UPDATE)
    agendamentos = await _buscar_agendamentos_do_dia(db, body.data, lock_for_update=True)

    # 4. Validação de Capacidade
    if len(agendamentos) >= MAX_POR_DIA:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Capacidade diária esgotada: máximo de {MAX_POR_DIA} atendimentos",
        )

    # 5. Validação de Disponibilidade de Horário
    if not _slot_disponivel(body.hora, agendamentos):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Este horário já foi reservado ou conflita com outro agendamento",
        )

    try:
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
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Erro de integridade ao salvar. O horário pode ter sido ocupado.",
        )

    logger.info(
        "agendamento_created",
        agendamento_id=str(agendamento.id),
        lead_id=str(body.lead_id),
        user_id=str(current_user.id),
    )
    return AgendamentoResponse.model_validate(agendamento)


@router.get(
    "/{agendamento_id}",
    response_model=AgendamentoResponse,
    summary="Detalhes de um agendamento",
    description="Retorna os dados de um agendamento específico, com verificação de acesso ao lead vinculado.",
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para o lead vinculado", "model": HTTPErrorResponse},
        404: {"description": "Agendamento não encontrado", "model": HTTPErrorResponse},
    },
)
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


@router.put(
    "/{agendamento_id}",
    response_model=AgendamentoResponse,
    summary="Atualizar agendamento",
    description="Atualiza o status de um agendamento existente.",
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão para o lead vinculado", "model": HTTPErrorResponse},
        404: {"description": "Agendamento não encontrado", "model": HTTPErrorResponse},
        422: {"description": "Status inválido", "model": HTTPErrorResponse},
    },
)
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
        new_status=str(body.status),
        user_id=str(current_user.id),
    )
    return AgendamentoResponse.model_validate(ag)