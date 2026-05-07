"""
Seed Leads Test Script
======================
Povoa o banco com leads fictícios para testar filtros avançados e performance.
"""
import asyncio
import os
import sys
import uuid
import random
from datetime import datetime, timedelta, timezone

if sys.platform == 'win32':
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy.ext.asyncio import create_async_engine
from app.infrastructure.persistence.database import AsyncSessionLocal
from app.infrastructure.config.settings import get_settings
from app.models.lead import Lead, LeadStatus, LeadScore
from app.models.briefing import Briefing
from app.models.interacao import Interacao
from app.models.user import User
from app.models.agendamento import Agendamento
from app.models.proposta import Proposta

from sqlalchemy.pool import NullPool
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

async def seed_leads():
    settings = get_settings()
    # Forçamos 127.0.0.1 e NullPool para máxima estabilidade no Windows
    db_url = settings.DATABASE_URL.replace("localhost", "127.0.0.1")
    engine = create_async_engine(db_url, poolclass=NullPool)
    SessionLocal = async_sessionmaker(engine, class_=AsyncSession)

    destinos = ["Fortaleza", "Natal", "Gramado", "Fernando de Noronha", "Paris", "Roma", "Disney"]
    nomes = ["Alice Silva", "Bruno Souza", "Carla Dias", "Daniel Oliveira", "Eduarda Lima"]
    
    async with SessionLocal() as session:
        print(f"🚀 Iniciando seed forçado (5 leads)...")
        for i in range(5):
            lead_id = uuid.uuid4()
            lead = Lead(
                id=lead_id,
                nome=f"{random.choice(nomes)} {i}",
                telefone=f"55119{random.randint(10000000, 99999999)}",
                status=random.choice(list(LeadStatus)),
                score=random.choice(list(LeadScore)),
                origem="whatsapp",
                criado_em=datetime.now(timezone.utc) - timedelta(days=random.randint(0, 15))
            )
            session.add(lead)
            
            briefing = Briefing(
                lead_id=lead_id,
                destino=random.choice(destinos),
                completude_pct=random.randint(20, 100)
            )
            session.add(briefing)

            await session.commit()
            print(f"✅ Lead {i+1}/5 persistido.")

    print("✅ Seed concluído!")
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(seed_leads())
