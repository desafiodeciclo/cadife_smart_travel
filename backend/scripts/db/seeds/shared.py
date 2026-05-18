"""
Shared helpers and constants for all seed modules.
"""
from __future__ import annotations

import asyncio
import sys
import uuid
from pathlib import Path

# ── path setup (used when any seed is run standalone) ─────────────────────────
_BACKEND = Path(__file__).resolve().parents[3]  # seeds/ → db/ → scripts/ → backend/
_SEEDS = Path(__file__).resolve().parent
for _p in [str(_BACKEND), str(_SEEDS)]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.security.jwt import hash_password
from app.infrastructure.security.pii_encryption import hmac_hash
from app.models.briefing import Briefing, calculate_completude
from app.models.lead import Lead
from app.domain.entities.enums import UserPerfil
from app.models.user import User

DEMO_PASSWORD = "Cadife@2026"
ADMIN_EMAIL = "admin@cadifetoure.com.br"


# ── lookup helpers ─────────────────────────────────────────────────────────────


async def get_admin(session: AsyncSession) -> User:
    result = await session.execute(
        select(User).where(User.perfil == UserPerfil.admin).limit(1)
    )
    admin = result.scalar_one_or_none()
    if not admin:
        print("[ERROR] Nenhum admin encontrado. Execute seed_admin.py primeiro.")
        sys.exit(1)
    return admin


async def get_user_by_email(session: AsyncSession, email: str) -> User | None:
    result = await session.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()


async def get_lead_by_phone(session: AsyncSession, telefone: str) -> Lead | None:
    result = await session.execute(
        select(Lead).where(Lead.telefone_hash == hmac_hash(telefone))
    )
    return result.scalar_one_or_none()


# ── upsert helpers ─────────────────────────────────────────────────────────────


async def get_or_create_user(
    session: AsyncSession,
    email: str,
    nome: str,
    perfil: UserPerfil,
    telefone: str | None = None,
    **kwargs,
) -> User:
    existing = await get_user_by_email(session, email)
    if existing:
        print(f"  [SKIP] User {email}")
        return existing
    user = User(
        email=email,
        nome=nome,
        hashed_password=hash_password(DEMO_PASSWORD),
        perfil=perfil,
        telefone=telefone,
        is_active=True,
        **kwargs,
    )
    session.add(user)
    await session.flush()
    print(f"  [NEW]  User {email} ({perfil.value})")
    return user


async def get_or_create_lead(
    session: AsyncSession, telefone: str, **kwargs
) -> Lead:
    existing = await get_lead_by_phone(session, telefone)
    if existing:
        print(f"  [SKIP] Lead {kwargs.get('nome', telefone)}")
        return existing
    lead = Lead(telefone=telefone, telefone_hash=hmac_hash(telefone), **kwargs)
    session.add(lead)
    await session.flush()
    print(f"  [NEW]  Lead {kwargs.get('nome', telefone)}")
    return lead


async def get_or_create_briefing(
    session: AsyncSession, lead_id: uuid.UUID, **fields
) -> Briefing | None:
    result = await session.execute(
        select(Briefing).where(Briefing.lead_id == lead_id)
    )
    if result.scalar_one_or_none():
        print(f"  [SKIP] Briefing lead {lead_id}")
        return None
    completude = calculate_completude(fields)
    briefing = Briefing(lead_id=lead_id, completude_pct=completude, **fields)
    session.add(briefing)
    await session.flush()
    print(f"  [NEW]  Briefing {completude}% completude → lead {lead_id}")
    return briefing


# ── standalone runner (used by each seed's __main__) ──────────────────────────


def run_standalone(fn) -> None:
    """Wraps an async `run(session)` function for direct script execution."""
    async def _main():
        from app.infrastructure.persistence.database import AsyncSessionLocal, engine
        async with AsyncSessionLocal() as session:
            await fn(session)
        await engine.dispose()

    asyncio.run(_main())
