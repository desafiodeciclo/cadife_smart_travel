"""
02_leads — 20 leads cobrindo todo o ciclo de vida e todas as origens.

Distribuição por consultor:
  Daniela Costa   → Otávio (fechado), Camila (proposta), Isabela (proposta), Carla (fechado)
  Jakeline Lima   → João (novo), Rafael (agendado), Roberto (perdido), Felipe (novo)
  Diego Costa     → Maria (em_atendimento), Fernanda (qualificado), Sérgio (proposta)
  Marcos Andrade  → Ana Luiza (qualificado), Gabriel (qualificado), Natália (fechado)
  Patricia Silva  → Pedro (em_atendimento), Thiago (agendado), Amanda (em_atendimento)
  Bruno Ferreira  → Luciana (qualificado), Priscila (qualificado), Eduardo (perdido)
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
    daniela  = await get_user_by_email(session, "daniela.costa@cadifetoure.com.br")
    jakeline = await get_user_by_email(session, "jakeline.lima@cadifetoure.com.br")
    diego    = await get_user_by_email(session, "diego.costa@cadifetoure.com.br")
    marcos   = await get_user_by_email(session, "marcos.andrade@cadifetoure.com.br")
    patricia = await get_user_by_email(session, "patricia.silva@cadifetoure.com.br")
    bruno    = await get_user_by_email(session, "bruno.ferreira@cadifetoure.com.br")

    daniela_id  = daniela.id  if daniela  else admin.id
    jakeline_id = jakeline.id if jakeline else admin.id
    diego_id    = diego.id    if diego    else admin.id
    marcos_id   = marcos.id   if marcos   else admin.id
    patricia_id = patricia.id if patricia else admin.id
    bruno_id    = bruno.id    if bruno    else admin.id

    # ── Daniela Costa ─────────────────────────────────────────────────────────
    await get_or_create_lead(
        session,
        telefone="+5511966666666",
        nome="Otávio Grotto",
        origem=LeadOrigem.app,
        status=LeadStatus.fechado,
        score=LeadScore.quente,
        score_numerico=95,
        consultor_id=daniela_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511955555555",
        nome="Camila Santos",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.proposta,
        score=LeadScore.morno,
        score_numerico=68,
        consultor_id=daniela_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511966660003",
        nome="Isabela Rocha",
        origem=LeadOrigem.app,
        status=LeadStatus.proposta,
        score=LeadScore.quente,
        score_numerico=88,
        consultor_id=daniela_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5551933330006",
        nome="Carla Mendonça",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.fechado,
        score=LeadScore.quente,
        score_numerico=92,
        consultor_id=daniela_id,
    )

    # ── Jakeline Lima ──────────────────────────────────────────────────────────
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
        score_numerico=75,
        consultor_id=jakeline_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511833330010",
        nome="Roberto Carvalho",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.perdido,
        score=LeadScore.frio,
        score_numerico=18,
        consultor_id=jakeline_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511900000009",
        nome="Felipe Souza",
        origem=LeadOrigem.web,
        status=LeadStatus.novo,
        consultor_id=jakeline_id,
    )

    # ── Diego Costa ───────────────────────────────────────────────────────────
    await get_or_create_lead(
        session,
        telefone="+5511888888888",
        nome="Maria Oliveira",
        origem=LeadOrigem.web,
        status=LeadStatus.em_atendimento,
        score=LeadScore.morno,
        score_numerico=52,
        consultor_id=diego_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511877777777",
        nome="Fernanda Castro",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.qualificado,
        score=LeadScore.quente,
        score_numerico=84,
        consultor_id=diego_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5521977770011",
        nome="Sérgio Lima",
        origem=LeadOrigem.app,
        status=LeadStatus.proposta,
        score=LeadScore.quente,
        score_numerico=80,
        consultor_id=diego_id,
    )

    # ── Marcos Andrade ────────────────────────────────────────────────────────
    await get_or_create_lead(
        session,
        telefone="+5511866666666",
        nome="Ana Luiza Gomes",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.qualificado,
        score=LeadScore.quente,
        score_numerico=88,
        consultor_id=marcos_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5531977770002",
        nome="Gabriel Nogueira",
        origem=LeadOrigem.manual,
        status=LeadStatus.qualificado,
        score=LeadScore.quente,
        score_numerico=78,
        consultor_id=marcos_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511911110008",
        nome="Natália Costa",
        origem=LeadOrigem.manual,
        status=LeadStatus.fechado,
        score=LeadScore.quente,
        score_numerico=91,
        consultor_id=marcos_id,
    )

    # ── Patricia Silva ────────────────────────────────────────────────────────
    await get_or_create_lead(
        session,
        telefone="+5511933333100",
        nome="Pedro Alves",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.em_atendimento,
        score=LeadScore.morno,
        score_numerico=62,
        consultor_id=patricia_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511955550004",
        nome="Thiago Martins",
        origem=LeadOrigem.telefone,
        status=LeadStatus.agendado,
        score=LeadScore.morno,
        score_numerico=55,
        consultor_id=patricia_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511922220007",
        nome="Amanda Ribeiro",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.em_atendimento,
        score=LeadScore.morno,
        score_numerico=48,
        consultor_id=patricia_id,
    )

    # ── Bruno Ferreira ────────────────────────────────────────────────────────
    await get_or_create_lead(
        session,
        telefone="+5521988880001",
        nome="Luciana Ferreira",
        origem=LeadOrigem.web,
        status=LeadStatus.qualificado,
        score=LeadScore.quente,
        score_numerico=82,
        consultor_id=bruno_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511944440005",
        nome="Priscila Oliveira",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.qualificado,
        score=LeadScore.quente,
        score_numerico=72,
        consultor_id=bruno_id,
    )
    await get_or_create_lead(
        session,
        telefone="+5511855550012",
        nome="Eduardo Pinheiro",
        origem=LeadOrigem.web,
        status=LeadStatus.perdido,
        score=LeadScore.frio,
        score_numerico=12,
        consultor_id=bruno_id,
    )

    await session.commit()


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
