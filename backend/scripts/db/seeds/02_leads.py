"""
02_leads — 6 leads cobrindo todo o ciclo de vida: novo → fechado.

Distribuição por consultor (alinhada com mock_admin_repository.dart):
  Daniela Costa  → Otávio (fechado), Camila (proposta)
  Jakeline Lima  → João (novo), Rafael (agendado)
  Diego Costa    → Maria (em_atendimento), Fernanda (qualificado)
  Marcos Andrade → Ana Luiza (qualificado)  ← novo lead
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
    jakeline = await get_user_by_email(session, "jakeline.lima@cadifetoure.com.br")
    diego = await get_user_by_email(session, "diego.costa@cadifetoure.com.br")
    marcos = await get_user_by_email(session, "marcos.andrade@cadifetoure.com.br")

    daniela_id = daniela.id if daniela else admin.id
    jakeline_id = jakeline.id if jakeline else admin.id
    diego_id = diego.id if diego else admin.id
    marcos_id = marcos.id if marcos else admin.id

    # Daniela Costa → leads fechado + proposta
    await get_or_create_lead(
        session,
        telefone="+5511966666666",
        nome="Otávio Grotto",
        origem=LeadOrigem.app,
        status=LeadStatus.fechado,
        score=LeadScore.quente,
        consultor_id=daniela_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511955555555",
        nome="Camila Santos",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.proposta,
        score=LeadScore.morno,
        consultor_id=daniela_id,
    )

    # Jakeline Lima → leads novo + agendado
    await get_or_create_lead(
        session,
        telefone="+5511999999999",
        nome="João Silva",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.novo,
        consultor_id=jakeline_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511944444444",
        nome="Rafael Mendes",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.agendado,
        score=LeadScore.quente,
        consultor_id=jakeline_id,
    )

    # Diego Costa → leads em_atendimento + qualificado
    await get_or_create_lead(
        session,
        telefone="+5511888888888",
        nome="Maria Oliveira",
        origem=LeadOrigem.web,
        status=LeadStatus.em_atendimento,
        score=LeadScore.morno,
        consultor_id=diego_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511877777777",
        nome="Fernanda Castro",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.qualificado,
        score=LeadScore.quente,
        consultor_id=diego_id,
    )

    # Marcos Andrade → lead qualificado
    await get_or_create_lead(
        session,
        telefone="+5511866666666",
        nome="Ana Luiza Gomes",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.qualificado,
        score=LeadScore.quente,
        consultor_id=marcos_id,
    )

    await session.commit()


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
