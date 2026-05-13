"""
10_travel_diary — Entradas do diário de viagem por cliente.

Cobre os dados mockados em:
  - frontend_flutter/lib/features/client/profile/data/mocks/client_profile_mocks.dart
    (5 entradas: 3 para Paris/Otávio e 2 para Tóquio/Camila)

Campos mapeados:
  - tripId 'trip-paris'  → lead Otávio Grotto (+5511966666666)
  - tripId 'trip-tokyo'  → lead Camila Santos (+5511955555555)
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
        "Primeiro dia em Paris! A Torre Eiffel é ainda mais linda pessoalmente 🗼",
        _dt(2026, 6, 15),
    ),
    (
        "https://picsum.photos/seed/paris2/800/600",
        "Croissant de manhã, vinho à noite — Paris perfeita! 🥐🍷",
        _dt(2026, 6, 17),
    ),
    (
        "https://picsum.photos/seed/paris3/800/600",
        "Passeio de barco no Sena ao pôr do sol. Simplesmente inesquecível 🌅",
        _dt(2026, 6, 19),
    ),
]

_TOKYO_ENTRIES = [
    (
        "https://picsum.photos/seed/tokyo1/800/600",
        "Tóquio me impressionou desde o primeiro instante. Akihabara e Shibuya num só dia! 🎌",
        _dt(2026, 7, 10),
    ),
    (
        "https://picsum.photos/seed/kyoto1/800/600",
        "Day trip para Kyoto: templos, gueixas e o jardim de bambu. Uma viagem no tempo 🏯",
        _dt(2026, 7, 14),
    ),
]


async def run(session: AsyncSession) -> None:
    otavio_lead = await get_lead_by_phone(session, "+5511966666666")
    camila_lead = await get_lead_by_phone(session, "+5511955555555")

    otavio_user = await get_user_by_email(session, "otavio.grotto@gmail.com")
    camila_user = await get_user_by_email(session, "camila.santos@gmail.com")

    batches = [
        (otavio_lead, otavio_user, _PARIS_ENTRIES, "Otávio (Paris)"),
        (camila_lead, camila_user, _TOKYO_ENTRIES, "Camila (Tóquio)"),
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
