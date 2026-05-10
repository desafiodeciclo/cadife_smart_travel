"""
Seed Demo Data Script
====================
Populates the database with initial demo data (leads, trips, etc.).

Usage (from backend/ directory):
    python scripts/seed_demo_data.py
"""
from __future__ import annotations

import asyncio
import os
import sys
import uuid
from datetime import datetime, timedelta

# Ensure app package is resolvable when run from backend/ dir
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.persistence.database import AsyncSessionLocal, engine
from app.models.lead import Lead
from app.models.user import User, UserPerfil
from app.domain.entities.enums import LeadOrigem, LeadStatus

logger = structlog.get_logger()

async def get_or_create_admin(session: AsyncSession) -> User:
    result = await session.execute(select(User).where(User.perfil == UserPerfil.admin))
    admin = result.scalar_one_or_none()
    if not admin:
        print("[WARN] No admin found. Please run scripts/seed_admin.py first.")
        sys.exit(1)
    return admin

async def seed_leads(session: AsyncSession, admin: User) -> None:
    # Check if we already have demo leads
    result = await session.execute(select(Lead).limit(1))
    if result.scalar_one_or_none():
        print("[SKIP] Demo leads already exist.")
        return

    demo_leads = [
        Lead(
            id=uuid.uuid4(),
            nome="João Silva",
            telefone="+5511999999999",
            origem=LeadOrigem.whatsapp,
            status=LeadStatus.novo,
            consultor_id=admin.id
        ),
        Lead(
            id=uuid.uuid4(),
            nome="Maria Oliveira",
            telefone="+5511888888888",
            origem=LeadOrigem.site,
            status=LeadStatus.em_atendimento,
            consultor_id=admin.id
        )
    ]
    
    session.add_all(demo_leads)
    await session.commit()
    print(f"[OK] {len(demo_leads)} Demo leads created.")

async def main() -> None:
    print("=== Cadife Smart Travel — Seed Demo Data ===")
    
    async with AsyncSessionLocal() as session:
        admin = await get_or_create_admin(session)
        await seed_leads(session, admin)

    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(main())
