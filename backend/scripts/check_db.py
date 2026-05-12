import asyncio
import argparse
from sqlalchemy import select, func
from app.infrastructure.persistence.database import AsyncSessionLocal

# Importar todos os modelos para o SQLAlchemy resolver as relações
from app.models.lead import Lead
from app.models.user import User
from app.models.briefing import Briefing
from app.models.proposta import Proposta
from app.models.interacao import Interacao
from app.models.agendamento import Agendamento

async def check(table: str):
    async with AsyncSessionLocal() as session:
        if table == "users":
            result = await session.execute(select(User))
            users = result.scalars().all()
            print(f"\n👥 Lista de Usuários no Banco:")
            print(f"{'ID':<40} | {'Perfil':<10} | {'Email'}")
            print("-" * 80)
            for u in users:
                print(f"{str(u.id):<40} | {u.perfil:<10} | {u.email}")
        else:
            result = await session.execute(select(func.count(Lead.id)))
            count = result.scalar()
            print(f"\n📊 Total de leads: {count}")
            if count > 0:
                last = await session.execute(select(Lead).order_by(Lead.criado_em.desc()).limit(1))
                lead = last.scalar()
                print(f"Último lead: {lead.nome} ({lead.status})")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--table", default="leads")
    args = parser.parse_args()
    asyncio.run(check(args.table))
