"""
04_agendamentos — 2 realizados (Paris/Otávio e Tóquio/Camila) + 2 confirmados (Rafael e Ana Luiza).

Distribuição por consultor:
  Daniela Costa → Otávio (realizado 2026-02-14), Camila (realizado 2026-04-22)
  Jakeline Lima → Rafael (confirmado 2026-06-02)
  Marcos Andrade → Ana Luiza (confirmado 2026-07-10)
"""
from __future__ import annotations

import sys
from pathlib import Path
from datetime import date, time

_BACKEND = Path(__file__).resolve().parents[3]
_SEEDS = Path(__file__).resolve().parent
for _p in [str(_BACKEND), str(_SEEDS)]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import AgendamentoStatus, AgendamentoTipo
from app.models.agendamento import Agendamento
from shared import get_admin, get_lead_by_phone, get_user_by_email


async def run(session: AsyncSession) -> None:
    admin = await get_admin(session)
    daniela = await get_user_by_email(session, "daniela.costa@cadifetoure.com.br")
    jakeline = await get_user_by_email(session, "jakeline.lima@cadifetoure.com.br")
    marcos = await get_user_by_email(session, "marcos.andrade@cadifetoure.com.br")

    daniela_id = daniela.id if daniela else admin.id
    jakeline_id = jakeline.id if jakeline else admin.id
    marcos_id = marcos.id if marcos else admin.id

    otavio = await get_lead_by_phone(session, "+5511966666666")
    camila = await get_lead_by_phone(session, "+5511955555555")
    rafael = await get_lead_by_phone(session, "+5511944444444")
    ana_luiza = await get_lead_by_phone(session, "+5511866666666")

    rows = [
        dict(
            lead_id=otavio.id if otavio else None,
            data=date(2026, 2, 14),
            hora=time(10, 0),
            status=AgendamentoStatus.realizado,
            tipo=AgendamentoTipo.online,
            consultor_id=daniela_id,
        ),
        dict(
            lead_id=camila.id if camila else None,
            data=date(2026, 4, 22),
            hora=time(14, 0),
            status=AgendamentoStatus.realizado,
            tipo=AgendamentoTipo.online,
            consultor_id=daniela_id,
        ),
        dict(
            lead_id=rafael.id if rafael else None,
            data=date(2026, 6, 2),
            hora=time(11, 0),
            status=AgendamentoStatus.confirmado,
            tipo=AgendamentoTipo.online,
            consultor_id=jakeline_id,
        ),
        dict(
            lead_id=ana_luiza.id if ana_luiza else None,
            data=date(2026, 7, 10),
            hora=time(15, 0),
            status=AgendamentoStatus.confirmado,
            tipo=AgendamentoTipo.online,
            consultor_id=marcos_id,
        ),
    ]

    for row in rows:
        if not row["lead_id"]:
            continue
        exists = await session.execute(
            select(Agendamento).where(
                Agendamento.lead_id == row["lead_id"],
                Agendamento.data == row["data"],
            )
        )
        if exists.scalar_one_or_none():
            print(f"  [SKIP] Agendamento {row['data']}")
            continue
        session.add(Agendamento(**row))
        print(f"  [NEW]  Agendamento {row['data']} ({row['status'].value})")

    await session.commit()


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
