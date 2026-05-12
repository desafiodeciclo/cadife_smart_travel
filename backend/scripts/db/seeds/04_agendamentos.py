"""
04_agendamentos — 2 realizados (Paris, Tóquio) + 1 confirmado (Nova York).
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
    consultor_id = daniela.id if daniela else admin.id

    otavio = await get_lead_by_phone(session, "+5511966666666")
    camila = await get_lead_by_phone(session, "+5511955555555")
    rafael = await get_lead_by_phone(session, "+5511944444444")

    rows = [
        dict(
            lead_id=otavio.id if otavio else None,
            data=date(2026, 2, 14),
            hora=time(10, 0),
            status=AgendamentoStatus.realizado,
            tipo=AgendamentoTipo.online,
            consultor_id=consultor_id,
        ),
        dict(
            lead_id=camila.id if camila else None,
            data=date(2026, 4, 22),
            hora=time(14, 0),
            status=AgendamentoStatus.realizado,
            tipo=AgendamentoTipo.online,
            consultor_id=consultor_id,
        ),
        dict(
            lead_id=rafael.id if rafael else None,
            data=date(2026, 6, 2),
            hora=time(11, 0),
            status=AgendamentoStatus.confirmado,
            tipo=AgendamentoTipo.online,
            consultor_id=admin.id,
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
