"""
Seed Profile Data Script
========================
Populates database with rich demo data for client profile screens.

Creates consultores, client users (with full preferences), leads at every
lifecycle stage, briefings, agendamentos, propostas, interações, suitcase
items, and suitcase suggestions.

Usage (from backend/ directory):
    python scripts/seed_profile_data.py

Requires: seed_admin.py must be run first.
Demo password for all new users: Cadife@2026
"""
from __future__ import annotations

import asyncio
import os
import sys
import uuid
from datetime import date, time

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.persistence.database import AsyncSessionLocal, engine
from app.infrastructure.security.jwt import hash_password
from app.infrastructure.security.pii_encryption import hmac_hash
from app.models.agendamento import Agendamento
from app.models.briefing import Briefing, calculate_completude
from app.models.interacao import Interacao
from app.models.lead import Lead
from app.models.proposta import Proposta
from app.models.user import User, UserPerfil
from app.infrastructure.persistence.models.suitcase_model import (
    SuitcaseItemModel,
    SuitcaseSuggestionModel,
)
from app.domain.entities.enums import (
    AgendamentoStatus,
    AgendamentoTipo,
    DestinationType,
    LeadOrigem,
    LeadScore,
    LeadStatus,
    OrcamentoPerfil,
    PerfilViagem,
    PropostaStatus,
    SuitcaseCategory,
    TipoMensagem,
)

logger = structlog.get_logger()
DEMO_PASSWORD = "Cadife@2026"


# ─── helpers ──────────────────────────────────────────────────────────────────


async def get_admin(session: AsyncSession) -> User:
    result = await session.execute(
        select(User).where(User.perfil == UserPerfil.admin)
    )
    admin = result.scalar_one_or_none()
    if not admin:
        print("[ERROR] No admin found. Run scripts/seed_admin.py first.")
        sys.exit(1)
    return admin


async def get_or_create_user(
    session: AsyncSession,
    email: str,
    nome: str,
    perfil: UserPerfil,
    telefone: str | None = None,
    **kwargs,
) -> User:
    result = await session.execute(select(User).where(User.email == email))
    existing = result.scalar_one_or_none()
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
    phone_hash = hmac_hash(telefone)
    result = await session.execute(
        select(Lead).where(Lead.telefone_hash == phone_hash)
    )
    existing = result.scalar_one_or_none()
    if existing:
        print(f"  [SKIP] Lead {kwargs.get('nome', telefone)}")
        return existing
    lead = Lead(telefone=telefone, telefone_hash=phone_hash, **kwargs)
    session.add(lead)
    await session.flush()
    print(f"  [NEW]  Lead {kwargs.get('nome', telefone)}")
    return lead


async def get_or_create_briefing(
    session: AsyncSession, lead_id: uuid.UUID, **fields
) -> Briefing:
    result = await session.execute(
        select(Briefing).where(Briefing.lead_id == lead_id)
    )
    if result.scalar_one_or_none():
        print(f"  [SKIP] Briefing for lead {lead_id}")
        return
    completude = calculate_completude(fields)
    session.add(Briefing(lead_id=lead_id, completude_pct=completude, **fields))
    await session.flush()
    print(f"  [NEW]  Briefing ({completude}% completude) for lead {lead_id}")


# ─── 1. users ─────────────────────────────────────────────────────────────────


async def seed_users(session: AsyncSession) -> dict[str, User]:
    print("\n[1/7] Seeding users...")
    u: dict[str, User] = {}

    u["daniela"] = await get_or_create_user(
        session,
        email="daniela.costa@cadifetoure.com.br",
        nome="Daniela Costa",
        perfil=UserPerfil.consultor,
        telefone="+5511977777777",
    )
    u["otavio"] = await get_or_create_user(
        session,
        email="otavio.grotto@gmail.com",
        nome="Otávio Grotto",
        perfil=UserPerfil.cliente,
        telefone="+5511966666666",
        tipo_viagem=["turismo", "lazer"],
        preferencias=["luxo", "cidade", "frio"],
        tem_passaporte=True,
    )
    u["camila"] = await get_or_create_user(
        session,
        email="camila.santos@gmail.com",
        nome="Camila Santos",
        perfil=UserPerfil.cliente,
        telefone="+5511955555555",
        tipo_viagem=["aventura", "lazer"],
        preferencias=["cidade", "calor"],
        tem_passaporte=True,
    )
    u["rafael"] = await get_or_create_user(
        session,
        email="rafael.mendes@gmail.com",
        nome="Rafael Mendes",
        perfil=UserPerfil.cliente,
        telefone="+5511944444444",
        tipo_viagem=["turismo", "negócios"],
        preferencias=["cidade"],
        tem_passaporte=False,
    )

    await session.commit()
    return u


# ─── 2. leads ─────────────────────────────────────────────────────────────────


async def seed_leads(
    session: AsyncSession, users: dict[str, User], admin: User
) -> dict[str, Lead]:
    print("\n[2/7] Seeding leads...")
    consultor = users["daniela"]
    leads: dict[str, Lead] = {}

    leads["otavio"] = await get_or_create_lead(
        session,
        telefone="+5511966666666",
        nome="Otávio Grotto",
        origem=LeadOrigem.app,
        status=LeadStatus.fechado,
        score=LeadScore.quente,
        consultor_id=consultor.id,
    )
    leads["camila"] = await get_or_create_lead(
        session,
        telefone="+5511955555555",
        nome="Camila Santos",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.proposta,
        score=LeadScore.morno,
        consultor_id=consultor.id,
    )
    leads["rafael"] = await get_or_create_lead(
        session,
        telefone="+5511944444444",
        nome="Rafael Mendes",
        origem=LeadOrigem.whatsapp,
        status=LeadStatus.agendado,
        score=LeadScore.quente,
        consultor_id=admin.id,
    )

    await session.commit()
    return leads


# ─── 3. briefings ─────────────────────────────────────────────────────────────


async def seed_briefings(
    session: AsyncSession, leads: dict[str, Lead]
) -> None:
    print("\n[3/7] Seeding briefings...")

    await get_or_create_briefing(
        session,
        lead_id=leads["otavio"].id,
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
    await get_or_create_briefing(
        session,
        lead_id=leads["camila"].id,
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
        tem_passaporte=None,
        observacoes="Grupo de 4 amigas. Uma tem alergia a frutos do mar.",
    )
    await get_or_create_briefing(
        session,
        lead_id=leads["rafael"].id,
        destino="Nova York, EUA",
        origem="Belo Horizonte, Brasil",
        data_ida=date(2026, 7, 15),
        data_volta=date(2026, 7, 25),
        duracao_dias=10,
        qtd_pessoas=4,
        perfil=PerfilViagem.familia,
        tipo_viagem=["turismo", "compras"],
        preferencias=[],
        orcamento=OrcamentoPerfil.alto,
        tem_passaporte=None,
        observacoes="2 adultos e 2 crianças (8 e 12 anos). Querem visitar a Disney.",
    )

    await session.commit()
    print("  [OK] Briefings done.")


# ─── 4. agendamentos ──────────────────────────────────────────────────────────


async def seed_agendamentos(
    session: AsyncSession,
    leads: dict[str, Lead],
    users: dict[str, User],
    admin: User,
) -> None:
    print("\n[4/7] Seeding agendamentos...")
    consultor = users["daniela"]

    rows = [
        dict(
            lead_id=leads["otavio"].id,
            data=date(2026, 2, 14),
            hora=time(10, 0),
            status=AgendamentoStatus.realizado,
            tipo=AgendamentoTipo.online,
            consultor_id=consultor.id,
        ),
        dict(
            lead_id=leads["camila"].id,
            data=date(2026, 4, 22),
            hora=time(14, 0),
            status=AgendamentoStatus.realizado,
            tipo=AgendamentoTipo.online,
            consultor_id=consultor.id,
        ),
        dict(
            lead_id=leads["rafael"].id,
            data=date(2026, 6, 2),
            hora=time(11, 0),
            status=AgendamentoStatus.confirmado,
            tipo=AgendamentoTipo.online,
            consultor_id=admin.id,
        ),
    ]

    for row in rows:
        exists = await session.execute(
            select(Agendamento).where(
                Agendamento.lead_id == row["lead_id"],
                Agendamento.data == row["data"],
            )
        )
        if exists.scalar_one_or_none():
            print(f"  [SKIP] Agendamento {row['data']} lead {row['lead_id']}")
            continue
        session.add(Agendamento(**row))
        print(f"  [NEW]  Agendamento {row['data']} ({row['status'].value})")

    await session.commit()
    print("  [OK] Agendamentos done.")


# ─── 5. propostas ─────────────────────────────────────────────────────────────


async def seed_propostas(
    session: AsyncSession,
    leads: dict[str, Lead],
    users: dict[str, User],
) -> None:
    print("\n[5/7] Seeding propostas...")
    consultor = users["daniela"]

    rows = [
        dict(
            lead_id=leads["otavio"].id,
            descricao=(
                "Pacote Paris Romântico 7 dias — Voos TAM direto São Paulo↔Paris, "
                "hotel Hôtel de Crillon 5★, traslados, jantar exclusivo Torre Eiffel, "
                "passeio de barco no Sena ao pôr do sol, guia privativo em português."
            ),
            valor_estimado=28500.00,
            status=PropostaStatus.aprovada,
            consultor_id=consultor.id,
            expiration_hours=72,
        ),
        dict(
            lead_id=leads["camila"].id,
            descricao=(
                "Pacote Japão Explorer 14 dias para 4 pessoas — Voos Qatar Airways "
                "São Paulo↔Tóquio com escala em Doha, hotel Shinjuku Granbell 4★, "
                "JR Pass 14 dias, day trips Kyoto e Osaka, experiência de culinária "
                "japonesa com chef local. Produto sem frutos do mar disponível."
            ),
            valor_estimado=18900.00,
            status=PropostaStatus.enviada,
            consultor_id=consultor.id,
            expiration_hours=48,
        ),
    ]

    for row in rows:
        exists = await session.execute(
            select(Proposta).where(Proposta.lead_id == row["lead_id"])
        )
        if exists.scalar_one_or_none():
            print(f"  [SKIP] Proposta lead {row['lead_id']}")
            continue
        session.add(Proposta(**row))
        print(f"  [NEW]  Proposta ({row['status'].value}) lead {row['lead_id']}")

    await session.commit()
    print("  [OK] Propostas done.")


# ─── 6. interações ────────────────────────────────────────────────────────────


async def seed_interacoes(
    session: AsyncSession, leads: dict[str, Lead]
) -> None:
    print("\n[6/7] Seeding interações...")

    convs: list[tuple[uuid.UUID, list[tuple[str, str]]]] = [
        (
            leads["otavio"].id,
            [
                (
                    "Olá! Quero planejar uma viagem especial para Paris com minha esposa.",
                    "Que maravilha! Paris é um destino inesquecível! Para te ajudar a "
                    "criar a experiência perfeita, me conta: qual período vocês pensam em "
                    "viajar? E qual o estilo — algo mais romântico, cultural ou os dois?",
                ),
                (
                    "Queremos ir em março, algo bem romântico. É nosso aniversário de casamento!",
                    "Que lindo! Março é perfeito para Paris — o frio suave e as ruas menos "
                    "cheias criam uma atmosfera muito especial. Quantas pessoas serão? Somente vocês dois?",
                ),
                (
                    "Só nós dois. Temos passaporte válido e queremos um hotel no centro mesmo.",
                    "Perfeito! Dois adultos, passaporte em mãos — ótimo! Para um roteiro no "
                    "coração de Paris com atmosfera romântica, qual o perfil de investimento "
                    "que vocês planejam? Econômico, conforto, alto padrão ou luxo?",
                ),
                (
                    "Luxo mesmo! É uma ocasião especial.",
                    "Entendido! Já tenho tudo que preciso para montar um roteiro incrível para "
                    "vocês. Nossa consultora Daniela entrará em contato em breve para apresentar "
                    "opções exclusivas de hotéis 5 estrelas e experiências únicas em Paris!",
                ),
            ],
        ),
        (
            leads["camila"].id,
            [
                (
                    "Oi! Somos 4 amigas querendo ir ao Japão em agosto!",
                    "Que aventura incrível! O Japão em agosto é animadíssimo — tem festivais "
                    "tradicionais e a natureza exuberante. Vocês têm datas definidas? E qual "
                    "cidade principal querem explorar?",
                ),
                (
                    "Tóquio principal, mas queremos conhecer Kyoto também. Ficamos em agosto.",
                    "Tóquio + Kyoto é o combo perfeito! Dá pra fazer um roteiro fantástico em "
                    "2 semanas. Qual o perfil da turma — aventura, gastronomia, compras, templos?",
                ),
                (
                    "Tudo isso! Mas principalmente gastronomia e aventura. Uma de nós tem alergia a frutos do mar.",
                    "Anotado sobre a alergia — muito importante! O Japão tem opções incríveis "
                    "sem frutos do mar. Para 4 pessoas com 14 dias, qual o perfil de "
                    "investimento? Econômico, intermediário ou alto padrão?",
                ),
                (
                    "Alto padrão! Já economizamos bastante para essa viagem.",
                    "Maravilha! Com alto padrão em 14 dias para o Japão, nossa consultora vai "
                    "montar um roteiro exclusivo. Vou conectar vocês com a Daniela em breve!",
                ),
            ],
        ),
        (
            leads["rafael"].id,
            [
                (
                    "Olá! Quero levar minha família para Nova York.",
                    "Que destino incrível! Nova York tem algo para todos — desde shows da "
                    "Broadway até o Central Park. Me conta: quantas pessoas serão na viagem?",
                ),
                (
                    "4 pessoas, 2 adultos e 2 crianças de 8 e 12 anos. Queremos ir em julho.",
                    "Família incrível! Julho é excelente para Nova York. As crianças vão adorar! "
                    "Vocês têm passaporte? E já pensaram em quantos dias querem ficar?",
                ),
                (
                    "10 dias. Passaporte... preciso verificar.",
                    "Perfeito, 10 dias é um tempo ótimo! Sobre os passaportes, é bom verificar "
                    "logo pois pode levar algum tempo para tirar/renovar. Qual o perfil de "
                    "investimento para a família?",
                ),
            ],
        ),
    ]

    for lead_id, messages in convs:
        exists = await session.execute(
            select(Interacao).where(Interacao.lead_id == lead_id).limit(1)
        )
        if exists.scalar_one_or_none():
            print(f"  [SKIP] Interações lead {lead_id}")
            continue
        for cliente_msg, ia_msg in messages:
            session.add(
                Interacao(
                    lead_id=lead_id,
                    mensagem_cliente=cliente_msg,
                    mensagem_ia=ia_msg,
                    tipo_mensagem=TipoMensagem.texto,
                    status_envio="sent",
                )
            )
        print(f"  [NEW]  {len(messages)} interações lead {lead_id}")

    await session.commit()
    print("  [OK] Interações done.")


# ─── 7a. suitcase items ───────────────────────────────────────────────────────


async def seed_suitcase_items(
    session: AsyncSession,
    leads: dict[str, Lead],
    users: dict[str, User],
) -> None:
    print("\n[7a] Seeding suitcase items...")

    # (categoria, nome, quantidade, empacotado)
    items_by_client: dict[str, list[tuple]] = {
        "otavio": [
            (SuitcaseCategory.documentos, "Passaporte", 2, True),
            (SuitcaseCategory.documentos, "Visto Schengen", 2, True),
            (SuitcaseCategory.documentos, "Seguro Viagem Internacional", 1, True),
            (SuitcaseCategory.documentos, "Cartão de Crédito Internacional", 2, True),
            (SuitcaseCategory.roupas, "Casaco de Lã", 2, True),
            (SuitcaseCategory.roupas, "Suéter de Inverno", 3, True),
            (SuitcaseCategory.roupas, "Calça Jeans", 2, True),
            (SuitcaseCategory.roupas, "Vestido Elegante", 1, True),
            (SuitcaseCategory.roupas, "Trench Coat Impermeável", 1, True),
            (SuitcaseCategory.higiene, "Hidratante Facial", 1, True),
            (SuitcaseCategory.higiene, "Protetor Labial", 2, True),
            (SuitcaseCategory.eletronicos, "Adaptador de Tomada Universal", 1, True),
            (SuitcaseCategory.eletronicos, "Câmera Fotográfica", 1, True),
            (SuitcaseCategory.eletronicos, "Carregador Portátil", 1, True),
            (SuitcaseCategory.acessorios, "Guarda-Chuva Compacto", 2, False),
        ],
        "camila": [
            (SuitcaseCategory.documentos, "Passaporte", 4, False),
            (SuitcaseCategory.documentos, "Seguro Viagem", 4, False),
            (SuitcaseCategory.roupas, "Camisetas Casuais", 8, False),
            (SuitcaseCategory.roupas, "Calças Jeans", 4, False),
            (SuitcaseCategory.roupas, "Tênis Confortável", 4, False),
            (SuitcaseCategory.higiene, "Protetor Solar FPS 50+", 4, False),
            (SuitcaseCategory.eletronicos, "Adaptador Tomada Japonesa (tipo A)", 4, False),
            (SuitcaseCategory.eletronicos, "Carregador Portátil", 4, False),
            (SuitcaseCategory.saude, "Antialérgico (sem frutos do mar)", 1, False),
        ],
        "rafael": [
            (SuitcaseCategory.documentos, "Passaporte", 4, False),
            (SuitcaseCategory.documentos, "ESTA / Visto Americano", 4, False),
            (SuitcaseCategory.roupas, "Casaco Leve", 4, False),
            (SuitcaseCategory.roupas, "Tênis Confortável", 4, False),
            (SuitcaseCategory.eletronicos, "Adaptador de Tomada EUA", 1, False),
            (SuitcaseCategory.eletronicos, "Carregador Portátil", 1, False),
        ],
    }

    for key, items in items_by_client.items():
        lead = leads.get(key)
        user = users.get(key)
        if not lead or not user:
            continue
        exists = await session.execute(
            select(SuitcaseItemModel)
            .where(SuitcaseItemModel.lead_id == lead.id)
            .limit(1)
        )
        if exists.scalar_one_or_none():
            print(f"  [SKIP] Suitcase items for {key}")
            continue
        for categoria, nome, quantidade, empacotado in items:
            session.add(
                SuitcaseItemModel(
                    lead_id=lead.id,
                    user_id=user.id,
                    categoria=categoria.value,
                    nome=nome,
                    quantidade=quantidade,
                    empacotado=empacotado,
                )
            )
        print(f"  [NEW]  {len(items)} suitcase items for {key}")

    await session.commit()
    print("  [OK] Suitcase items done.")


# ─── 7b. suitcase suggestions ─────────────────────────────────────────────────


async def seed_suitcase_suggestions(session: AsyncSession) -> None:
    print("\n[7b] Seeding suitcase suggestions...")
    exists = await session.execute(
        select(SuitcaseSuggestionModel).limit(1)
    )
    if exists.scalar_one_or_none():
        print("  [SKIP] Suggestions already exist.")
        return

    # (tipo_destino, categoria, nome, quantidade_sugerida, descricao)
    rows: list[tuple] = [
        # ── PRAIA ─────────────────────────────────────────────────────────────
        (DestinationType.praia, SuitcaseCategory.documentos, "Passaporte", 1, "Documento essencial para viagens internacionais"),
        (DestinationType.praia, SuitcaseCategory.documentos, "Seguro Viagem", 1, "Cobertura médica e de bagagem"),
        (DestinationType.praia, SuitcaseCategory.documentos, "Cartão de Crédito Internacional", 1, "Para compras e emergências"),
        (DestinationType.praia, SuitcaseCategory.roupas, "Biquíni ou Sunga", 3, "Leve pelo menos 3 para alternar"),
        (DestinationType.praia, SuitcaseCategory.roupas, "Camiseta Leve", 5, "Para o dia a dia"),
        (DestinationType.praia, SuitcaseCategory.roupas, "Short", 3, None),
        (DestinationType.praia, SuitcaseCategory.roupas, "Vestido Casual", 2, "Para jantar e passeios"),
        (DestinationType.praia, SuitcaseCategory.roupas, "Saída de Praia", 2, None),
        (DestinationType.praia, SuitcaseCategory.roupas, "Sandália de Praia", 1, None),
        (DestinationType.praia, SuitcaseCategory.higiene, "Protetor Solar FPS 50+", 2, "Reaplicar a cada 2h na praia"),
        (DestinationType.praia, SuitcaseCategory.higiene, "Repelente", 1, "Para atividades ao ar livre à noite"),
        (DestinationType.praia, SuitcaseCategory.higiene, "Pós-Sol Hidratante", 1, None),
        (DestinationType.praia, SuitcaseCategory.higiene, "Shampoo e Condicionador", 1, None),
        (DestinationType.praia, SuitcaseCategory.acessorios, "Óculos de Sol", 1, "Proteção UV obrigatória"),
        (DestinationType.praia, SuitcaseCategory.acessorios, "Chapéu ou Boné", 1, None),
        (DestinationType.praia, SuitcaseCategory.acessorios, "Bolsa de Praia Impermeável", 1, None),
        (DestinationType.praia, SuitcaseCategory.eletronicos, "Câmera à Prova d'Água", 1, "Para fotos incríveis na água"),
        (DestinationType.praia, SuitcaseCategory.eletronicos, "Carregador Portátil", 1, None),
        (DestinationType.praia, SuitcaseCategory.eletronicos, "Fone de Ouvido Bluetooth", 1, None),
        (DestinationType.praia, SuitcaseCategory.saude, "Antialérgico", 1, "Para reações a frutos do mar ou insetos"),

        # ── FRIO ──────────────────────────────────────────────────────────────
        (DestinationType.frio, SuitcaseCategory.documentos, "Passaporte", 1, None),
        (DestinationType.frio, SuitcaseCategory.documentos, "Seguro Viagem", 1, "Inclua cobertura para esportes de neve se necessário"),
        (DestinationType.frio, SuitcaseCategory.documentos, "Cartão de Crédito Internacional", 1, None),
        (DestinationType.frio, SuitcaseCategory.roupas, "Casaco de Inverno Impermeável", 1, "Com capuz, impermeável"),
        (DestinationType.frio, SuitcaseCategory.roupas, "Luvas Térmicas", 1, "Par impermeável"),
        (DestinationType.frio, SuitcaseCategory.roupas, "Cachecol de Lã", 1, None),
        (DestinationType.frio, SuitcaseCategory.roupas, "Touca", 1, None),
        (DestinationType.frio, SuitcaseCategory.roupas, "Meias Térmicas", 5, None),
        (DestinationType.frio, SuitcaseCategory.roupas, "Suéter de Lã", 3, None),
        (DestinationType.frio, SuitcaseCategory.roupas, "Calça Jeans Grossa", 2, None),
        (DestinationType.frio, SuitcaseCategory.roupas, "Roupa Térmica de Base", 2, "Para baixo do casaco"),
        (DestinationType.frio, SuitcaseCategory.roupas, "Bota Impermeável", 1, "Par para neve ou chuva"),
        (DestinationType.frio, SuitcaseCategory.higiene, "Hidratante Corporal Intensivo", 1, "Para o ar seco do frio"),
        (DestinationType.frio, SuitcaseCategory.higiene, "Protetor Labial", 2, "O frio reseca os lábios"),
        (DestinationType.frio, SuitcaseCategory.higiene, "Creme para Mãos", 1, None),
        (DestinationType.frio, SuitcaseCategory.eletronicos, "Adaptador de Tomada Universal", 1, None),
        (DestinationType.frio, SuitcaseCategory.eletronicos, "Carregador Portátil", 1, "Baterias duram menos no frio"),
        (DestinationType.frio, SuitcaseCategory.saude, "Vitamina C", 1, "Para fortalecer a imunidade"),
        (DestinationType.frio, SuitcaseCategory.saude, "Descongestionante Nasal", 1, "Para o ar frio e seco"),

        # ── URBANO ────────────────────────────────────────────────────────────
        (DestinationType.urbano, SuitcaseCategory.documentos, "Passaporte", 1, None),
        (DestinationType.urbano, SuitcaseCategory.documentos, "Visto (se necessário)", 1, "Verifique a necessidade para o país destino"),
        (DestinationType.urbano, SuitcaseCategory.documentos, "Seguro Viagem", 1, None),
        (DestinationType.urbano, SuitcaseCategory.documentos, "Cartão de Crédito Internacional", 1, None),
        (DestinationType.urbano, SuitcaseCategory.roupas, "Calça Social ou Jeans", 2, None),
        (DestinationType.urbano, SuitcaseCategory.roupas, "Blazer Casual", 1, "Versátil para diferentes ocasiões"),
        (DestinationType.urbano, SuitcaseCategory.roupas, "Camisa Social", 3, None),
        (DestinationType.urbano, SuitcaseCategory.roupas, "Camiseta Casual", 4, None),
        (DestinationType.urbano, SuitcaseCategory.roupas, "Tênis Confortável", 1, "Para longas caminhadas"),
        (DestinationType.urbano, SuitcaseCategory.roupas, "Sapato Casual", 1, None),
        (DestinationType.urbano, SuitcaseCategory.higiene, "Protetor Solar FPS 30", 1, "Para dias ao ar livre"),
        (DestinationType.urbano, SuitcaseCategory.higiene, "Kit Higiene Básico", 1, "Escova, pasta, desodorante"),
        (DestinationType.urbano, SuitcaseCategory.eletronicos, "Adaptador de Tomada", 1, "Verifique o padrão do país"),
        (DestinationType.urbano, SuitcaseCategory.eletronicos, "Carregador Portátil", 1, None),
        (DestinationType.urbano, SuitcaseCategory.eletronicos, "Câmera Fotográfica", 1, None),
        (DestinationType.urbano, SuitcaseCategory.acessorios, "Mochila Pequena", 1, "Para passeios diários"),
        (DestinationType.urbano, SuitcaseCategory.acessorios, "Guarda-Chuva Compacto", 1, "Para chuvas inesperadas"),

        # ── AVENTURA ──────────────────────────────────────────────────────────
        (DestinationType.aventura, SuitcaseCategory.documentos, "Passaporte", 1, None),
        (DestinationType.aventura, SuitcaseCategory.documentos, "Seguro de Aventura", 1, "Cobertura para esportes radicais"),
        (DestinationType.aventura, SuitcaseCategory.documentos, "Cartão de Vacinação", 1, "Verifique vacinas necessárias para o destino"),
        (DestinationType.aventura, SuitcaseCategory.roupas, "Calça de Trekking", 2, "Resistente e de secagem rápida"),
        (DestinationType.aventura, SuitcaseCategory.roupas, "Camisa Manga Longa UV", 3, "Proteção solar e contra insetos"),
        (DestinationType.aventura, SuitcaseCategory.roupas, "Boné ou Chapéu", 1, "Para o sol intenso"),
        (DestinationType.aventura, SuitcaseCategory.roupas, "Bota de Trilha", 1, "Par com suporte ao tornozelo"),
        (DestinationType.aventura, SuitcaseCategory.roupas, "Meia Cano Alto", 3, "Para usar com botas"),
        (DestinationType.aventura, SuitcaseCategory.roupas, "Capa de Chuva Leve", 1, None),
        (DestinationType.aventura, SuitcaseCategory.saude, "Kit Primeiros Socorros", 1, "Band-aid, antisséptico, analgésico"),
        (DestinationType.aventura, SuitcaseCategory.saude, "Repelente com DEET", 1, "Alta concentração para áreas de risco"),
        (DestinationType.aventura, SuitcaseCategory.saude, "Antialérgico", 1, None),
        (DestinationType.aventura, SuitcaseCategory.saude, "Antiácido", 1, None),
        (DestinationType.aventura, SuitcaseCategory.eletronicos, "Lanterna de Cabeça", 1, "Deixa as mãos livres"),
        (DestinationType.aventura, SuitcaseCategory.eletronicos, "Carregador Solar", 1, "Para áreas remotas sem energia"),
        (DestinationType.aventura, SuitcaseCategory.eletronicos, "Carregador Portátil", 1, None),
        (DestinationType.aventura, SuitcaseCategory.acessorios, "Mochila 40L", 1, "Para trilhas e acampamentos"),
        (DestinationType.aventura, SuitcaseCategory.acessorios, "Cantil ou Garrafa Térmica", 1, "Hidratação constante"),
        (DestinationType.aventura, SuitcaseCategory.acessorios, "Bastão de Trekking", 2, "Par para maior estabilidade"),
        (DestinationType.aventura, SuitcaseCategory.acessorios, "Saco de Dormir Leve", 1, "Para acampamentos ou hostels"),
    ]

    for tipo_destino, categoria, nome, quantidade, descricao in rows:
        session.add(
            SuitcaseSuggestionModel(
                tipo_destino=tipo_destino.value,
                categoria=categoria.value,
                nome=nome,
                quantidade_sugerida=quantidade,
                descricao=descricao,
            )
        )

    await session.commit()
    print(f"  [OK] {len(rows)} suitcase suggestions seeded.")


# ─── main ─────────────────────────────────────────────────────────────────────


async def main() -> None:
    print("=" * 55)
    print("  Cadife Smart Travel — Seed Profile Data")
    print("=" * 55)
    print(f"  Demo password for all new users: {DEMO_PASSWORD}\n")

    async with AsyncSessionLocal() as session:
        admin = await get_admin(session)
        users = await seed_users(session)
        leads = await seed_leads(session, users, admin)
        await seed_briefings(session, leads)
        await seed_agendamentos(session, leads, users, admin)
        await seed_propostas(session, leads, users)
        await seed_interacoes(session, leads)
        await seed_suitcase_items(session, leads, users)
        await seed_suitcase_suggestions(session)

    await engine.dispose()
    print("\n" + "=" * 55)
    print("  [DONE] Profile data seeded successfully!")
    print("=" * 55)
    print("\nCredenciais para teste no app Flutter:")
    print("  Otávio Grotto  → otavio.grotto@gmail.com")
    print("  Camila Santos  → camila.santos@gmail.com")
    print("  Rafael Mendes  → rafael.mendes@gmail.com")
    print("  Daniela Costa  → daniela.costa@cadifetoure.com.br")
    print(f"  Senha de todos: {DEMO_PASSWORD}")


if __name__ == "__main__":
    asyncio.run(main())
