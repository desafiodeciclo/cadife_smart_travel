"""
09_offers — Vitrine digital da Cadife Tour (ofertas publicadas).

Cobre os dados mockados em:
  - frontend_flutter/lib/features/client/offers/data/repositories/mock_offer_repository.dart
    Destinations: Maldivas, Paris, Gramado, Cancún, Tóquio, Nova York,
                  Alpes Suíços, Patagônia, Caribe, Dubai
  - frontend_flutter/lib/features/client/home/infrastructure/mocks/client_home_mocks.dart
    Recommendations: Milão (Itália), Praga (Rep. Tcheca), Santorini (Grécia)

Todas as offers são criadas em status 'publicada' pelo usuário admin.
"""
from __future__ import annotations

import sys
from datetime import date
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
    (
        "Lua de Mel nas Maldivas",
        "Maldivas",
        OfferCategoria.lua_de_mel,
        12_500.00,
        10,
        date(2026, 8, 15),
        ["Voo direto", "Transfer aquático", "Villa overwater", "Café da manhã incluso", "Mergulho guiado"],
        "Experiência exclusiva em villa sobre o oceano Índico. Recifes de coral, areia branca e pôr do sol inesquecível para casais.",
    ),
    (
        "Paris Romântico — 7 Dias",
        "Paris, França",
        OfferCategoria.lua_de_mel,
        8_900.00,
        7,
        date(2026, 9, 10),
        ["Voo TAM direto GRU–CDG", "Hotel 4★ no centro", "Jantar Torre Eiffel", "Passeio de barco no Sena", "Guia privativo"],
        "A cidade do amor com curadoria exclusiva: museus, gastronomia, champanhe e momentos únicos à beira do Sena.",
    ),
    (
        "Serra Gaúcha — Gramado & Canela",
        "Gramado, Brasil",
        OfferCategoria.nacional,
        2_800.00,
        5,
        date(2026, 7, 3),
        ["Transfer rodoviário", "Hotel fazenda 4★", "Festival de Natal incluído", "Degustação de vinhos"],
        "O charme europeu no coração do Rio Grande do Sul. Chocolates, fondue, natureza exuberante e o famoso Natal Luz.",
    ),
    (
        "Cancún All Inclusive",
        "Cancún, México",
        OfferCategoria.outros,
        6_200.00,
        8,
        date(2026, 7, 20),
        ["Voo incluso", "Resort 5★ all inclusive", "Transfer aeroporto", "Open bar 24h", "Excursão Chichén Itzá"],
        "Sol, mar turquesa e resorts de luxo na Rivera Maya. Perfeito para relaxar ou explorar as ruínas maias.",
    ),
    (
        "Tóquio Imersão Cultural",
        "Tóquio, Japão",
        OfferCategoria.internacional,
        9_800.00,
        14,
        date(2026, 10, 5),
        ["Voo Qatar Airways", "Hotel Shinjuku 4★", "JR Pass 14 dias", "Day trips Kyoto e Osaka", "Workshop culinária japonesa"],
        "Do futuro ao passado: Akihabara, Shibuya, templos de Kyoto e a culinária mais fascinante do mundo.",
    ),
    (
        "Nova York — City Break",
        "Nova York, EUA",
        OfferCategoria.executivo,
        7_500.00,
        7,
        date(2026, 11, 15),
        ["Voo incluso", "Hotel Midtown 4★", "Transfer JFK", "City Pass (5 atrações)", "Cruzeiro ao redor de Manhattan"],
        "A cidade que nunca dorme: Broadway, Central Park, museus de classe mundial e gastronomia de alto nível.",
    ),
    (
        "Alpes Suíços — Ski & Neve",
        "Alpes Suíços, Suíça",
        OfferCategoria.aventura,
        15_800.00,
        10,
        date(2026, 12, 20),
        ["Voo Swiss Air", "Chalé boutique 5★", "Ski pass 7 dias", "Aulas de esqui", "Passeio de trenó"],
        "As montanhas mais belas da Europa com neve garantida. Esqui, snowboard e gastronomia alpina em cenário de conto de fadas.",
    ),
    (
        "Patagônia — Aventura Extrema",
        "Patagônia, Argentina/Chile",
        OfferCategoria.aventura,
        8_400.00,
        12,
        date(2026, 3, 10),
        ["Voos nacionais inclusos", "Lodge 4★ com vista geleiras", "Trekking guiado", "Navegação Lago Argentino", "Fotografia profissional"],
        "O fim do mundo com paisagens que roubam o fôlego: glaciares, condores, montanhas nevadas e trilhas épicas.",
    ),
    (
        "Cruzeiro pelo Caribe — 7 Noites",
        "Caribe",
        OfferCategoria.cruzeiro,
        5_900.00,
        9,
        date(2026, 6, 28),
        ["Cabine com varanda", "Pensão completa a bordo", "Entretenimento incluído", "Escala em 4 ilhas", "Open bar seleto"],
        "Embarque em Santos e descubra as ilhas caribenhas a bordo do MSC Fantasia. Praias paradisíacas em cada porto.",
    ),
    (
        "Dubai Luxury Experience",
        "Dubai, Emirados Árabes",
        OfferCategoria.executivo,
        18_500.00,
        8,
        date(2026, 9, 25),
        ["Voo Emirates Business Class", "Hotel Burj Al Arab 7★", "Transfer em limousine", "Desert Safari VIP", "Jantar Burj Khalifa"],
        "O luxo absoluto do Oriente Médio: arranha-céus dourados, shopping de altíssimo padrão e experiences únicas no deserto.",
    ),
    (
        "Milão — Moda e Gastronomia",
        "Milão, Itália",
        OfferCategoria.internacional,
        5_200.00,
        6,
        date(2026, 10, 18),
        ["Voo incluso", "Hotel Design District 4★", "Tour gastronômico", "Visita Duomo e La Scala", "Personal shopper"],
        "A capital mundial da moda e do design. Da risoto ao tiramisù, de Versace a Leonardo da Vinci.",
    ),
    (
        "Praga — A Cidade Dourada",
        "Praga, Rep. Tcheca",
        OfferCategoria.internacional,
        4_100.00,
        6,
        date(2026, 8, 22),
        ["Voo incluso", "Hotel Cidade Antiga 4★", "Tour castelo de Praga", "Degustação de cerveja artesanal", "Cruzeiro no Vltava"],
        "Uma das cidades medievais mais preservadas da Europa. Torres góticas, pontes de pedra e a melhor cerveja do mundo.",
    ),
    (
        "Santorini — O Azul do Egeu",
        "Santorini, Grécia",
        OfferCategoria.lua_de_mel,
        6_500.00,
        8,
        date(2026, 9, 3),
        ["Voo incluso", "Suíte com vista para a caldera", "Passeio de catamarã", "Tour vinícola", "Jantar ao pôr do sol em Oia"],
        "Cúpulas azuis, vulcões e o mar Egeu: o pôr do sol mais famoso do mundo espera por você em Oia.",
    ),
]


async def run(session: AsyncSession) -> None:
    exists = await session.execute(select(Offer).limit(1))
    if exists.scalar_one_or_none():
        print("  [SKIP] Offers (já existem registros)")
        return

    admin = await get_admin(session)

    for titulo, destino, categoria, preco, duracao, data_saida, servicos, descricao in _OFFERS:
        session.add(
            Offer(
                titulo=titulo,
                destino=destino,
                descricao=descricao,
                categoria=categoria,
                preco_base=preco,
                servicos_inclusos=servicos,
                imagens=[
                    f"https://picsum.photos/seed/{destino.split(',')[0].lower().replace(' ', '-')}/800/600"
                ],
                data_saida_sugerida=data_saida,
                duracao_dias=duracao,
                status=OfferStatus.publicada,
                criado_por=admin.id,
            )
        )

    await session.commit()
    print(f"  [NEW]  {len(_OFFERS)} offers publicadas")


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
