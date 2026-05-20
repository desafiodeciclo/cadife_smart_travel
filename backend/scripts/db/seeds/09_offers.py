"""
09_offers — Vitrine digital da Cadife Tour (22 ofertas publicadas).

Cobre os mocks do Flutter e adiciona novas categorias:
  - lua_de_mel: Maldivas, Paris, Santorini, Bali, Maldivas Low Season
  - internacional: Tóquio, Milão, Praga, Austrália, Egito, Machu Picchu
  - executivo: Nova York, Dubai
  - aventura: Alpes Suíços, Patagônia, Safári África do Sul
  - cruzeiro: Caribe, Mediterrâneo, Fiordos Noruegueses
  - nacional: Gramado, Fernando de Noronha, Pantanal
  - outros: Cancún

Todas em status 'published' (admin).
"""
from __future__ import annotations

import sys
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

_BACKEND = Path(__file__).resolve().parents[3]
_SEEDS = Path(__file__).resolve().parent
for _p in [str(_BACKEND), str(_SEEDS)]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import OfferCategoria, OfferStatus
from app.models.offer import Offer
from shared import get_admin


# (titulo, destino, categoria, preco_base, duracao_dias, data_saida, servicos, descricao)
_OFFERS = [
    # ── Lua de mel ─────────────────────────────────────────────────────────────
    (
        "Lua de Mel nas Maldivas",
        "Maldivas",
        OfferCategoria.lua_de_mel,
        12_500.00, 10, date(2026, 8, 15),
        ["Voo direto", "Transfer aquático", "Villa overwater", "Café da manhã incluso", "Mergulho guiado"],
        "Experiência exclusiva em villa sobre o oceano Índico. Recifes de coral, areia branca e pôr do sol inesquecível para casais.",
    ),
    (
        "Paris Romântico — 7 Dias",
        "Paris, França",
        OfferCategoria.lua_de_mel,
        8_900.00, 7, date(2026, 9, 10),
        ["Voo TAM direto GRU–CDG", "Hotel 4★ no centro", "Jantar Torre Eiffel", "Passeio de barco no Sena", "Guia privativo"],
        "A cidade do amor com curadoria exclusiva: museus, gastronomia, champanhe e momentos únicos à beira do Sena.",
    ),
    (
        "Santorini — O Azul do Egeu",
        "Santorini, Grécia",
        OfferCategoria.lua_de_mel,
        6_500.00, 8, date(2026, 9, 3),
        ["Voo incluso", "Suíte com vista para a caldera", "Passeio de catamarã", "Tour vinícola", "Jantar ao pôr do sol em Oia"],
        "Cúpulas azuis, vulcões e o mar Egeu: o pôr do sol mais famoso do mundo espera por você em Oia.",
    ),
    (
        "Bali Romântico — Ubud & Seminyak",
        "Bali, Indonésia",
        OfferCategoria.lua_de_mel,
        7_200.00, 12, date(2026, 10, 8),
        ["Voo incluso", "Villa com piscina privativa", "Spa balinês 4h", "Aula de culinária balinesa", "Transfer privativo"],
        "A ilha dos deuses com rituais de cura, templos milenares, arrozais esmeralda e praias douradas de Seminyak.",
    ),
    # ── Internacional ──────────────────────────────────────────────────────────
    (
        "Tóquio Imersão Cultural",
        "Tóquio, Japão",
        OfferCategoria.internacional,
        9_800.00, 14, date(2026, 10, 5),
        ["Voo Qatar Airways", "Hotel Shinjuku 4★", "JR Pass 14 dias", "Day trips Kyoto e Osaka", "Workshop culinária japonesa"],
        "Do futuro ao passado: Akihabara, Shibuya, templos de Kyoto e a culinária mais fascinante do mundo.",
    ),
    (
        "Milão — Moda e Gastronomia",
        "Milão, Itália",
        OfferCategoria.internacional,
        5_200.00, 6, date(2026, 10, 18),
        ["Voo incluso", "Hotel Design District 4★", "Tour gastronômico", "Visita Duomo e La Scala", "Personal shopper"],
        "A capital mundial da moda e do design. Da risoto ao tiramisù, de Versace a Leonardo da Vinci.",
    ),
    (
        "Praga — A Cidade Dourada",
        "Praga, Rep. Tcheca",
        OfferCategoria.internacional,
        4_100.00, 6, date(2026, 8, 22),
        ["Voo incluso", "Hotel Cidade Antiga 4★", "Tour castelo de Praga", "Degustação de cerveja artesanal", "Cruzeiro no Vltava"],
        "Uma das cidades medievais mais preservadas da Europa. Torres góticas, pontes de pedra e a melhor cerveja do mundo.",
    ),
    (
        "Austrália — Sydney & Grande Barreira de Coral",
        "Sydney e Cairns, Austrália",
        OfferCategoria.internacional,
        14_200.00, 15, date(2026, 11, 8),
        ["Voos LATAM GRU–SYD + Sydney–CNS", "Hotel Sydney 4★", "Resort Cairns 4★", "Mergulho Grande Barreira de Coral", "Sydney Harbour Cruise"],
        "A maior ilha do mundo com a ópera de Sydney, Bondi Beach, os 14 kangaroos de Hunter Valley e o maior recife vivo do planeta.",
    ),
    (
        "Egito Faraônico — Cairo, Nilo e Luxor",
        "Cairo e Luxor, Egito",
        OfferCategoria.internacional,
        7_800.00, 11, date(2026, 10, 12),
        ["Voo incluso", "Hotel Cairo 5★", "Cruzeiro no Nilo 4 noites", "Guia arqueólogo privativo", "Visita pirâmides ao amanhecer"],
        "4.500 anos de história em cada pedra. Pirâmides de Gizé, Vale dos Reis, Templo de Karnak e o lendário mercado Khan el-Khalili.",
    ),
    (
        "Machu Picchu e Cusco — Mistério Inca",
        "Cusco e Machu Picchu, Peru",
        OfferCategoria.internacional,
        6_400.00, 9, date(2026, 7, 6),
        ["Voo incluso", "Hotel Cusco 4★", "Trem Hiram Bingham (luxo)", "Ingresso Machu Picchu", "Tour Vale Sagrado", "Guia arqueólogo"],
        "Uma das 7 maravilhas do mundo moderno. A cidadela inca suspensa entre montanhas e nuvens que mudará sua perspectiva de vida.",
    ),
    # ── Executivo ──────────────────────────────────────────────────────────────
    (
        "Nova York — City Break",
        "Nova York, EUA",
        OfferCategoria.executivo,
        7_500.00, 7, date(2026, 11, 15),
        ["Voo incluso", "Hotel Midtown 4★", "Transfer JFK", "City Pass (5 atrações)", "Cruzeiro ao redor de Manhattan"],
        "A cidade que nunca dorme: Broadway, Central Park, museus de classe mundial e gastronomia de alto nível.",
    ),
    (
        "Dubai Luxury Experience",
        "Dubai, Emirados Árabes",
        OfferCategoria.executivo,
        18_500.00, 8, date(2026, 9, 25),
        ["Voo Emirates Business Class", "Hotel Burj Al Arab 7★", "Transfer em limousine", "Desert Safari VIP", "Jantar Burj Khalifa"],
        "O luxo absoluto do Oriente Médio: arranha-céus dourados, shopping de altíssimo padrão e experiences únicas no deserto.",
    ),
    # ── Aventura ───────────────────────────────────────────────────────────────
    (
        "Alpes Suíços — Ski & Neve",
        "Alpes Suíços, Suíça",
        OfferCategoria.aventura,
        15_800.00, 10, date(2026, 12, 20),
        ["Voo Swiss Air", "Chalé boutique 5★", "Ski pass 7 dias", "Aulas de esqui", "Passeio de trenó"],
        "As montanhas mais belas da Europa com neve garantida. Esqui, snowboard e gastronomia alpina em cenário de conto de fadas.",
    ),
    (
        "Patagônia — Aventura Extrema",
        "Patagônia, Argentina/Chile",
        OfferCategoria.aventura,
        8_400.00, 12, date(2026, 3, 10),
        ["Voos nacionais inclusos", "Lodge 4★ com vista geleiras", "Trekking guiado", "Navegação Lago Argentino", "Fotografia profissional"],
        "O fim do mundo com paisagens que roubam o fôlego: glaciares, condores, montanhas nevadas e trilhas épicas.",
    ),
    (
        "Safári África do Sul — Big Five",
        "Kruger e Cape Town, África do Sul",
        OfferCategoria.aventura,
        13_600.00, 12, date(2026, 8, 3),
        ["Voo incluso", "Lodge de safári 4★", "3 saídas de jipe/dia", "Voo Cape Town", "Tour Robben Island", "Wine tour Stellenbosch"],
        "Os Big Five no Parque Kruger ao amanhecer, os pinguins de Boulders Beach e os vinhos de Stellenbosch. África em toda a sua glória.",
    ),
    # ── Cruzeiro ───────────────────────────────────────────────────────────────
    (
        "Cruzeiro pelo Caribe — 7 Noites",
        "Caribe",
        OfferCategoria.cruzeiro,
        5_900.00, 9, date(2026, 6, 28),
        ["Cabine com varanda", "Pensão completa a bordo", "Entretenimento incluído", "Escala em 4 ilhas", "Open bar seleto"],
        "Embarque em Santos e descubra as ilhas caribenhas a bordo do MSC Fantasia. Praias paradisíacas em cada porto.",
    ),
    (
        "Cruzeiro Mediterrâneo — Itália, Grécia e Croácia",
        "Mediterrâneo",
        OfferCategoria.cruzeiro,
        8_200.00, 11, date(2026, 7, 12),
        ["Voo incluso", "Cabine balcão Costa Cruises", "Pensão completa", "Paradas em Barcelona, Gênova, Civitavecchia, Santorini, Dubrovnik", "Guias em português"],
        "O Mediterrâneo em 11 dias: pizza em Nápoles, arte em Florença, pôr do sol em Santorini e as muralhas medievais de Dubrovnik.",
    ),
    (
        "Cruzeiro Fiordos Noruegueses — Natureza Épica",
        "Noruega",
        OfferCategoria.cruzeiro,
        11_400.00, 10, date(2026, 6, 15),
        ["Voo incluso", "Cabine com janela panorâmica", "Pensão completa", "Fiordos Geiranger e Nærøy (UNESCO)", "Aurora boreal (se temporada)"],
        "Os fiordos mais espetaculares da Europa cortando montanhas de 1.400m. Casas coloridas de Bergen e a natureza selvagem norueguesa.",
    ),
    # ── Nacional ───────────────────────────────────────────────────────────────
    (
        "Serra Gaúcha — Gramado & Canela",
        "Gramado, Brasil",
        OfferCategoria.nacional,
        2_800.00, 5, date(2026, 7, 3),
        ["Transfer rodoviário", "Hotel fazenda 4★", "Festival de Natal incluído", "Degustação de vinhos"],
        "O charme europeu no coração do Rio Grande do Sul. Chocolates, fondue, natureza exuberante e o famoso Natal Luz.",
    ),
    (
        "Fernando de Noronha — Paraíso Preservado",
        "Fernando de Noronha, Brasil",
        OfferCategoria.nacional,
        6_800.00, 7, date(2026, 9, 6),
        ["Voos TAM GRU–REC–FEN", "Pousada 4★ com café incluso", "Passeio de barco com golfinhos", "Mergulho em Baía do Sancho", "Taxa de preservação inclusa"],
        "A ilha mais bonita do Brasil com praias preservadas, golfinhos, tartarugas marinhas e o snorkeling mais transparente do Atlântico.",
    ),
    (
        "Pantanal — Maior Biodiversidade do Planeta",
        "Pantanal, MT/MS — Brasil",
        OfferCategoria.nacional,
        3_900.00, 5, date(2026, 7, 20),
        ["Traslados inclusos", "Fazenda-lodge 4★", "2 safáris/dia com guia naturalista", "Passeio de barco", "Observação de onças"],
        "A maior planície alagável do mundo com jacarés, araras-azuis, tuiuiús e a maior chance do mundo de ver onças-pintadas na natureza.",
    ),
    # ── Outros ─────────────────────────────────────────────────────────────────
    (
        "Cancún All Inclusive",
        "Cancún, México",
        OfferCategoria.outros,
        6_200.00, 8, date(2026, 7, 20),
        ["Voo incluso", "Resort 5★ all inclusive", "Transfer aeroporto", "Open bar 24h", "Excursão Chichén Itzá"],
        "Sol, mar turquesa e resorts de luxo na Rivera Maya. Perfeito para relaxar ou explorar as ruínas maias.",
    ),
]


async def run(session: AsyncSession) -> None:
    exists = await session.execute(select(Offer).limit(1))
    if exists.scalar_one_or_none():
        print("  [SKIP] Offers (já existem registros)")
        return

    admin = await get_admin(session)

    for titulo, destino, _categoria, preco, duracao, data_saida, servicos, descricao in _OFFERS:
        dep = datetime(data_saida.year, data_saida.month, data_saida.day, 12, 0, tzinfo=timezone.utc)
        ret = dep + timedelta(days=duracao)
        deadline = dep - timedelta(days=30)
        slug = destino.split(",")[0].lower().replace(" ", "-")
        session.add(
            Offer(
                agency_id=admin.id,
                title=titulo,
                description=descricao,
                destination=destino,
                destination_image_url=f"https://picsum.photos/seed/{slug}/800/600",
                departure_date=dep,
                return_date=ret,
                booking_deadline=deadline,
                duration_days=duracao,
                accommodations=[],
                included_services=servicos,
                travelers=2,
                available_spots=10,
                spots_reserved=0,
                base_price=preco,
                final_price=preco,
                highlights=servicos[:3],
                amenities=[],
                status=OfferStatus.published,
                published_at=datetime.now(timezone.utc),
            )
        )

    await session.commit()
    print(f"  [NEW]  {len(_OFFERS)} offers publicadas")


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
