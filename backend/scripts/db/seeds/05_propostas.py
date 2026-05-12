"""
05_propostas — Paris aprovada (R$ 28.500) + Tóquio enviada (R$ 18.900).
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
    admin = await get_admin(session)
    daniela = await get_user_by_email(session, "daniela.costa@cadifetoure.com.br")
    consultor_id = daniela.id if daniela else admin.id

    otavio = await get_lead_by_phone(session, "+5511966666666")
    camila = await get_lead_by_phone(session, "+5511955555555")

    rows = [
        dict(
            lead_id=otavio.id if otavio else None,
            descricao=(
                "Pacote Paris Romântico 7 dias — Voos TAM direto São Paulo↔Paris, "
                "hotel Hôtel de Crillon 5★, traslados, jantar exclusivo Torre Eiffel, "
                "passeio de barco no Sena ao pôr do sol, guia privativo em português."
            ),
            valor_estimado=28500.00,
            status=PropostaStatus.aprovada,
            consultor_id=consultor_id,
            expiration_hours=72,
        ),
        dict(
            lead_id=camila.id if camila else None,
            descricao=(
                "Pacote Japão Explorer 14 dias para 4 pessoas — Voos Qatar Airways "
                "São Paulo↔Tóquio com escala em Doha, hotel Shinjuku Granbell 4★, "
                "JR Pass 14 dias, day trips Kyoto e Osaka, experiência de culinária "
                "japonesa com chef local. Produto sem frutos do mar disponível."
            ),
            valor_estimado=18900.00,
            status=PropostaStatus.enviada,
            consultor_id=consultor_id,
            expiration_hours=48,
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
