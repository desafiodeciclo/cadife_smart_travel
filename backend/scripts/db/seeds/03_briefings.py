"""
03_briefings — Briefings completos e parciais para todos os 20 leads.

Completude por lead:
  Otávio Grotto    → 100% (Paris, casal, luxo)
  Camila Santos    → 96%  (Tóquio, amigos, alto)
  Isabela Rocha    → 100% (Orlando, família, alto)
  Carla Mendonça   → 96%  (Gramado, casal, médio)
  Rafael Mendes    → 92%  (Nova York, família, alto)
  Fernanda Castro  → 88%  (Lisboa/Porto, amigos, alto)
  Ana Luiza Gomes  → 88%  (Buenos Aires/Bariloche, casal, premium)
  Gabriel Nogueira → 88%  (Austrália, solo, alto)
  Natália Costa    → 96%  (Portugal + Espanha, casal, alto)
  Pedro Alves      → 80%  (Egito, casal, médio)
  Thiago Martins   → 84%  (Roma + Florença, casal, alto)
  Luciana Ferreira → 92%  (Grécia + Croácia, casal, premium)
  Priscila Oliveira→ 80%  (Bali, amigos, alto)
  Sérgio Lima      → 84%  (Cancún, casal, médio)
  Amanda Ribeiro   → 60%  (Dubai, casal, premium — parcial)
  João Silva       → parcial (Europa, solo/amigos, sem datas)
  Maria Oliveira   → parcial (Cancún, casal, sem data volta)
  Thiago/Felipe    → parcial mínimo
  Roberto/Eduardo  → parcial mínimo (leads perdidos)
"""
from __future__ import annotations

import sys
from pathlib import Path
from datetime import date

_BACKEND = Path(__file__).resolve().parents[3]
_SEEDS = Path(__file__).resolve().parent
for _p in [str(_BACKEND), str(_SEEDS)]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import OrcamentoPerfil, PerfilViagem
from shared import get_lead_by_phone, get_or_create_briefing


async def run(session: AsyncSession) -> None:
    # ── leads lookup ──────────────────────────────────────────────────────────
    otavio   = await get_lead_by_phone(session, "+5511966666666")
    camila   = await get_lead_by_phone(session, "+5511955555555")
    isabela  = await get_lead_by_phone(session, "+5511966660003")
    carla    = await get_lead_by_phone(session, "+5551933330006")
    rafael   = await get_lead_by_phone(session, "+5511944444444")
    fernanda = await get_lead_by_phone(session, "+5511877777777")
    ana_luiza= await get_lead_by_phone(session, "+5511866666666")
    gabriel  = await get_lead_by_phone(session, "+5531977770002")
    natalia  = await get_lead_by_phone(session, "+5511911110008")
    pedro    = await get_lead_by_phone(session, "+5511933333100")
    thiago   = await get_lead_by_phone(session, "+5511955550004")
    luciana  = await get_lead_by_phone(session, "+5521988880001")
    priscila = await get_lead_by_phone(session, "+5511944440005")
    sergio   = await get_lead_by_phone(session, "+5521977770011")
    amanda   = await get_lead_by_phone(session, "+5511922220007")
    joao     = await get_lead_by_phone(session, "+5511999999999")
    maria    = await get_lead_by_phone(session, "+5511888888888")
    roberto  = await get_lead_by_phone(session, "+5511833330010")
    felipe   = await get_lead_by_phone(session, "+5511900000009")
    eduardo  = await get_lead_by_phone(session, "+5511855550012")

    # ── briefings completos ───────────────────────────────────────────────────

    if otavio:
        await get_or_create_briefing(
            session,
            lead_id=otavio.id,
            destino="Paris, França",
            origem="São Paulo, Brasil",
            data_ida=date(2026, 3, 10),
            data_volta=date(2026, 3, 17),
            duracao_dias=7,
            qtd_pessoas=2,
            perfil=PerfilViagem.casal,
            tipo_viagem=["romântica", "luxo", "turismo"],
            preferencias=["monumentos", "restaurantes estrelados", "museus"],
            orcamento=OrcamentoPerfil.premium,
            tem_passaporte=True,
            observacoes="Aniversário de casamento. Preferem hotéis no coração de Paris.",
        )

    if camila:
        await get_or_create_briefing(
            session,
            lead_id=camila.id,
            destino="Tóquio, Japão",
            origem="São Paulo, Brasil",
            data_ida=date(2026, 8, 5),
            data_volta=date(2026, 8, 19),
            duracao_dias=14,
            qtd_pessoas=4,
            perfil=PerfilViagem.amigos,
            tipo_viagem=["aventura", "gastronomia"],
            preferencias=["templos", "culinária local", "lojas de anime"],
            orcamento=OrcamentoPerfil.alto,
            observacoes="Grupo de 4 amigas. Uma tem alergia a frutos do mar.",
        )

    if isabela:
        await get_or_create_briefing(
            session,
            lead_id=isabela.id,
            destino="Orlando, EUA",
            origem="São Paulo, Brasil",
            data_ida=date(2026, 7, 1),
            data_volta=date(2026, 7, 14),
            duracao_dias=13,
            qtd_pessoas=4,
            perfil=PerfilViagem.familia,
            tipo_viagem=["turismo", "lazer", "parques temáticos"],
            preferencias=["Disney World", "Universal Studios", "compras no outlet"],
            orcamento=OrcamentoPerfil.alto,
            tem_passaporte=True,
            observacoes="2 adultos e 2 filhas (10 e 14 anos). Sonho das meninas visitar a Disney. Querem combinar parques com compras.",
        )

    if carla:
        await get_or_create_briefing(
            session,
            lead_id=carla.id,
            destino="Gramado e Canela, Brasil",
            origem="Porto Alegre, Brasil",
            data_ida=date(2026, 6, 20),
            data_volta=date(2026, 6, 25),
            duracao_dias=5,
            qtd_pessoas=2,
            perfil=PerfilViagem.casal,
            tipo_viagem=["romântica", "gastronomia"],
            preferencias=["fondue", "vinhos locais", "chocolates artesanais", "natureza"],
            orcamento=OrcamentoPerfil.medio,
            tem_passaporte=False,
            observacoes="Lua de mel nacional. Querem chalé com lareira e café colonial completo.",
        )

    if rafael:
        await get_or_create_briefing(
            session,
            lead_id=rafael.id,
            destino="Nova York, EUA",
            origem="Belo Horizonte, Brasil",
            data_ida=date(2026, 7, 15),
            data_volta=date(2026, 7, 25),
            duracao_dias=10,
            qtd_pessoas=4,
            perfil=PerfilViagem.familia,
            tipo_viagem=["turismo", "compras"],
            orcamento=OrcamentoPerfil.alto,
            observacoes="2 adultos e 2 crianças (8 e 12 anos). Querem visitar a Disney e Broadway.",
        )

    if fernanda:
        await get_or_create_briefing(
            session,
            lead_id=fernanda.id,
            destino="Lisboa e Porto, Portugal",
            origem="São Paulo, Brasil",
            data_ida=date(2026, 9, 12),
            data_volta=date(2026, 9, 26),
            duracao_dias=14,
            qtd_pessoas=3,
            perfil=PerfilViagem.amigos,
            tipo_viagem=["cultural", "gastronomia"],
            preferencias=["museus", "fado ao vivo", "vinhos portugueses", "pastéis de Belém"],
            orcamento=OrcamentoPerfil.alto,
            tem_passaporte=True,
            observacoes="3 amigas comemorando 30 anos. Querem hotéis boutique históricos no centro histórico.",
        )

    if ana_luiza:
        await get_or_create_briefing(
            session,
            lead_id=ana_luiza.id,
            destino="Buenos Aires e Bariloche, Argentina",
            origem="São Paulo, Brasil",
            data_ida=date(2026, 10, 5),
            data_volta=date(2026, 10, 15),
            duracao_dias=10,
            qtd_pessoas=2,
            perfil=PerfilViagem.casal,
            tipo_viagem=["romântica", "aventura"],
            preferencias=["patagônia", "vinícolas mendocinas", "trilhas na neve", "gastronomia portenha"],
            orcamento=OrcamentoPerfil.premium,
            tem_passaporte=True,
            observacoes="Lua de mel! Querem combinar cidade cosmopolita (Buenos Aires 4 dias) com natureza selvagem (Bariloche 5 dias).",
        )

    if gabriel:
        await get_or_create_briefing(
            session,
            lead_id=gabriel.id,
            destino="Sydney e Cairns, Austrália",
            origem="Belo Horizonte, Brasil",
            data_ida=date(2026, 11, 10),
            data_volta=date(2026, 11, 28),
            duracao_dias=18,
            qtd_pessoas=2,
            perfil=PerfilViagem.amigos,
            tipo_viagem=["aventura", "natureza", "mergulho"],
            preferencias=["Grande Barreira de Coral", "ópera de Sydney", "vida selvagem", "surf"],
            orcamento=OrcamentoPerfil.alto,
            tem_passaporte=True,
            observacoes="Dois amigos aventureiros. Mergulho na Grande Barreira de Coral é prioridade máxima.",
        )

    if natalia:
        await get_or_create_briefing(
            session,
            lead_id=natalia.id,
            destino="Lisboa, Porto e Madrid",
            origem="São Paulo, Brasil",
            data_ida=date(2026, 5, 8),
            data_volta=date(2026, 5, 21),
            duracao_dias=13,
            qtd_pessoas=2,
            perfil=PerfilViagem.casal,
            tipo_viagem=["cultural", "gastronomia"],
            preferencias=["museus", "vinhos", "tapas", "flamenco", "fado", "história"],
            orcamento=OrcamentoPerfil.alto,
            tem_passaporte=True,
            observacoes="Casal de professores de história. Querem imersão cultural profunda: museus, guia local e gastronomia autêntica.",
        )

    if pedro:
        await get_or_create_briefing(
            session,
            lead_id=pedro.id,
            destino="Cairo e Luxor, Egito",
            origem="São Paulo, Brasil",
            data_ida=date(2026, 10, 18),
            data_volta=date(2026, 10, 29),
            duracao_dias=11,
            qtd_pessoas=2,
            perfil=PerfilViagem.casal,
            tipo_viagem=["cultural", "aventura", "histórico"],
            preferencias=["pirâmides de Gizé", "Vale dos Reis", "cruzeiro no Nilo", "bazar Khan el-Khalili"],
            orcamento=OrcamentoPerfil.medio,
            tem_passaporte=True,
            observacoes="Fascinados por história antiga. Querem cruzeiro no Nilo e ver as pirâmides ao amanhecer.",
        )

    if thiago:
        await get_or_create_briefing(
            session,
            lead_id=thiago.id,
            destino="Roma, Florença e Veneza, Itália",
            origem="São Paulo, Brasil",
            data_ida=date(2026, 9, 5),
            data_volta=date(2026, 9, 18),
            duracao_dias=13,
            qtd_pessoas=2,
            perfil=PerfilViagem.casal,
            tipo_viagem=["cultural", "gastronômico", "histórico"],
            preferencias=["Coliseu", "museus Vaticano", "galerias florentinas", "gôndola em Veneza", "trufa e vinho"],
            orcamento=OrcamentoPerfil.alto,
            tem_passaporte=True,
            observacoes="Casal apaixonado por arte renascentista e gastronomia italiana. Ele é professor de história da arte.",
        )

    if luciana:
        await get_or_create_briefing(
            session,
            lead_id=luciana.id,
            destino="Santorini, Mykonos e Dubrovnik",
            origem="Rio de Janeiro, Brasil",
            data_ida=date(2026, 6, 10),
            data_volta=date(2026, 6, 24),
            duracao_dias=14,
            qtd_pessoas=2,
            perfil=PerfilViagem.casal,
            tipo_viagem=["romântica", "lazer", "praia"],
            preferencias=["pôr do sol em Oia", "praias de Mykonos", "muralhas de Dubrovnik", "culinária mediterrânea"],
            orcamento=OrcamentoPerfil.premium,
            tem_passaporte=True,
            observacoes="Casal em aniversário de 5 anos de namoro. Querem uma suíte com vista para a caldera em Santorini.",
        )

    if priscila:
        await get_or_create_briefing(
            session,
            lead_id=priscila.id,
            destino="Ubud e Seminyak, Bali — Indonésia",
            origem="São Paulo, Brasil",
            data_ida=date(2026, 8, 22),
            data_volta=date(2026, 9, 3),
            duracao_dias=12,
            qtd_pessoas=4,
            perfil=PerfilViagem.amigos,
            tipo_viagem=["bem-estar", "espiritual", "natureza"],
            preferencias=["retiro de yoga", "spa balinês", "templos", "arrozais", "praia de Seminyak"],
            orcamento=OrcamentoPerfil.alto,
            tem_passaporte=True,
            observacoes="4 amigas. Querem combinar espiritualidade e relaxamento em Ubud com praias e vida noturna em Seminyak.",
        )

    if sergio:
        await get_or_create_briefing(
            session,
            lead_id=sergio.id,
            destino="Cancún e Playa del Carmen, México",
            origem="São Paulo, Brasil",
            data_ida=date(2026, 12, 18),
            data_volta=date(2026, 12, 27),
            duracao_dias=9,
            qtd_pessoas=2,
            perfil=PerfilViagem.casal,
            tipo_viagem=["praia", "all-inclusive", "lazer"],
            preferencias=["resort all-inclusive", "Chichén Itzá", "cenote", "mergulho"],
            orcamento=OrcamentoPerfil.medio,
            tem_passaporte=True,
            observacoes="Viagem de fim de ano. Preferem resort com show noturno e animação.",
        )

    # ── briefings parciais ────────────────────────────────────────────────────

    if amanda:
        await get_or_create_briefing(
            session,
            lead_id=amanda.id,
            destino="Dubai, Emirados Árabes",
            origem="São Paulo, Brasil",
            data_ida=date(2026, 11, 28),
            qtd_pessoas=2,
            perfil=PerfilViagem.casal,
            orcamento=OrcamentoPerfil.premium,
            tem_passaporte=True,
            observacoes="Quer experiência de luxo total. Ainda definindo datas exatas.",
        )

    if joao:
        await get_or_create_briefing(
            session,
            lead_id=joao.id,
            destino="Europa",
            observacoes="Ainda definindo roteiro. Interesse em Portugal ou Espanha.",
        )

    if maria:
        await get_or_create_briefing(
            session,
            lead_id=maria.id,
            destino="Cancún, México",
            data_ida=date(2026, 12, 20),
            qtd_pessoas=2,
            perfil=PerfilViagem.casal,
            orcamento=OrcamentoPerfil.medio,
        )

    if roberto:
        await get_or_create_briefing(
            session,
            lead_id=roberto.id,
            destino="Portugal",
            observacoes="Estava interessado mas perdeu o contato. Sem datas definidas.",
        )

    if felipe:
        await get_or_create_briefing(
            session,
            lead_id=felipe.id,
            destino="Nordeste do Brasil",
            observacoes="Interesse geral. Mencionou praias. Ainda em fase de pesquisa.",
        )

    if eduardo:
        await get_or_create_briefing(
            session,
            lead_id=eduardo.id,
            destino="Europa Geral",
            observacoes="Lead frio. Não respondeu ao follow-up.",
        )

    await session.commit()


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
