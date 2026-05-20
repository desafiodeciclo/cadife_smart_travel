"""
07_suitcase — Itens da mala por cliente + 120 sugestões estáticas por tipo de destino.

Clientes com itens: Otávio (Paris), Camila (Tóquio), Rafael (Nova York),
                    Isabela (Orlando), Carla (Gramado), Natália (Portugal+Espanha)
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

from app.domain.entities.enums import DestinationType, SuitcaseCategory
from app.infrastructure.persistence.models.suitcase_model import (
    SuitcaseItemModel,
    SuitcaseSuggestionModel,
)
from shared import get_lead_by_phone, get_user_by_email

# ── itens por cliente ──────────────────────────────────────────────────────────
# (categoria, nome, quantidade, empacotado)

_PARIS = [
    (SuitcaseCategory.documentos,  "Passaporte",                      2, True),
    (SuitcaseCategory.documentos,  "Visto Schengen",                  2, True),
    (SuitcaseCategory.documentos,  "Seguro Viagem Internacional",     1, True),
    (SuitcaseCategory.documentos,  "Cartão de Crédito Internacional", 2, True),
    (SuitcaseCategory.documentos,  "Vouchers Impressos",              1, True),
    (SuitcaseCategory.roupas,      "Casaco de Lã",                    2, True),
    (SuitcaseCategory.roupas,      "Suéter de Inverno",               3, True),
    (SuitcaseCategory.roupas,      "Calça Jeans",                     2, True),
    (SuitcaseCategory.roupas,      "Vestido Elegante",                1, True),
    (SuitcaseCategory.roupas,      "Trench Coat Impermeável",         1, True),
    (SuitcaseCategory.roupas,      "Sapato Social",                   1, True),
    (SuitcaseCategory.higiene,     "Hidratante Facial",               1, True),
    (SuitcaseCategory.higiene,     "Protetor Labial",                 2, True),
    (SuitcaseCategory.higiene,     "Perfume",                         1, True),
    (SuitcaseCategory.eletronicos, "Adaptador de Tomada Universal",   1, True),
    (SuitcaseCategory.eletronicos, "Câmera Fotográfica",              1, True),
    (SuitcaseCategory.eletronicos, "Carregador Portátil",             1, True),
    (SuitcaseCategory.acessorios,  "Guarda-Chuva Compacto",          2, False),
    (SuitcaseCategory.acessorios,  "Cachecol de Lã",                  2, True),
]

_TOQUIO = [
    (SuitcaseCategory.documentos,  "Passaporte",                            4, False),
    (SuitcaseCategory.documentos,  "Seguro Viagem",                         4, False),
    (SuitcaseCategory.documentos,  "JR Pass",                               4, False),
    (SuitcaseCategory.roupas,      "Camisetas Casuais",                     8, False),
    (SuitcaseCategory.roupas,      "Calças Jeans",                          4, False),
    (SuitcaseCategory.roupas,      "Tênis Confortável",                     4, False),
    (SuitcaseCategory.roupas,      "Camiseta de Manga Longa",               4, False),
    (SuitcaseCategory.higiene,     "Protetor Solar FPS 50+",                4, False),
    (SuitcaseCategory.higiene,     "Desinfetante para Mãos",                4, False),
    (SuitcaseCategory.eletronicos, "Adaptador Tomada Japonesa (tipo A)",    4, False),
    (SuitcaseCategory.eletronicos, "Carregador Portátil",                   4, False),
    (SuitcaseCategory.saude,       "Antialérgico (sem frutos do mar)",      1, False),
    (SuitcaseCategory.acessorios,  "Sacola Reutilizável",                   4, False),
]

_NOVA_YORK = [
    (SuitcaseCategory.documentos,  "Passaporte",                     4, False),
    (SuitcaseCategory.documentos,  "ESTA / Visto Americano",         4, False),
    (SuitcaseCategory.documentos,  "Seguro Viagem",                  1, False),
    (SuitcaseCategory.roupas,      "Casaco Leve",                    4, False),
    (SuitcaseCategory.roupas,      "Tênis Confortável",              4, False),
    (SuitcaseCategory.roupas,      "Camisetas Casuais",              8, False),
    (SuitcaseCategory.eletronicos, "Adaptador de Tomada EUA",        1, False),
    (SuitcaseCategory.eletronicos, "Carregador Portátil",            1, False),
    (SuitcaseCategory.acessorios,  "Mochila Pequena",                2, False),
]

_ORLANDO = [
    (SuitcaseCategory.documentos,  "Passaporte",                     4, True),
    (SuitcaseCategory.documentos,  "ESTA / Visto Americano",         4, True),
    (SuitcaseCategory.documentos,  "Seguro Viagem",                  1, True),
    (SuitcaseCategory.documentos,  "Park Hopper Pass (impresso)",    4, True),
    (SuitcaseCategory.roupas,      "Camiseta Casual",                16, False),
    (SuitcaseCategory.roupas,      "Short / Bermuda",                8, False),
    (SuitcaseCategory.roupas,      "Tênis Confortável para Parques", 4, False),
    (SuitcaseCategory.roupas,      "Blusa Leve (para ar condicionado)", 4, False),
    (SuitcaseCategory.higiene,     "Protetor Solar FPS 70+",         4, True),
    (SuitcaseCategory.higiene,     "Repelente",                      2, True),
    (SuitcaseCategory.eletronicos, "Adaptador de Tomada EUA",        1, True),
    (SuitcaseCategory.eletronicos, "Carregador Portátil",            2, True),
    (SuitcaseCategory.eletronicos, "Câmera Fotográfica",             1, True),
    (SuitcaseCategory.acessorios,  "Mochila Pequena para Parques",   2, False),
    (SuitcaseCategory.acessorios,  "Garrafa Térmica",                2, False),
    (SuitcaseCategory.saude,       "Protetor Solar Labial",          4, True),
    (SuitcaseCategory.saude,       "Hidratante Corporal",            2, True),
]

_GRAMADO = [
    (SuitcaseCategory.documentos,  "RG ou CNH",                     2, True),
    (SuitcaseCategory.documentos,  "Cartão de Crédito",             2, True),
    (SuitcaseCategory.roupas,      "Casaco de Inverno",             2, True),
    (SuitcaseCategory.roupas,      "Suéter de Lã",                  3, True),
    (SuitcaseCategory.roupas,      "Calça Jeans",                   2, True),
    (SuitcaseCategory.roupas,      "Roupa Íntima Térmica",          2, True),
    (SuitcaseCategory.roupas,      "Meias Grossas",                 4, True),
    (SuitcaseCategory.roupas,      "Bota de Couro",                 1, True),
    (SuitcaseCategory.roupas,      "Pijama Quentinho",              2, True),
    (SuitcaseCategory.higiene,     "Hidratante Corporal Intensivo", 1, True),
    (SuitcaseCategory.higiene,     "Protetor Labial",               2, True),
    (SuitcaseCategory.eletronicos, "Carregador Portátil",           1, True),
    (SuitcaseCategory.acessorios,  "Cachecol",                      2, True),
    (SuitcaseCategory.acessorios,  "Luvas",                         2, True),
    (SuitcaseCategory.acessorios,  "Touca",                         2, True),
]

_PORTUGAL_ESPANHA = [
    (SuitcaseCategory.documentos,  "Passaporte",                     2, True),
    (SuitcaseCategory.documentos,  "Seguro Viagem",                  1, True),
    (SuitcaseCategory.documentos,  "Cartão de Crédito Internacional",2, True),
    (SuitcaseCategory.documentos,  "Reservas de hotel impressas",    1, True),
    (SuitcaseCategory.roupas,      "Calça Jeans",                    3, True),
    (SuitcaseCategory.roupas,      "Camisa Social",                  4, True),
    (SuitcaseCategory.roupas,      "Camiseta Casual",                6, True),
    (SuitcaseCategory.roupas,      "Tênis Confortável para Caminhada",1, True),
    (SuitcaseCategory.roupas,      "Sapato Casual",                  1, True),
    (SuitcaseCategory.roupas,      "Casaco Leve",                    2, True),
    (SuitcaseCategory.higiene,     "Protetor Solar FPS 50",          1, True),
    (SuitcaseCategory.eletronicos, "Adaptador de Tomada Universal",  1, True),
    (SuitcaseCategory.eletronicos, "Câmera Fotográfica",             1, True),
    (SuitcaseCategory.eletronicos, "Carregador Portátil",            1, True),
    (SuitcaseCategory.acessorios,  "Guarda-Chuva Compacto",          1, True),
    (SuitcaseCategory.acessorios,  "Mochila Pequena",                1, True),
]

# ── sugestões estáticas expandidas ────────────────────────────────────────────
# (tipo_destino, categoria, nome, quantidade_sugerida, descricao)

_SUGGESTIONS = [
    # PRAIA (20 itens)
    (DestinationType.praia, SuitcaseCategory.documentos,  "Passaporte",                      1, "Documento essencial para viagens internacionais"),
    (DestinationType.praia, SuitcaseCategory.documentos,  "Seguro Viagem",                   1, "Cobertura médica e de bagagem"),
    (DestinationType.praia, SuitcaseCategory.documentos,  "Cartão de Crédito Internacional", 1, "Para compras e emergências"),
    (DestinationType.praia, SuitcaseCategory.roupas,      "Biquíni ou Sunga",                3, "Leve pelo menos 3 para alternar"),
    (DestinationType.praia, SuitcaseCategory.roupas,      "Camiseta Leve",                   5, "Para o dia a dia"),
    (DestinationType.praia, SuitcaseCategory.roupas,      "Short",                           3, None),
    (DestinationType.praia, SuitcaseCategory.roupas,      "Vestido Casual",                  2, "Para jantar e passeios"),
    (DestinationType.praia, SuitcaseCategory.roupas,      "Saída de Praia",                  2, None),
    (DestinationType.praia, SuitcaseCategory.roupas,      "Sandália de Praia",               1, None),
    (DestinationType.praia, SuitcaseCategory.higiene,     "Protetor Solar FPS 50+",          2, "Reaplicar a cada 2h na praia"),
    (DestinationType.praia, SuitcaseCategory.higiene,     "Repelente",                       1, "Para atividades ao ar livre à noite"),
    (DestinationType.praia, SuitcaseCategory.higiene,     "Pós-Sol Hidratante",              1, None),
    (DestinationType.praia, SuitcaseCategory.higiene,     "Shampoo e Condicionador",         1, None),
    (DestinationType.praia, SuitcaseCategory.acessorios,  "Óculos de Sol",                   1, "Proteção UV obrigatória"),
    (DestinationType.praia, SuitcaseCategory.acessorios,  "Chapéu ou Boné",                  1, None),
    (DestinationType.praia, SuitcaseCategory.acessorios,  "Bolsa de Praia Impermeável",      1, None),
    (DestinationType.praia, SuitcaseCategory.eletronicos, "Câmera à Prova d'Água",           1, "Para fotos incríveis na água"),
    (DestinationType.praia, SuitcaseCategory.eletronicos, "Carregador Portátil",             1, None),
    (DestinationType.praia, SuitcaseCategory.eletronicos, "Fone de Ouvido Bluetooth",        1, None),
    (DestinationType.praia, SuitcaseCategory.saude,       "Antialérgico",                    1, "Para reações a frutos do mar ou insetos"),
    # FRIO (19 itens)
    (DestinationType.frio, SuitcaseCategory.documentos,  "Passaporte",                       1, None),
    (DestinationType.frio, SuitcaseCategory.documentos,  "Seguro Viagem",                    1, "Inclua cobertura para esportes de neve se necessário"),
    (DestinationType.frio, SuitcaseCategory.documentos,  "Cartão de Crédito Internacional",  1, None),
    (DestinationType.frio, SuitcaseCategory.roupas,      "Casaco de Inverno Impermeável",    1, "Com capuz, impermeável"),
    (DestinationType.frio, SuitcaseCategory.roupas,      "Luvas Térmicas",                   1, "Par impermeável"),
    (DestinationType.frio, SuitcaseCategory.roupas,      "Cachecol de Lã",                   1, None),
    (DestinationType.frio, SuitcaseCategory.roupas,      "Touca",                            1, None),
    (DestinationType.frio, SuitcaseCategory.roupas,      "Meias Térmicas",                   5, None),
    (DestinationType.frio, SuitcaseCategory.roupas,      "Suéter de Lã",                     3, None),
    (DestinationType.frio, SuitcaseCategory.roupas,      "Calça Jeans Grossa",               2, None),
    (DestinationType.frio, SuitcaseCategory.roupas,      "Roupa Térmica de Base",            2, "Para baixo do casaco"),
    (DestinationType.frio, SuitcaseCategory.roupas,      "Bota Impermeável",                 1, "Par para neve ou chuva"),
    (DestinationType.frio, SuitcaseCategory.higiene,     "Hidratante Corporal Intensivo",    1, "Para o ar seco do frio"),
    (DestinationType.frio, SuitcaseCategory.higiene,     "Protetor Labial",                  2, "O frio reseca os lábios"),
    (DestinationType.frio, SuitcaseCategory.higiene,     "Creme para Mãos",                  1, None),
    (DestinationType.frio, SuitcaseCategory.eletronicos, "Adaptador de Tomada Universal",    1, None),
    (DestinationType.frio, SuitcaseCategory.eletronicos, "Carregador Portátil",              1, "Baterias duram menos no frio"),
    (DestinationType.frio, SuitcaseCategory.saude,       "Vitamina C",                       1, "Para fortalecer a imunidade"),
    (DestinationType.frio, SuitcaseCategory.saude,       "Descongestionante Nasal",          1, "Para o ar frio e seco"),
    # URBANO (20 itens)
    (DestinationType.urbano, SuitcaseCategory.documentos,  "Passaporte",                     1, None),
    (DestinationType.urbano, SuitcaseCategory.documentos,  "Visto (se necessário)",          1, "Verifique a necessidade para o país destino"),
    (DestinationType.urbano, SuitcaseCategory.documentos,  "Seguro Viagem",                  1, None),
    (DestinationType.urbano, SuitcaseCategory.documentos,  "Cartão de Crédito Internacional",1, None),
    (DestinationType.urbano, SuitcaseCategory.roupas,      "Calça Social ou Jeans",          2, None),
    (DestinationType.urbano, SuitcaseCategory.roupas,      "Blazer Casual",                  1, "Versátil para diferentes ocasiões"),
    (DestinationType.urbano, SuitcaseCategory.roupas,      "Camisa Social",                  3, None),
    (DestinationType.urbano, SuitcaseCategory.roupas,      "Camiseta Casual",                4, None),
    (DestinationType.urbano, SuitcaseCategory.roupas,      "Tênis Confortável",              1, "Para longas caminhadas"),
    (DestinationType.urbano, SuitcaseCategory.roupas,      "Sapato Casual",                  1, None),
    (DestinationType.urbano, SuitcaseCategory.higiene,     "Protetor Solar FPS 30",          1, "Para dias ao ar livre"),
    (DestinationType.urbano, SuitcaseCategory.higiene,     "Kit Higiene Básico",             1, "Escova, pasta, desodorante"),
    (DestinationType.urbano, SuitcaseCategory.eletronicos, "Adaptador de Tomada",            1, "Verifique o padrão do país"),
    (DestinationType.urbano, SuitcaseCategory.eletronicos, "Carregador Portátil",            1, None),
    (DestinationType.urbano, SuitcaseCategory.eletronicos, "Câmera Fotográfica",             1, None),
    (DestinationType.urbano, SuitcaseCategory.acessorios,  "Mochila Pequena",                1, "Para passeios diários"),
    (DestinationType.urbano, SuitcaseCategory.acessorios,  "Guarda-Chuva Compacto",          1, "Para chuvas inesperadas"),
    (DestinationType.urbano, SuitcaseCategory.acessorios,  "Cinto",                          1, None),
    (DestinationType.urbano, SuitcaseCategory.saude,       "Analgésico",                     1, "Para dores de cabeça ou cansaço"),
    (DestinationType.urbano, SuitcaseCategory.saude,       "Antidiarreico",                  1, "Especialmente útil em destinos exóticos"),
    # AVENTURA (22 itens)
    (DestinationType.aventura, SuitcaseCategory.documentos,  "Passaporte",                   1, None),
    (DestinationType.aventura, SuitcaseCategory.documentos,  "Seguro de Aventura",           1, "Cobertura para esportes radicais"),
    (DestinationType.aventura, SuitcaseCategory.documentos,  "Cartão de Vacinação",          1, "Verifique vacinas necessárias para o destino"),
    (DestinationType.aventura, SuitcaseCategory.documentos,  "Comprovante de Vacina Febre Amarela", 1, "Obrigatório em muitos países tropicais"),
    (DestinationType.aventura, SuitcaseCategory.roupas,      "Calça de Trekking",            2, "Resistente e de secagem rápida"),
    (DestinationType.aventura, SuitcaseCategory.roupas,      "Camisa Manga Longa UV",        3, "Proteção solar e contra insetos"),
    (DestinationType.aventura, SuitcaseCategory.roupas,      "Boné ou Chapéu",               1, "Para o sol intenso"),
    (DestinationType.aventura, SuitcaseCategory.roupas,      "Bota de Trilha",               1, "Par com suporte ao tornozelo"),
    (DestinationType.aventura, SuitcaseCategory.roupas,      "Meia Cano Alto",               3, "Para usar com botas"),
    (DestinationType.aventura, SuitcaseCategory.roupas,      "Capa de Chuva Leve",           1, None),
    (DestinationType.aventura, SuitcaseCategory.saude,       "Kit Primeiros Socorros",       1, "Band-aid, antisséptico, analgésico"),
    (DestinationType.aventura, SuitcaseCategory.saude,       "Repelente com DEET",           1, "Alta concentração para áreas de risco"),
    (DestinationType.aventura, SuitcaseCategory.saude,       "Antialérgico",                 1, None),
    (DestinationType.aventura, SuitcaseCategory.saude,       "Antiácido",                    1, None),
    (DestinationType.aventura, SuitcaseCategory.saude,       "Soro de Reidratação Oral",     2, "Para dias de trekking intenso"),
    (DestinationType.aventura, SuitcaseCategory.eletronicos, "Lanterna de Cabeça",           1, "Deixa as mãos livres"),
    (DestinationType.aventura, SuitcaseCategory.eletronicos, "Carregador Solar",             1, "Para áreas remotas sem energia"),
    (DestinationType.aventura, SuitcaseCategory.eletronicos, "Carregador Portátil",          1, None),
    (DestinationType.aventura, SuitcaseCategory.eletronicos, "GPS ou App Offline",           1, "Fundamental em trilhas sem internet"),
    (DestinationType.aventura, SuitcaseCategory.acessorios,  "Mochila 40L",                  1, "Para trilhas e acampamentos"),
    (DestinationType.aventura, SuitcaseCategory.acessorios,  "Cantil ou Garrafa Térmica",    1, "Hidratação constante"),
    (DestinationType.aventura, SuitcaseCategory.acessorios,  "Bastão de Trekking",           2, "Par para maior estabilidade"),
]


async def _seed_items(session, lead, user, items):
    exists = await session.execute(
        select(SuitcaseItemModel).where(SuitcaseItemModel.lead_id == lead.id).limit(1)
    )
    if exists.scalar_one_or_none():
        print(f"  [SKIP] Suitcase items lead {lead.id}")
        return
    for categoria, nome, quantidade, empacotado in items:
        session.add(SuitcaseItemModel(
            lead_id=lead.id,
            user_id=user.id,
            categoria=categoria.value,
            nome=nome,
            quantidade=quantidade,
            empacotado=empacotado,
        ))
    print(f"  [NEW]  {len(items)} itens → lead {lead.id}")


async def run(session: AsyncSession) -> None:
    otavio_lead   = await get_lead_by_phone(session, "+5511966666666")
    camila_lead   = await get_lead_by_phone(session, "+5511955555555")
    rafael_lead   = await get_lead_by_phone(session, "+5511944444444")
    isabela_lead  = await get_lead_by_phone(session, "+5511966660003")
    carla_lead    = await get_lead_by_phone(session, "+5551933330006")
    natalia_lead  = await get_lead_by_phone(session, "+5511911110008")

    otavio_user  = await get_user_by_email(session, "otavio.grotto@gmail.com")
    camila_user  = await get_user_by_email(session, "camila.santos@gmail.com")
    rafael_user  = await get_user_by_email(session, "rafael.mendes@gmail.com")
    isabela_user = await get_user_by_email(session, "isabela.rocha@gmail.com")
    carla_user   = await get_user_by_email(session, "carla.mendonca@gmail.com")
    natalia_user = await get_user_by_email(session, "natalia.costa@gmail.com")

    if otavio_lead  and otavio_user:  await _seed_items(session, otavio_lead,  otavio_user,  _PARIS)
    if camila_lead  and camila_user:  await _seed_items(session, camila_lead,  camila_user,  _TOQUIO)
    if rafael_lead  and rafael_user:  await _seed_items(session, rafael_lead,  rafael_user,  _NOVA_YORK)
    if isabela_lead and isabela_user: await _seed_items(session, isabela_lead, isabela_user, _ORLANDO)
    if carla_lead   and carla_user:   await _seed_items(session, carla_lead,   carla_user,   _GRAMADO)
    if natalia_lead and natalia_user: await _seed_items(session, natalia_lead, natalia_user, _PORTUGAL_ESPANHA)

    await session.commit()

    # sugestões estáticas
    exists = await session.execute(select(SuitcaseSuggestionModel).limit(1))
    if exists.scalar_one_or_none():
        print("  [SKIP] Suitcase suggestions")
    else:
        for tipo_destino, categoria, nome, quantidade, descricao in _SUGGESTIONS:
            session.add(SuitcaseSuggestionModel(
                tipo_destino=tipo_destino.value,
                categoria=categoria.value,
                nome=nome,
                quantidade_sugerida=quantidade,
                descricao=descricao,
            ))
        await session.commit()
        print(f"  [NEW]  {len(_SUGGESTIONS)} suitcase suggestions")


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
