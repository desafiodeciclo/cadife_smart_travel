"""
Curadoria Service — Gatilho de oferta de horários quando briefing atinge 60%
===========================================================================
Responsabilidades:
  - Verificar se lead já possui agendamento ativo (evita oferta repetida)
  - Buscar próximos slots disponíveis para curadoria
  - Gerar mensagem da AYA oferecendo horários de forma natural
"""
from datetime import date, datetime, time, timedelta
from typing import Optional

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import AgendamentoStatus, LeadStatus
from app.models.agendamento import Agendamento

logger = structlog.get_logger()

# Horários fixos de atendimento (seg-sex) — espelha routes/agenda.py
HORARIOS_DISPONIVEIS = ["09:00", "10:00", "11:00", "13:00", "14:00", "15:00"]
MAX_POR_DIA = 6
DIAS_A_FRENTE = 7  # quantos dias à frente buscar slots


async def lead_tem_agendamento_ativo(db: AsyncSession, lead_id) -> bool:
    """Retorna True se o lead já tem agendamento não-cancelado."""
    result = await db.execute(
        select(Agendamento).where(
            Agendamento.lead_id == lead_id,
            Agendamento.status != AgendamentoStatus.cancelado,
        )
    )
    return result.scalar_one_or_none() is not None


async def get_proximos_slots_disponiveis(
    db: AsyncSession,
    quantidade: int = 3,
) -> list[dict]:
    """
    Busca os próximos N slots disponíveis para curadoria.

    Returns:
        Lista de dicts: [{"data": date, "hora": str}, ...]
    """
    slots_disponiveis: list[dict] = []
    hoje = date.today()

    for offset in range(DIAS_A_FRENTE):
        if len(slots_disponiveis) >= quantidade:
            break

        current = hoje + timedelta(days=offset)
        if current.weekday() >= 5:  # pula sábado (5) e domingo (6)
            continue

        result = await db.execute(
            select(Agendamento).where(
                Agendamento.data == current,
                Agendamento.status != AgendamentoStatus.cancelado,
            )
        )
        agendados = result.scalars().all()
        agendados_horas = {str(a.hora)[:5] for a in agendados}

        for hora in HORARIOS_DISPONIVEIS:
            if len(slots_disponiveis) >= quantidade:
                break
            if hora not in agendados_horas and len(agendados) < MAX_POR_DIA:
                slots_disponiveis.append({"data": current, "hora": hora})

    return slots_disponiveis


def gerar_mensagem_oferta_curadoria(slots: list[dict], nome_cliente: Optional[str] = None) -> str:
    """
    Gera mensagem natural da AYA oferecendo horários de curadoria.

    Args:
        slots: Lista de slots disponíveis (máx 3).
        nome_cliente: Nome do cliente para personalização (opcional).

    Returns:
        Mensagem pronta para envio via WhatsApp.
    """
    if not slots:
        return (
            "Que ótimo! Consegui entender bem o que você procura para sua viagem. 😊\n\n"
            "Nossos consultores estão com a agenda cheia no momento, mas vou pedir para entrarem em contato "
            "com você em breve para agendarmos uma conversa personalizada."
        )

    saudacao = f"Oi{nome_cliente + '!' if nome_cliente else '!'}"

    linhas_slots = []
    for i, slot in enumerate(slots, start=1):
        data_str = slot["data"].strftime("%d/%m")
        linhas_slots.append(f"{i}. {data_str} às {slot['hora']}")

    opcoes_texto = "\n".join(linhas_slots)

    return (
        f"{saudacao} Consegui entender direitinho o que você busca para sua viagem — "
        f"já está tudo anotado para nosso consultor! 😊✈️\n\n"
        f"Agora vamos para a parte mais especial: a *curadoria personalizada*. "
        f"Nosso consultor vai montar um roteiro sob medida para você, mas antes precisamos agendar "
        f"uma conversa rápida (cerca de 15 minutos) para alinhar todos os detalhes.\n\n"
        f"Tenho alguns horários disponíveis nos próximos dias:\n\n"
        f"{opcoes_texto}\n\n"
        f"Qual desses dias e horários funciona melhor para você? "
        f"É só responder com o número da opção ou me informar outro horário que verifico a disponibilidade!"
    )


def deve_oferecer_curadoria(
    status_antes: LeadStatus,
    status_depois: LeadStatus,
    completude_pct: int,
) -> bool:
    """
    Decide se deve oferecer curadoria com base na transição de status.

    Regra: oferecer apenas na transição EM_ATENDIMENTO → QUALIFICADO
    quando o briefing acabou de atingir ≥ 60%.
    """
    return (
        status_antes == LeadStatus.em_atendimento
        and status_depois == LeadStatus.qualificado
        and completude_pct >= 60
    )
