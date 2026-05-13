
import asyncio
import uuid
import os
from dotenv import load_dotenv

# FORÇAR CARREGAMENTO DO .ENV
load_dotenv("d:/Users/jackl/ALPHA EDTCH/Desafio de ciclo/cadife_smart_travel/backend/.env")

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.infrastructure.config.settings import get_settings
from app.domain.entities.enums import LeadStatus
from sqlalchemy.pool import NullPool

# IMPORTAR TODOS OS MODELOS PARA SATISFAZER O REGISTRY
import app.infrastructure.persistence.models.user_model
import app.infrastructure.persistence.models.lead_model
import app.infrastructure.persistence.models.briefing_model
import app.infrastructure.persistence.models.offer_model
import app.infrastructure.persistence.models.itinerary_model
import app.infrastructure.persistence.models.travel_model
import app.infrastructure.persistence.models.agendamento_model
import app.infrastructure.persistence.models.proposta_model

from app.infrastructure.persistence.models.lead_model import LeadModel

async def seed_leads():
    settings = get_settings()
    # Verificar se a chave foi carregada
    if not settings.ENCRYPTION_KEY:
        print("ERRO: ENCRYPTION_KEY ainda não detectada!")
        return

    engine = create_async_engine(settings.DATABASE_URL, poolclass=NullPool)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        leads = [
            LeadModel(id=uuid.uuid4(), nome="Lead Novo 1", telefone="+5511999991111", status=LeadStatus.novo.value),
            LeadModel(id=uuid.uuid4(), nome="Lead Qualificado 1", telefone="+5511999992222", status=LeadStatus.qualificado.value),
            LeadModel(id=uuid.uuid4(), nome="Lead Qualificado 2", telefone="+5511999993333", status=LeadStatus.qualificado.value),
            LeadModel(id=uuid.uuid4(), nome="Lead Atendimento 1", telefone="+5511999994444", status=LeadStatus.em_atendimento.value),
        ]
        session.add_all(leads)
        await session.commit()
        print(f"LEADS_CRIADOS:{len(leads)}")
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(seed_leads())
