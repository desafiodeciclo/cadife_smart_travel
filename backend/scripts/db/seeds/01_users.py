"""
01_users — 6 consultores demo + 10 clientes com preferências de viagem.

Consultores: Daniela, Jakeline, Diego, Marcos, Patricia, Bruno
Clientes: Otávio, Camila, Rafael, Pedro, Luciana, Gabriel, Isabela, Thiago,
          Priscila, Carla, Amanda, Natália, Felipe
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
    await get_or_create_user(
        session,
        email="patricia.silva@cadifetoure.com.br",
        nome="Patricia Silva",
        perfil=UserPerfil.consultor,
        telefone="+5511966664444",
    )
    await get_or_create_user(
        session,
        email="bruno.ferreira@cadifetoure.com.br",
        nome="Bruno Ferreira",
        perfil=UserPerfil.consultor,
        telefone="+5511955555000",
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
    await get_or_create_user(
        session,
        email="pedro.alves@gmail.com",
        nome="Pedro Alves",
        perfil=UserPerfil.cliente,
        telefone="+5511933333100",
        tipo_viagem=["aventura", "cultural"],
        preferencias=["deserto", "história", "pirâmides"],
        tem_passaporte=True,
    )
    await get_or_create_user(
        session,
        email="luciana.ferreira@gmail.com",
        nome="Luciana Ferreira",
        perfil=UserPerfil.cliente,
        telefone="+5521988880001",
        tipo_viagem=["lazer", "romântica"],
        preferencias=["praias", "mediterrâneo", "ilha"],
        tem_passaporte=True,
    )
    await get_or_create_user(
        session,
        email="gabriel.nogueira@gmail.com",
        nome="Gabriel Nogueira",
        perfil=UserPerfil.cliente,
        telefone="+5531977770002",
        tipo_viagem=["aventura", "natureza"],
        preferencias=["wildlife", "oceania", "mergulho"],
        tem_passaporte=True,
    )
    await get_or_create_user(
        session,
        email="isabela.rocha@gmail.com",
        nome="Isabela Rocha",
        perfil=UserPerfil.cliente,
        telefone="+5511966660003",
        tipo_viagem=["turismo", "lazer"],
        preferencias=["parques temáticos", "família", "compras"],
        tem_passaporte=True,
    )
    await get_or_create_user(
        session,
        email="thiago.martins@gmail.com",
        nome="Thiago Martins",
        perfil=UserPerfil.cliente,
        telefone="+5511955550004",
        tipo_viagem=["cultural", "histórico"],
        preferencias=["museus", "culinária italiana", "arte"],
        tem_passaporte=True,
    )
    await get_or_create_user(
        session,
        email="priscila.oliveira@gmail.com",
        nome="Priscila Oliveira",
        perfil=UserPerfil.cliente,
        telefone="+5511944440005",
        tipo_viagem=["bem-estar", "espiritual"],
        preferencias=["spa", "yoga", "retiro", "natureza"],
        tem_passaporte=True,
    )
    await get_or_create_user(
        session,
        email="carla.mendonca@gmail.com",
        nome="Carla Mendonça",
        perfil=UserPerfil.cliente,
        telefone="+5551933330006",
        tipo_viagem=["nacional", "romântica"],
        preferencias=["serras", "vinhos", "gastronomia regional"],
        tem_passaporte=False,
    )
    await get_or_create_user(
        session,
        email="amanda.ribeiro@gmail.com",
        nome="Amanda Ribeiro",
        perfil=UserPerfil.cliente,
        telefone="+5511922220007",
        tipo_viagem=["luxo", "compras"],
        preferencias=["arranha-céus", "deserto", "experiências únicas"],
        tem_passaporte=True,
    )
    await get_or_create_user(
        session,
        email="natalia.costa@gmail.com",
        nome="Natália Costa",
        perfil=UserPerfil.cliente,
        telefone="+5511911110008",
        tipo_viagem=["cultural", "gastronomia"],
        preferencias=["história", "vinho", "fado", "tapas"],
        tem_passaporte=True,
    )
    await get_or_create_user(
        session,
        email="felipe.souza@gmail.com",
        nome="Felipe Souza",
        perfil=UserPerfil.cliente,
        telefone="+5511900000009",
        tipo_viagem=["turismo", "lazer"],
        preferencias=["praia", "sol"],
        tem_passaporte=False,
    )

    await session.commit()


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
