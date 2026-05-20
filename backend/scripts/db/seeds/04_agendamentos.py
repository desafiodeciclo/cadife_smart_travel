"""
04_agendamentos — 10 agendamentos cobrindo todos os status.

Distribuição:
  Daniela Costa  → Otávio (realizado), Camila (realizado), Isabela (confirmado), Carla (realizado)
  Jakeline Lima  → Rafael (confirmado), Felipe (pendente)
  Diego Costa    → Fernanda (confirmado), Sérgio (pendente)
  Marcos Andrade → Ana Luiza (confirmado), Gabriel (confirmado)
  Patricia Silva → Pedro (confirmado), Thiago (confirmado), Amanda (pendente)
  Bruno Ferreira → Luciana (confirmado), Natália (realizado), Eduardo (cancelado)
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
    admin    = await get_admin(session)
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

    otavio   = await get_lead_by_phone(session, "+5511966666666")
    camila   = await get_lead_by_phone(session, "+5511955555555")
    isabela  = await get_lead_by_phone(session, "+5511966660003")
    carla    = await get_lead_by_phone(session, "+5551933330006")
    rafael   = await get_lead_by_phone(session, "+5511944444444")
    felipe   = await get_lead_by_phone(session, "+5511900000009")
    fernanda = await get_lead_by_phone(session, "+5511877777777")
    sergio   = await get_lead_by_phone(session, "+5521977770011")
    ana_luiza= await get_lead_by_phone(session, "+5511866666666")
    gabriel  = await get_lead_by_phone(session, "+5531977770002")
    pedro    = await get_lead_by_phone(session, "+5511933333100")
    thiago   = await get_lead_by_phone(session, "+5511955550004")
    amanda   = await get_lead_by_phone(session, "+5511922220007")
    luciana  = await get_lead_by_phone(session, "+5521988880001")
    natalia  = await get_lead_by_phone(session, "+5511911110008")
    eduardo  = await get_lead_by_phone(session, "+5511855550012")

    rows = [
        # Daniela Costa
        dict(lead_id=otavio.id   if otavio   else None, data=date(2026, 2, 14), hora=time(10, 0),  status=AgendamentoStatus.realizado,  tipo=AgendamentoTipo.online,     consultor_id=daniela_id),
        dict(lead_id=camila.id   if camila   else None, data=date(2026, 4, 22), hora=time(14, 0),  status=AgendamentoStatus.realizado,  tipo=AgendamentoTipo.online,     consultor_id=daniela_id),
        dict(lead_id=isabela.id  if isabela  else None, data=date(2026, 5, 28), hora=time(15, 0),  status=AgendamentoStatus.confirmado, tipo=AgendamentoTipo.online,     consultor_id=daniela_id),
        dict(lead_id=carla.id    if carla    else None, data=date(2026, 4, 10), hora=time(11, 0),  status=AgendamentoStatus.realizado,  tipo=AgendamentoTipo.presencial, consultor_id=daniela_id),
        # Jakeline Lima
        dict(lead_id=rafael.id   if rafael   else None, data=date(2026, 6, 2),  hora=time(11, 0),  status=AgendamentoStatus.confirmado, tipo=AgendamentoTipo.online,     consultor_id=jakeline_id),
        dict(lead_id=felipe.id   if felipe   else None, data=date(2026, 6, 15), hora=time(16, 0),  status=AgendamentoStatus.pendente,   tipo=AgendamentoTipo.online,     consultor_id=jakeline_id),
        # Diego Costa
        dict(lead_id=fernanda.id if fernanda else None, data=date(2026, 6, 20), hora=time(10, 0),  status=AgendamentoStatus.confirmado, tipo=AgendamentoTipo.online,     consultor_id=diego_id),
        dict(lead_id=sergio.id   if sergio   else None, data=date(2026, 6, 25), hora=time(14, 30), status=AgendamentoStatus.pendente,   tipo=AgendamentoTipo.online,     consultor_id=diego_id),
        # Marcos Andrade
        dict(lead_id=ana_luiza.id if ana_luiza else None, data=date(2026, 7, 10), hora=time(15, 0), status=AgendamentoStatus.confirmado, tipo=AgendamentoTipo.online,    consultor_id=marcos_id),
        dict(lead_id=gabriel.id  if gabriel  else None, data=date(2026, 7, 18), hora=time(10, 30), status=AgendamentoStatus.confirmado, tipo=AgendamentoTipo.online,     consultor_id=marcos_id),
        # Patricia Silva
        dict(lead_id=pedro.id    if pedro    else None, data=date(2026, 6, 5),  hora=time(9, 0),   status=AgendamentoStatus.confirmado, tipo=AgendamentoTipo.online,     consultor_id=patricia_id),
        dict(lead_id=thiago.id   if thiago   else None, data=date(2026, 6, 12), hora=time(11, 0),  status=AgendamentoStatus.confirmado, tipo=AgendamentoTipo.presencial, consultor_id=patricia_id),
        dict(lead_id=amanda.id   if amanda   else None, data=date(2026, 6, 20), hora=time(15, 0),  status=AgendamentoStatus.pendente,   tipo=AgendamentoTipo.online,     consultor_id=patricia_id),
        # Bruno Ferreira
        dict(lead_id=luciana.id  if luciana  else None, data=date(2026, 5, 20), hora=time(14, 0),  status=AgendamentoStatus.confirmado, tipo=AgendamentoTipo.online,     consultor_id=bruno_id),
        dict(lead_id=natalia.id  if natalia  else None, data=date(2026, 4, 5),  hora=time(10, 0),  status=AgendamentoStatus.realizado,  tipo=AgendamentoTipo.presencial, consultor_id=bruno_id),
        dict(lead_id=eduardo.id  if eduardo  else None, data=date(2026, 3, 15), hora=time(16, 0),  status=AgendamentoStatus.cancelado,  tipo=AgendamentoTipo.online,     consultor_id=bruno_id),
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
