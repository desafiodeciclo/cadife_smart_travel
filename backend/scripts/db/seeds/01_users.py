"""
01_users — 4 consultores demo + 3 clientes com preferências de viagem completas.
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

from app.domain.entities.enums import UserPerfil
from shared import get_or_create_user


async def run(session: AsyncSession) -> None:
    # ── Consultores ───────────────────────────────────────────────────────────
    await get_or_create_user(
        session,
        email="daniela.costa@cadifetoure.com.br",
        nome="Daniela Costa",
        perfil=UserPerfil.consultor,
        telefone="+5511977777777",
    )
    await get_or_create_user(
        session,
        email="jakeline.lima@cadifetoure.com.br",
        nome="Jakeline Lima",
        perfil=UserPerfil.consultor,
        telefone="+5511999991111",
    )
    await get_or_create_user(
        session,
        email="diego.costa@cadifetoure.com.br",
        nome="Diego Costa",
        perfil=UserPerfil.consultor,
        telefone="+5511988882222",
    )
    await get_or_create_user(
        session,
        email="marcos.andrade@cadifetoure.com.br",
        nome="Marcos Andrade",
        perfil=UserPerfil.consultor,
        telefone="+5511977773333",
    )
    # ── Clientes ──────────────────────────────────────────────────────────────
    await get_or_create_user(
        session,
        email="otavio.grotto@gmail.com",
        nome="Otávio Grotto",
        perfil=UserPerfil.cliente,
        telefone="+5511966666666",
        tipo_viagem=["turismo", "lazer"],
        preferencias=["luxo", "cidade", "frio"],
        tem_passaporte=True,
    )
    await get_or_create_user(
        session,
        email="camila.santos@gmail.com",
        nome="Camila Santos",
        perfil=UserPerfil.cliente,
        telefone="+5511955555555",
        tipo_viagem=["aventura", "lazer"],
        preferencias=["cidade", "calor"],
        tem_passaporte=True,
    )
    await get_or_create_user(
        session,
        email="rafael.mendes@gmail.com",
        nome="Rafael Mendes",
        perfil=UserPerfil.cliente,
        telefone="+5511944444444",
        tipo_viagem=["turismo", "negócios"],
        preferencias=["cidade"],
        tem_passaporte=False,
    )
    await session.commit()


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
