"""
11_itinerary — Itinerários curados pela consultora após reunião de alinhamento.

Regra de negócio: itens de itinerário só existem quando o agendamento
correspondente está em status 'realizado' (curadoria concluída).

  Otávio Grotto  → agendamento 2026-02-14 (realizado) → Paris 7 dias
  Camila Santos  → agendamento 2026-04-22 (realizado) → Tóquio 14 dias
  Rafael Mendes  → agendamento 2026-06-02 (confirmado) → sem itinerário

Mocks do Flutter cobertos:
  - client_home_mocks.dart  → mockItineraryItems() (4 itens Paris)
  - itinerary_service.dart  → GET /leads/{id}/itinerary
"""
from __future__ import annotations

import sys
from datetime import datetime, timezone
from pathlib import Path

_BACKEND = Path(__file__).resolve().parents[3]
_SEEDS = Path(__file__).resolve().parent
for _p in [str(_BACKEND), str(_SEEDS)]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import ItineraryItemType
from app.infrastructure.persistence.models.itinerary_model import ItineraryItemModel
from shared import get_admin, get_lead_by_phone, get_user_by_email


def _dt(year: int, month: int, day: int, hour: int = 12, minute: int = 0) -> datetime:
    return datetime(year, month, day, hour, minute, 0, tzinfo=timezone.utc)


# ── Paris — Otávio Grotto (lead fechado, agendamento realizado 2026-02-14) ───
# Viagem: 2026-06-15 a 2026-06-22 | 2 pessoas | casal | luxo
# (titulo, tipo, local, endereco, horario_inicio, horario_fim, descricao, notas)

_PARIS = [
    (
        "Voo GRU → CDG",
        ItineraryItemType.voo,
        "Aeroporto de Guarulhos (GRU) — Terminal 3",
        "Rodovia Hélio Smidt, s/n, Guarulhos, SP",
        _dt(2026, 6, 15, 22, 10),
        _dt(2026, 6, 16, 14, 0),
        "Air France AF457. Portão G12. Check-in recomendado às 19h30.",
        "Franquia de bagagem: 2 × 23 kg por pessoa. Refeição a bordo inclusa.",
    ),
    (
        "Traslado Aeroporto → Hotel",
        ItineraryItemType.transferencia,
        "Aeroporto Charles de Gaulle (CDG) — Terminal 2E",
        "Route de Roissy, 95700 Roissy-en-France, França",
        _dt(2026, 6, 16, 15, 0),
        _dt(2026, 6, 16, 16, 30),
        "Motorista particular aguardando no desembarque com placa 'Grotto'.",
        "Duração estimada: 45–60 min. Veículo: Mercedes Classe E.",
    ),
    (
        "Check-in — Hôtel Le Marais",
        ItineraryItemType.hotel_checkin,
        "Hôtel Le Marais",
        "2 Rue de Bretagne, 75003 Paris, França",
        _dt(2026, 6, 16, 16, 30),
        _dt(2026, 6, 22, 11, 0),
        "Reserva confirmada. Quarto Deluxe Vue Cour — 5 noites.",
        "Café da manhã incluso (7h–10h30). Wi-Fi gratuito. Confirmar early check-in se possível.",
    ),
    (
        "Jantar de Boas-Vindas",
        ItineraryItemType.refeicao,
        "Le Comptoir du Relais",
        "9 Carrefour de l'Odéon, 75006 Paris, França",
        _dt(2026, 6, 16, 20, 0),
        _dt(2026, 6, 16, 22, 30),
        "Bistrô clássico parisiense no coração de Saint-Germain-des-Prés.",
        "Reserva no nome de Grotto. Culinária francesa tradicional — Menu Dégustation recomendado.",
    ),
    (
        "Passeio — Torre Eiffel & Trocadéro",
        ItineraryItemType.passeio,
        "Torre Eiffel",
        "Champ de Mars, 5 Av. Anatole France, 75007 Paris, França",
        _dt(2026, 6, 17, 10, 0),
        _dt(2026, 6, 17, 13, 0),
        "Ingressos para o 2º andar inclusos. Tarde livre para Champs-Élysées.",
        "Ingressos já comprados — sem fila. Levar documento com foto.",
    ),
    (
        "Passeio — Museu do Louvre",
        ItineraryItemType.passeio,
        "Musée du Louvre",
        "Rue de Rivoli, 75001 Paris, França",
        _dt(2026, 6, 18, 9, 0),
        _dt(2026, 6, 18, 13, 0),
        "Visita guiada em português: Mona Lisa, Vênus de Milo e esculturas gregas.",
        "Guia privativo contratado — ponto de encontro: Pirâmide de Cristal, 9h.",
    ),
    (
        "Almoço — Montmartre",
        ItineraryItemType.refeicao,
        "Le Consulat",
        "18 Rue Norvins, 75018 Paris, França",
        _dt(2026, 6, 18, 13, 30),
        _dt(2026, 6, 18, 15, 0),
        "Restaurante histórico onde Picasso e Toulouse-Lautrec frequentavam.",
        None,
    ),
    (
        "Day Trip — Palácio de Versalhes",
        ItineraryItemType.passeio,
        "Château de Versailles",
        "Place d'Armes, 78000 Versailles, França",
        _dt(2026, 6, 19, 9, 0),
        _dt(2026, 6, 19, 17, 0),
        "Palácio, Salão dos Espelhos e Jardins. Transfer de ida e volta inclusos.",
        "Ingressos Passport incluídos (acesso completo). Refeição no jardim por conta própria.",
    ),
    (
        "Passeio — Musée d'Orsay",
        ItineraryItemType.passeio,
        "Musée d'Orsay",
        "1 Rue de la Légion d'Honneur, 75007 Paris, França",
        _dt(2026, 6, 20, 10, 0),
        _dt(2026, 6, 20, 13, 0),
        "Impressionismo francês: Monet, Renoir, Degas e Van Gogh.",
        "Ingressos já inclusos. Tarde livre para compras em Saint-Germain.",
    ),
    (
        "Passeio de Barco — Rio Sena ao Pôr do Sol",
        ItineraryItemType.passeio,
        "Bateaux Parisiens — Pont de l'Alma",
        "Port de la Bourdonnais, 75007 Paris, França",
        _dt(2026, 6, 21, 18, 30),
        _dt(2026, 6, 21, 20, 0),
        "Cruzeiro panorâmico com champanhe ao pôr do sol.",
        "Embarque 18h15. Dress code: smart casual.",
    ),
    (
        "Check-out — Hôtel Le Marais",
        ItineraryItemType.hotel_checkout,
        "Hôtel Le Marais",
        "2 Rue de Bretagne, 75003 Paris, França",
        _dt(2026, 6, 22, 11, 0),
        None,
        "Bagagens podem ser deixadas na recepção até a saída.",
        "Solicitar late checkout até 12h se possível.",
    ),
    (
        "Traslado Hotel → Aeroporto CDG",
        ItineraryItemType.transferencia,
        "Hôtel Le Marais",
        "2 Rue de Bretagne, 75003 Paris, França",
        _dt(2026, 6, 22, 14, 0),
        _dt(2026, 6, 22, 15, 30),
        "Motorista particular — saída do hotel às 14h em ponto.",
        None,
    ),
    (
        "Voo CDG → GRU",
        ItineraryItemType.voo,
        "Aeroporto Charles de Gaulle (CDG) — Terminal 2E",
        "Route de Roissy, 95700 Roissy-en-France, França",
        _dt(2026, 6, 22, 17, 0),
        _dt(2026, 6, 23, 6, 0),
        "Air France AF458. Check-in até 14h30.",
        "Franquia de bagagem: 2 × 23 kg. Refeição a bordo inclusa.",
    ),
]

# ── Tóquio — Camila Santos (lead proposta, agendamento realizado 2026-04-22) ─
# Viagem: 2026-07-10 a 2026-07-24 | 4 pessoas | amigos | urbano/aventura

_TOQUIO = [
    (
        "Voo GRU → NRT",
        ItineraryItemType.voo,
        "Aeroporto de Guarulhos (GRU) — Terminal 3",
        "Rodovia Hélio Smidt, s/n, Guarulhos, SP",
        _dt(2026, 7, 10, 23, 55),
        _dt(2026, 7, 12, 19, 0),
        "Qatar Airways QR775 com escala em Doha (DOH). Check-in às 20h30.",
        "JR Pass 14 dias embarcado — apresentar na chegada. Franquia: 2 × 23 kg.",
    ),
    (
        "Traslado NRT → Hotel Shinjuku",
        ItineraryItemType.transferencia,
        "Aeroporto Narita (NRT) — Terminal 1",
        "1-1 Furugome, Narita, Chiba 282-0004, Japão",
        _dt(2026, 7, 12, 20, 30),
        _dt(2026, 7, 12, 22, 0),
        "Limousine Bus reservado (Narita → Shinjuku). Ponto de embarque: saída B.",
        None,
    ),
    (
        "Check-in — Shinjuku Granbell Hotel",
        ItineraryItemType.hotel_checkin,
        "Shinjuku Granbell Hotel",
        "2-14-5 Kabukicho, Shinjuku, Tóquio, Japão",
        _dt(2026, 7, 12, 22, 0),
        _dt(2026, 7, 24, 12, 0),
        "2 quartos Standard Twin — 11 noites. Check-in tardio confirmado.",
        "Café da manhã opcional (¥2.000/pessoa). Próximo ao metrô Shinjuku.",
    ),
    (
        "Passeio — Shibuya, Harajuku e Omotesando",
        ItineraryItemType.passeio,
        "Shibuya Scramble Crossing",
        "2 Chome-2-1 Dogenzaka, Shibuya City, Tóquio, Japão",
        _dt(2026, 7, 13, 10, 0),
        _dt(2026, 7, 13, 18, 0),
        "Cruzamento mais famoso do mundo, templo Meiji, lojas de grife em Omotesando.",
        "Usar JR Pass para deslocamentos. App Suica recomendado.",
    ),
    (
        "Passeio — Akihabara & Asakusa",
        ItineraryItemType.passeio,
        "Akihabara Electric Town",
        "Akihabara, Chiyoda City, Tóquio, Japão",
        _dt(2026, 7, 14, 10, 0),
        _dt(2026, 7, 14, 17, 0),
        "Paraíso da eletrônica, mangá e cultura pop. Tarde: templo Senso-ji em Asakusa.",
        None,
    ),
    (
        "Workshop de Culinária Japonesa",
        ItineraryItemType.refeicao,
        "Tsukiji Cooking Class",
        "4-16-2 Tsukiji, Chuo City, Tóquio, Japão",
        _dt(2026, 7, 15, 18, 0),
        _dt(2026, 7, 15, 21, 0),
        "Aula de sushi, ramen e gyoza com chef local. Inclui jantar ao final.",
        "Produto sem frutos do mar disponível para Camila — confirmar na chegada.",
    ),
    (
        "Day Trip — Kyoto (Templos e Gueixas)",
        ItineraryItemType.passeio,
        "Estação de Kyoto",
        "Higashishiokoji Kamadonocho, Shimogyo Ward, Kyoto, Japão",
        _dt(2026, 7, 16, 6, 30),
        _dt(2026, 7, 16, 22, 0),
        "Shinkansen Nozomi (45 min). Fushimi Inari, Arashiyama, Gion Shijo ao entardecer.",
        "JR Pass cobre Shinkansen. Aluguel de quimono em Gion por conta própria.",
    ),
    (
        "Day Trip — Osaka (Gastronomia e Castelo)",
        ItineraryItemType.passeio,
        "Estação de Osaka",
        "3 Chome-1-1 Umeda, Kita Ward, Osaka, Japão",
        _dt(2026, 7, 17, 7, 0),
        _dt(2026, 7, 17, 21, 0),
        "Castelo de Osaka, Dotonbori, takoyaki e okonomiyaki — a capital da gastronomia japonesa.",
        "JR Pass cobre a viagem. Levar dinheiro em yen (muitos locais não aceitam cartão).",
    ),
    (
        "Passeio — Hamarikyu & Cruzeiro pela Baía de Tóquio",
        ItineraryItemType.passeio,
        "Jardins Hamarikyu",
        "1-1 Hamarikyuteien, Chuo City, Tóquio, Japão",
        _dt(2026, 7, 20, 10, 0),
        _dt(2026, 7, 20, 14, 0),
        "Jardim tradicional do período Edo. Cruzeiro de yakatabune pela baía ao meio-dia.",
        "Ingresso do jardim: ¥300. Cruzeiro: reservado — embarque às 11h30.",
    ),
    (
        "Check-out — Shinjuku Granbell Hotel",
        ItineraryItemType.hotel_checkout,
        "Shinjuku Granbell Hotel",
        "2-14-5 Kabukicho, Shinjuku, Tóquio, Japão",
        _dt(2026, 7, 24, 12, 0),
        None,
        "Bagagens podem ficar na recepção até a saída para o aeroporto.",
        None,
    ),
    (
        "Traslado Hotel → Aeroporto NRT",
        ItineraryItemType.transferencia,
        "Shinjuku Granbell Hotel",
        "2-14-5 Kabukicho, Shinjuku, Tóquio, Japão",
        _dt(2026, 7, 24, 14, 0),
        _dt(2026, 7, 24, 16, 0),
        "Limousine Bus reservado (Shinjuku → Narita). Saída às 14h em ponto.",
        None,
    ),
    (
        "Voo NRT → GRU",
        ItineraryItemType.voo,
        "Aeroporto Narita (NRT) — Terminal 1",
        "1-1 Furugome, Narita, Chiba 282-0004, Japão",
        _dt(2026, 7, 24, 17, 30),
        _dt(2026, 7, 25, 9, 0),
        "Qatar Airways QR776 com escala em Doha. Check-in até 14h30.",
        "Franquia: 2 × 23 kg. Lembrar de declarar compras acima de US$500 na alfândega.",
    ),
]


async def _seed_itinerary(session, lead, consultor_id, items, label):
    exists = await session.execute(
        select(ItineraryItemModel)
        .where(ItineraryItemModel.lead_id == lead.id)
        .limit(1)
    )
    if exists.scalar_one_or_none():
        print(f"  [SKIP] Itinerary {label}")
        return

    for titulo, tipo, local, endereco, inicio, fim, descricao, notas in items:
        session.add(
            ItineraryItemModel(
                lead_id=lead.id,
                criado_por=consultor_id,
                tipo=tipo.value,
                titulo=titulo,
                descricao=descricao,
                local=local,
                endereco=endereco,
                horario_inicio=inicio,
                horario_fim=fim,
                notas=notas,
            )
        )

    await session.commit()
    print(f"  [NEW]  {len(items)} itens de itinerário → {label}")


async def run(session: AsyncSession) -> None:
    admin = await get_admin(session)
    daniela = await get_user_by_email(session, "daniela.costa@cadifetoure.com.br")
    consultor_id = daniela.id if daniela else admin.id

    otavio_lead = await get_lead_by_phone(session, "+5511966666666")
    camila_lead = await get_lead_by_phone(session, "+5511955555555")

    if otavio_lead:
        await _seed_itinerary(session, otavio_lead, consultor_id, _PARIS, "Otávio (Paris)")

    if camila_lead:
        await _seed_itinerary(session, camila_lead, consultor_id, _TOQUIO, "Camila (Tóquio)")

    # Rafael: agendamento ainda confirmado (não realizado) — sem itinerário


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
