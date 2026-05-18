"""
00_admin — Cria o admin de demonstração se não existir nenhum.

Para produção (senha customizada) use: python scripts/seed_admin.py
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

from app.infrastructure.security.jwt import hash_password
from app.domain.entities.enums import UserPerfil
from app.models.user import User
from shared import ADMIN_EMAIL, DEMO_PASSWORD


async def run(session: AsyncSession) -> None:
    result = await session.execute(
        select(User).where(User.perfil == UserPerfil.admin).limit(1)
    )
    if result.scalar_one_or_none():
        print("  [SKIP] Admin já existe")
        return

    admin = User(
        email=ADMIN_EMAIL,
        nome="Administrador",
        hashed_password=hash_password(DEMO_PASSWORD),
        perfil=UserPerfil.admin,
        is_active=True,
    )
    session.add(admin)
    await session.commit()
    print(f"  [NEW]  Admin {ADMIN_EMAIL} (senha: {DEMO_PASSWORD})")


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
