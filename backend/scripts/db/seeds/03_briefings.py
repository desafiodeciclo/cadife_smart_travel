"""
03_briefings — Briefings com 100%, 96% e 92% de completude + 2 parciais.
"""
from __future__ import annotations

import sys
from pathlib import Path
from datetime import date

_BACKEND = Path(__file__).resolve().parents[3]
_SEEDS = Path(__file__).resolve().parent
for _p in [str(_BACKEND), str(_SEEDS)]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import OrcamentoPerfil, PerfilViagem
from shared import get_lead_by_phone, get_or_create_briefing


async def run(session: AsyncSession) -> None:
    otavio = await get_lead_by_phone(session, "+5511966666666")
    camila = await get_lead_by_phone(session, "+5511955555555")
    rafael = await get_lead_by_phone(session, "+5511944444444")
    joao = await get_lead_by_phone(session, "+5511999999999")
    maria = await get_lead_by_phone(session, "+5511888888888")

    if otavio:
        await get_or_create_briefing(
            session,
            lead_id=otavio.id,
            destino="Paris, França",
            origem="São Paulo, Brasil",
            data_ida=date(2026, 3, 10),
            data_volta=date(2026, 3, 17),
            duracao_dias=7,
            qtd_pessoas=2,
            perfil=PerfilViagem.casal,
            tipo_viagem=["romântica", "luxo", "turismo"],
            preferencias=["monumentos", "restaurantes estrelados", "museus"],
            orcamento=OrcamentoPerfil.premium,
            tem_passaporte=True,
            observacoes="Aniversário de casamento. Preferem hotéis no coração de Paris.",
        )

    if camila:
        await get_or_create_briefing(
            session,
            lead_id=camila.id,
            destino="Tóquio, Japão",
            origem="São Paulo, Brasil",
            data_ida=date(2026, 8, 5),
            data_volta=date(2026, 8, 19),
            duracao_dias=14,
            qtd_pessoas=4,
            perfil=PerfilViagem.amigos,
            tipo_viagem=["aventura", "gastronomia"],
            preferencias=["templos", "culinária local", "lojas de anime"],
            orcamento=OrcamentoPerfil.alto,
            observacoes="Grupo de 4 amigas. Uma tem alergia a frutos do mar.",
        )

    if rafael:
        await get_or_create_briefing(
            session,
            lead_id=rafael.id,
            destino="Nova York, EUA",
            origem="Belo Horizonte, Brasil",
            data_ida=date(2026, 7, 15),
            data_volta=date(2026, 7, 25),
            duracao_dias=10,
            qtd_pessoas=4,
            perfil=PerfilViagem.familia,
            tipo_viagem=["turismo", "compras"],
            orcamento=OrcamentoPerfil.alto,
            observacoes="2 adultos e 2 crianças (8 e 12 anos). Querem visitar a Disney.",
        )

    if joao:
        await get_or_create_briefing(
            session,
            lead_id=joao.id,
            destino="Europa",
            observacoes="Ainda definindo roteiro. Interesse em Portugal ou Espanha.",
        )

    if maria:
        await get_or_create_briefing(
            session,
            lead_id=maria.id,
            destino="Cancún, México",
            data_ida=date(2026, 12, 20),
            qtd_pessoas=2,
            perfil=PerfilViagem.casal,
            orcamento=OrcamentoPerfil.medio,
        )

    await session.commit()


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
