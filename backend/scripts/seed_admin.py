"""
Seed Admin Script
=================
Creates the initial admin user so the Flutter app can perform its first login.

Usage (from backend/ directory):
    python scripts/seed_admin.py

Environment: reads DATABASE_URL from .env (or environment variables).
"""
from __future__ import annotations

import asyncio
import getpass
import os
import sys

# Ensure app package is resolvable when run from backend/ dir
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.infrastructure.config.settings import get_settings
from app.infrastructure.security.jwt import hash_password
from app.models.user import User, UserPerfil

logger = structlog.get_logger()


async def seed_admin(session: AsyncSession, email: str, nome: str, password: str) -> None:
    result = await session.execute(select(User).where(User.email == email))
    existing = result.scalar_one_or_none()

    if existing:
        print(f"[SKIP] Admin '{email}' already exists (id={existing.id}).")
        return

    hashed = hash_password(password)
    admin = User(
        email=email,
        nome=nome,
        hashed_password=hashed,
        perfil=UserPerfil.admin,
        is_active=True,
    )
    session.add(admin)
    await session.commit()
    await session.refresh(admin)
    print(f"[OK] Admin created: email={email}, id={admin.id}")


async def main() -> None:
    settings = get_settings()

    print("=== Cadife Smart Travel — Seed Admin ===")
    email = input("Admin e-mail [admin@cadifetoure.com.br]: ").strip() or "admin@cadifetoure.com.br"
    nome = input("Admin name [Administrador]: ").strip() or "Administrador"
    password = getpass.getpass("Password: ")
    if len(password) < 8:
        print("[ERROR] Password must be at least 8 characters.")
        sys.exit(1)

    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    SessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with SessionLocal() as session:
        await seed_admin(session, email, nome, password)

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
