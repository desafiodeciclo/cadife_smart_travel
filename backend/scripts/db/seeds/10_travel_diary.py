"""
10_travel_diary — Entradas do diário de viagem por cliente.

Clientes com diário:
  Otávio Grotto  → 5 entradas (Paris — viagem realizada)
  Camila Santos  → 5 entradas (Tóquio — viagem realizada)
  Natália Costa  → 4 entradas (Portugal+Espanha — viagem realizada)
  Carla Mendonça → 3 entradas (Gramado — viagem realizada)
"""
from __future__ import annotations

import sys
from datetime import datetime, timezone
from pathlib import Path

_BACKEND = Path(__file__).resolve().parents[3]
_SEEDS = Path(__file__).resolve().parent
for _p in [str(_BACKEND), str(_SEEDS)]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.persistence.models.travel_diary_model import TravelDiaryEntryModel
from shared import get_lead_by_phone, get_user_by_email


def _dt(year: int, month: int, day: int) -> datetime:
    return datetime(year, month, day, 12, 0, 0, tzinfo=timezone.utc)


# (foto_url, nota, data_entrada)

_PARIS_ENTRIES = [
    (
        "https://picsum.photos/seed/paris1/800/600",
        "Primeiro dia em Paris! A Torre Eiffel é ainda mais linda pessoalmente.",
        _dt(2026, 3, 11),
    ),
    (
        "https://picsum.photos/seed/paris2/800/600",
        "Croissant de manhã no Café de Flore, vinho à noite em Montmartre. Paris perfeita!",
        _dt(2026, 3, 12),
    ),
    (
        "https://picsum.photos/seed/paris3/800/600",
        "Museu do Louvre de manhã — a Mona Lisa ao vivo é surreal. Tarde livre no Marais.",
        _dt(2026, 3, 13),
    ),
    (
        "https://picsum.photos/seed/versailles/800/600",
        "Day trip a Versalhes! O Salão dos Espelhos tirou o fôlego. Jardins inesquecíveis.",
        _dt(2026, 3, 14),
    ),
    (
        "https://picsum.photos/seed/paris5/800/600",
        "Passeio de barco no Sena ao pôr do sol com champanhe. A melhor despedida de Paris!",
        _dt(2026, 3, 16),
    ),
]

_TOKYO_ENTRIES = [
    (
        "https://picsum.photos/seed/tokyo1/800/600",
        "Tóquio me impressionou desde o primeiro instante. Akihabara e Shibuya num só dia!",
        _dt(2026, 8, 7),
    ),
    (
        "https://picsum.photos/seed/kyoto1/800/600",
        "Day trip para Kyoto: templos, gueixas e o jardim de bambu. Uma viagem no tempo.",
        _dt(2026, 8, 10),
    ),
    (
        "https://picsum.photos/seed/tokyo2/800/600",
        "Workshop de sushi! O chef nos ensinou a fazer nigiri e gyoza. Sem frutos do mar para a Bia.",
        _dt(2026, 8, 11),
    ),
    (
        "https://picsum.photos/seed/osaka1/800/600",
        "Osaka! Takoyaki, okonomiyaki e o Castelo de Osaka. Gastronomia incrível.",
        _dt(2026, 8, 12),
    ),
    (
        "https://picsum.photos/seed/tokyo3/800/600",
        "Último dia: compras em Harajuku e Omotesando. Mala quase não fechou!",
        _dt(2026, 8, 18),
    ),
]

_PORTUGAL_ENTRIES = [
    (
        "https://picsum.photos/seed/lisboa1/800/600",
        "Lisboa incrível! O tramway subindo para o Castelo de São Jorge, pastéis de Belém na mão.",
        _dt(2026, 5, 9),
    ),
    (
        "https://picsum.photos/seed/porto1/800/600",
        "Porto: a Livraria Lello, o pôr do sol na Ribeira e vinho do Porto direto das caves. Inesquecível.",
        _dt(2026, 5, 13),
    ),
    (
        "https://picsum.photos/seed/madrid1/800/600",
        "Madrid! Museu do Prado de manhã — Velázquez e Goya ao vivo. Tapas no La Latina à noite.",
        _dt(2026, 5, 17),
    ),
    (
        "https://picsum.photos/seed/toledo1/800/600",
        "Day trip a Toledo: cidade medieval intacta no topo de uma rocha. História pura.",
        _dt(2026, 5, 19),
    ),
]

_GRAMADO_ENTRIES = [
    (
        "https://picsum.photos/seed/gramado1/800/600",
        "Chegamos ao chalé e a lareira já estava acesa. Gramado no inverno é um conto de fadas!",
        _dt(2026, 6, 21),
    ),
    (
        "https://picsum.photos/seed/gramado2/800/600",
        "Tour pelas vinícolas de Bento Gonçalves. Chardonnay e queijo colonial — simplesmente perfeito.",
        _dt(2026, 6, 23),
    ),
    (
        "https://picsum.photos/seed/gramado3/800/600",
        "Último dia: chocolate quente, chocolaterie e Parque do Caracol. A cachoeira congelou!",
        _dt(2026, 6, 25),
    ),
]


async def run(session: AsyncSession) -> None:
    otavio_lead  = await get_lead_by_phone(session, "+5511966666666")
    camila_lead  = await get_lead_by_phone(session, "+5511955555555")
    natalia_lead = await get_lead_by_phone(session, "+5511911110008")
    carla_lead   = await get_lead_by_phone(session, "+5551933330006")

    otavio_user  = await get_user_by_email(session, "otavio.grotto@gmail.com")
    camila_user  = await get_user_by_email(session, "camila.santos@gmail.com")
    natalia_user = await get_user_by_email(session, "natalia.costa@gmail.com")
    carla_user   = await get_user_by_email(session, "carla.mendonca@gmail.com")

    batches = [
        (otavio_lead,  otavio_user,  _PARIS_ENTRIES,    "Otávio (Paris)"),
        (camila_lead,  camila_user,  _TOKYO_ENTRIES,    "Camila (Tóquio)"),
        (natalia_lead, natalia_user, _PORTUGAL_ENTRIES, "Natália (Portugal+Espanha)"),
        (carla_lead,   carla_user,   _GRAMADO_ENTRIES,  "Carla (Gramado)"),
    ]

    for lead, user, entries, label in batches:
        if not lead or not user:
            print(f"  [SKIP] Diary {label} — lead ou usuário não encontrado")
            continue

        exists = await session.execute(
            select(TravelDiaryEntryModel)
            .where(TravelDiaryEntryModel.lead_id == lead.id)
            .limit(1)
        )
        if exists.scalar_one_or_none():
            print(f"  [SKIP] Diary entries {label}")
            continue

        for foto_url, nota, data_entrada in entries:
            session.add(
                TravelDiaryEntryModel(
                    lead_id=lead.id,
                    user_id=user.id,
                    foto_url=foto_url,
                    thumb_url=foto_url.replace("/800/600", "/200/200"),
                    nota=nota,
                    data_entrada=data_entrada,
                )
            )

        await session.commit()
        print(f"  [NEW]  {len(entries)} diary entries → {label}")


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
