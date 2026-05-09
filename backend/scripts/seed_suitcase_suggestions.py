"""
Seed Script — Suitcase Suggestions
==================================
Populates the 'suitcase_suggestions' table with deterministic items based on destination types.
"""

import asyncio
import sys
import os

# Add parent directory to path to allow imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select
from app.infrastructure.persistence.database import AsyncSessionLocal
from app.infrastructure.persistence.models.suitcase_model import SuitcaseSuggestionModel
from app.domain.entities.enums import SuitcaseCategory, DestinationType

SUGGESTIONS = [
    # PRAIA
    {
        "tipo_destino": DestinationType.praia,
        "categoria": SuitcaseCategory.roupas,
        "nome": "Biquíni / Sunga",
        "quantidade_sugerida": 2,
    },
    {
        "tipo_destino": DestinationType.praia,
        "categoria": SuitcaseCategory.roupas,
        "nome": "Chinelo",
        "quantidade_sugerida": 1,
    },
    {
        "tipo_destino": DestinationType.praia,
        "categoria": SuitcaseCategory.higiene,
        "nome": "Protetor Solar",
        "quantidade_sugerida": 1,
    },
    {
        "tipo_destino": DestinationType.praia,
        "categoria": SuitcaseCategory.acessorios,
        "nome": "Óculos de Sol",
        "quantidade_sugerida": 1,
    },
    {
        "tipo_destino": DestinationType.praia,
        "categoria": SuitcaseCategory.acessorios,
        "nome": "Toalha de Praia",
        "quantidade_sugerida": 1,
    },

    # FRIO
    {
        "tipo_destino": DestinationType.frio,
        "categoria": SuitcaseCategory.roupas,
        "nome": "Casaco Pesado",
        "quantidade_sugerida": 1,
    },
    {
        "tipo_destino": DestinationType.frio,
        "categoria": SuitcaseCategory.roupas,
        "nome": "Segunda Pele (Térmica)",
        "quantidade_sugerida": 2,
    },
    {
        "tipo_destino": DestinationType.frio,
        "categoria": SuitcaseCategory.acessorios,
        "nome": "Luvas e Cachecol",
        "quantidade_sugerida": 1,
    },
    {
        "tipo_destino": DestinationType.frio,
        "categoria": SuitcaseCategory.higiene,
        "nome": "Hidratante Labial",
        "quantidade_sugerida": 1,
    },

    # AVENTURA
    {
        "tipo_destino": DestinationType.aventura,
        "categoria": SuitcaseCategory.roupas,
        "nome": "Bota de Trilha",
        "quantidade_sugerida": 1,
    },
    {
        "tipo_destino": DestinationType.aventura,
        "categoria": SuitcaseCategory.acessorios,
        "nome": "Mochila de Ataque",
        "quantidade_sugerida": 1,
    },
    {
        "tipo_destino": DestinationType.aventura,
        "categoria": SuitcaseCategory.saude,
        "nome": "Repelente",
        "quantidade_sugerida": 1,
    },
    {
        "tipo_destino": DestinationType.aventura,
        "categoria": SuitcaseCategory.acessorios,
        "nome": "Lanterna de Cabeça",
        "quantidade_sugerida": 1,
    },

    # URBANO
    {
        "tipo_destino": DestinationType.urbano,
        "categoria": SuitcaseCategory.roupas,
        "nome": "Tênis Confortável",
        "quantidade_sugerida": 1,
    },
    {
        "tipo_destino": DestinationType.urbano,
        "categoria": SuitcaseCategory.eletronicos,
        "nome": "Power Bank",
        "quantidade_sugerida": 1,
    },
    {
        "tipo_destino": DestinationType.urbano,
        "categoria": SuitcaseCategory.documentos,
        "nome": "Cartão de Transporte Público",
        "quantidade_sugerida": 1,
    },
]

async def seed():
    print("Starting suitcase suggestions seed...")
    async with AsyncSessionLocal() as session:
        for data in SUGGESTIONS:
            # Check if exists
            stmt = select(SuitcaseSuggestionModel).where(
                SuitcaseSuggestionModel.tipo_destino == data["tipo_destino"].value,
                SuitcaseSuggestionModel.nome == data["nome"]
            )
            result = await session.execute(stmt)
            if not result.scalar_one_or_none():
                suggestion = SuitcaseSuggestionModel(
                    tipo_destino=data["tipo_destino"].value,
                    categoria=data["categoria"].value,
                    nome=data["nome"],
                    quantidade_sugerida=data["quantidade_sugerida"]
                )
                session.add(suggestion)
                print(f"Added suggestion: {data['nome']} for {data['tipo_destino'].value}")
        
        await session.commit()
    print("Seed complete!")

if __name__ == "__main__":
    asyncio.run(seed())
