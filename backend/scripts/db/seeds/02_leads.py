"""
02_leads — 5 leads cobrindo todo o ciclo de vida: novo → fechado.
"""
from __future__ import annotations

import sys
from pathlib import Path

_BACKEND = Path(__file__).resolve().parents[3]
_SEEDS = Path(__file__).resolve().parent
for _p in [str(_BACKEND), str(_SEEDS)]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import LeadOrigem, LeadScore, LeadStatus
from shared import get_admin, get_or_create_lead, get_user_by_email


async def run(session: AsyncSession) -> None:
    admin = await get_admin(session)
    daniela = await get_user_by_email(session, "daniela.costa@cadifetoure.com.br")
    consultor_id = daniela.id if daniela else admin.id

    await get_or_create_lead(
        session,
        telefone="+5511966666666",
        nome="Otávio Grotto",
        origem=LeadOrigem.app,
        status=LeadStatus.fechado,
        score=LeadScore.quente,
        consultor_id=consultor_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511955555555",
        nome="Camila Santos",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.proposta,
        score=LeadScore.morno,
        consultor_id=consultor_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511944444444",
        nome="Rafael Mendes",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.agendado,
        score=LeadScore.quente,
        consultor_id=admin.id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511999999999",
        nome="João Silva",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.novo,
        consultor_id=admin.id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511888888888",
        nome="Maria Oliveira",
        origem=LeadOrigem.web,
        status=LeadStatus.em_atendimento,
        consultor_id=admin.id,
    )
    await session.commit()


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
