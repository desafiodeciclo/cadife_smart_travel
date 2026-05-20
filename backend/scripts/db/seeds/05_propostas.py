"""
05_propostas — 8 propostas cobrindo todos os status possíveis.

  Otávio Grotto   → aprovada   R$ 28.500 (Paris, Daniela)
  Camila Santos   → enviada    R$ 18.900 (Tóquio, Daniela)
  Isabela Rocha   → enviada    R$ 22.400 (Orlando, Daniela)
  Carla Mendonça  → aprovada   R$  4.800 (Gramado, Daniela)
  Natália Costa   → aprovada   R$ 16.200 (Portugal+Espanha, Bruno)
  Sérgio Lima     → enviada    R$  9.100 (Cancún, Diego)
  Rafael Mendes   → rascunho   R$ 19.500 (Nova York, Jakeline)
  Ana Luiza Gomes → rascunho   R$ 24.800 (Buenos Aires+Bariloche, Marcos)
"""
from __future__ import annotations

import sys
from pathlib import Path

_BACKEND = Path(__file__).resolve().parents[3]
_SEEDS = Path(__file__).resolve().parent
for _p in [str(_BACKEND), str(_SEEDS)]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import PropostaStatus
from app.models.proposta import Proposta
from shared import get_lead_by_phone, get_user_by_email, get_admin


async def run(session: AsyncSession) -> None:
    admin    = await get_admin(session)
    daniela  = await get_user_by_email(session, "daniela.costa@cadifetoure.com.br")
    jakeline = await get_user_by_email(session, "jakeline.lima@cadifetoure.com.br")
    diego    = await get_user_by_email(session, "diego.costa@cadifetoure.com.br")
    marcos   = await get_user_by_email(session, "marcos.andrade@cadifetoure.com.br")
    bruno    = await get_user_by_email(session, "bruno.ferreira@cadifetoure.com.br")

    daniela_id  = daniela.id  if daniela  else admin.id
    jakeline_id = jakeline.id if jakeline else admin.id
    diego_id    = diego.id    if diego    else admin.id
    marcos_id   = marcos.id   if marcos   else admin.id
    bruno_id    = bruno.id    if bruno    else admin.id

    otavio  = await get_lead_by_phone(session, "+5511966666666")
    camila  = await get_lead_by_phone(session, "+5511955555555")
    isabela = await get_lead_by_phone(session, "+5511966660003")
    carla   = await get_lead_by_phone(session, "+5551933330006")
    natalia = await get_lead_by_phone(session, "+5511911110008")
    sergio  = await get_lead_by_phone(session, "+5521977770011")
    rafael  = await get_lead_by_phone(session, "+5511944444444")
    ana_luiza = await get_lead_by_phone(session, "+5511866666666")

    rows = [
        dict(
            lead_id=otavio.id if otavio else None,
            descricao=(
                "Pacote Paris Romântico 7 dias — Voos TAM direto GRU↔CDG, "
                "hotel Hôtel de Crillon 5★, traslados, jantar exclusivo Torre Eiffel, "
                "passeio de barco no Sena ao pôr do sol, guia privativo em português."
            ),
            valor_estimado=28_500.00,
            status=PropostaStatus.aprovada,
            consultor_id=daniela_id,
            expiration_hours=72,
        ),
        dict(
            lead_id=camila.id if camila else None,
            descricao=(
                "Pacote Japão Explorer 14 dias para 4 pessoas — Voos Qatar Airways "
                "GRU↔NRT com escala em Doha, hotel Shinjuku Granbell 4★, "
                "JR Pass 14 dias, day trips Kyoto e Osaka, workshop de culinária "
                "japonesa com chef local. Cardápio sem frutos do mar disponível."
            ),
            valor_estimado=18_900.00,
            status=PropostaStatus.enviada,
            consultor_id=daniela_id,
            expiration_hours=48,
        ),
        dict(
            lead_id=isabela.id if isabela else None,
            descricao=(
                "Pacote Orlando Família 13 dias — Voos LATAM GRU↔MCO, "
                "hotel Disney's Grand Floridian Resort 5★ (8 noites) + Disney Moderate (5 noites), "
                "Park Hopper Pass 7 dias (Disney + Universal + SeaWorld), "
                "transfer privativo e day trip Premium Outlets International."
            ),
            valor_estimado=22_400.00,
            status=PropostaStatus.enviada,
            consultor_id=daniela_id,
            expiration_hours=72,
        ),
        dict(
            lead_id=carla.id if carla else None,
            descricao=(
                "Pacote Serra Gaúcha Romântico 5 dias — Chalé boutique com lareira e banheira "
                "de hidromassagem, café colonial incluso, jantar especial no Michelon Gastronomia, "
                "degustação em 3 vinícolas premium, visita ao Parque do Caracol."
            ),
            valor_estimado=4_800.00,
            status=PropostaStatus.aprovada,
            consultor_id=daniela_id,
            expiration_hours=48,
        ),
        dict(
            lead_id=natalia.id if natalia else None,
            descricao=(
                "Pacote Ibérico Cultural 13 dias — Voos TAP GRU↔LIS↔MAD, "
                "hotéis boutique históricos 4★ em Lisboa, Porto e Madrid, "
                "guias culturais privativos em português, jantar com espetáculo de fado em Lisboa "
                "e flamenco em Madrid, tour vinícola no Douro e Toledo day trip."
            ),
            valor_estimado=16_200.00,
            status=PropostaStatus.aprovada,
            consultor_id=bruno_id,
            expiration_hours=72,
        ),
        dict(
            lead_id=sergio.id if sergio else None,
            descricao=(
                "Pacote Cancún All Inclusive 9 dias — Voos Azul GRU↔CUN, "
                "resort Iberostar Selection Cancún 5★ all inclusive (open bar 24h), "
                "transfer aeroporto, excursão Chichén Itzá com guia bilíngue, "
                "day trip cenote Ik Kil e Playa del Carmen."
            ),
            valor_estimado=9_100.00,
            status=PropostaStatus.enviada,
            consultor_id=diego_id,
            expiration_hours=48,
        ),
        dict(
            lead_id=rafael.id if rafael else None,
            descricao=(
                "RASCUNHO — Pacote Nova York Família 10 dias — Voos LATAM GRU↔JFK, "
                "hotel Midtown 4★ com 2 quartos comunicantes, New York CityPASS (6 atrações), "
                "day trip Washington D.C. — aguardando confirmação de passaporte."
            ),
            valor_estimado=19_500.00,
            status=PropostaStatus.rascunho,
            consultor_id=jakeline_id,
            expiration_hours=96,
        ),
        dict(
            lead_id=ana_luiza.id if ana_luiza else None,
            descricao=(
                "RASCUNHO — Pacote Lua de Mel Argentina 10 dias — Voos Aerolíneas GRU↔EZE+BRC, "
                "Hotel Palacio Duhau Park Hyatt em Buenos Aires 5★, "
                "Llao Llao Resort & Spa Bariloche 5★ com vista para o lago, "
                "aula de tango privativa, jantar degustação portenho, trekking guiado "
                "e cruzeiro lagos patagônicos."
            ),
            valor_estimado=24_800.00,
            status=PropostaStatus.rascunho,
            consultor_id=marcos_id,
            expiration_hours=96,
        ),
    ]

    for row in rows:
        if not row["lead_id"]:
            continue
        exists = await session.execute(
            select(Proposta).where(Proposta.lead_id == row["lead_id"])
        )
        if exists.scalar_one_or_none():
            print(f"  [SKIP] Proposta lead {row['lead_id']}")
            continue
        session.add(Proposta(**row))
        print(f"  [NEW]  Proposta {row['status'].value} — R$ {row['valor_estimado']:,.2f}")

    await session.commit()


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
