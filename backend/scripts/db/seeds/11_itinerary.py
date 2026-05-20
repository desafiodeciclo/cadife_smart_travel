"""
11_itinerary — Itinerários curados para leads com agendamento 'realizado'.

Regra de negócio: itinerário existe somente quando agendamento = realizado.

  Otávio Grotto  → agendamento 2026-02-14 (realizado) → Paris 7 dias (13 itens)
  Camila Santos  → agendamento 2026-04-22 (realizado) → Tóquio 14 dias (12 itens)
  Carla Mendonça → agendamento 2026-04-10 (realizado) → Gramado 5 dias (10 itens)
  Natália Costa  → agendamento 2026-04-05 (realizado) → Portugal+Espanha 13 dias (14 itens)
  Rafael Mendes  → agendamento 2026-06-02 (confirmado) → sem itinerário
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


# ── Paris — Otávio Grotto ─────────────────────────────────────────────────────
# Viagem: 2026-03-10 a 2026-03-17 | 2 pessoas | casal | premium
# (titulo, tipo, local, endereco, horario_inicio, horario_fim, descricao, notas)

_PARIS = [
    ("Voo GRU → CDG",                   ItineraryItemType.voo,             "Aeroporto de Guarulhos (GRU) — Terminal 3",      "Rodovia Hélio Smidt, s/n, Guarulhos, SP",                        _dt(2026,3,10,22,10), _dt(2026,3,11,14, 0), "Air France AF457. Portão G12. Check-in recomendado às 19h30.", "Franquia: 2 × 23 kg. Refeição a bordo inclusa."),
    ("Traslado CDG → Hotel",             ItineraryItemType.transferencia,   "Aeroporto Charles de Gaulle (CDG) — Terminal 2E", "Route de Roissy, 95700 Roissy-en-France",                       _dt(2026,3,11,15, 0), _dt(2026,3,11,16,30), "Motorista particular com placa 'Grotto'.",                    "Mercedes Classe E. Duração ~50 min."),
    ("Check-in — Hôtel Le Marais",       ItineraryItemType.hotel_checkin,   "Hôtel Le Marais",                                "2 Rue de Bretagne, 75003 Paris",                                 _dt(2026,3,11,16,30), _dt(2026,3,17,11, 0), "Quarto Deluxe Vue Cour — 5 noites. Café incluso.",            "Wi-Fi gratuito. Confirmar early check-in."),
    ("Jantar de Boas-Vindas",            ItineraryItemType.refeicao,        "Le Comptoir du Relais",                          "9 Carrefour de l'Odéon, 75006 Paris",                            _dt(2026,3,11,20, 0), _dt(2026,3,11,22,30), "Bistrô clássico em Saint-Germain-des-Prés.",                  "Reserva no nome de Grotto."),
    ("Torre Eiffel & Trocadéro",         ItineraryItemType.passeio,         "Torre Eiffel",                                   "Champ de Mars, 5 Av. Anatole France, 75007 Paris",               _dt(2026,3,12,10, 0), _dt(2026,3,12,13, 0), "Ingressos para o 2º andar inclusos.",                         "Ingressos já comprados — sem fila."),
    ("Museu do Louvre",                  ItineraryItemType.passeio,         "Musée du Louvre",                                "Rue de Rivoli, 75001 Paris",                                     _dt(2026,3,13, 9, 0), _dt(2026,3,13,13, 0), "Visita guiada em português: Mona Lisa, Vênus de Milo.",       "Guia privativo — ponto Pirâmide de Cristal, 9h."),
    ("Almoço em Montmartre",             ItineraryItemType.refeicao,        "Le Consulat",                                    "18 Rue Norvins, 75018 Paris",                                    _dt(2026,3,13,13,30), _dt(2026,3,13,15, 0), "Restaurante histórico frequentado por Picasso.",              None),
    ("Day Trip — Versalhes",             ItineraryItemType.passeio,         "Château de Versailles",                          "Place d'Armes, 78000 Versailles",                                _dt(2026,3,14, 9, 0), _dt(2026,3,14,17, 0), "Salão dos Espelhos e Jardins. Transfer inclusos.",            "Passport Ticket incluso."),
    ("Musée d'Orsay",                    ItineraryItemType.passeio,         "Musée d'Orsay",                                  "1 Rue de la Légion d'Honneur, 75007 Paris",                      _dt(2026,3,15,10, 0), _dt(2026,3,15,13, 0), "Monet, Renoir, Degas e Van Gogh.",                            "Ingressos inclusos. Tarde livre."),
    ("Cruzeiro no Sena ao Pôr do Sol",   ItineraryItemType.passeio,         "Bateaux Parisiens — Pont de l'Alma",             "Port de la Bourdonnais, 75007 Paris",                            _dt(2026,3,16,18,30), _dt(2026,3,16,20, 0), "Cruzeiro panorâmico com champanhe.",                          "Embarque 18h15. Smart casual."),
    ("Check-out — Hôtel Le Marais",      ItineraryItemType.hotel_checkout,  "Hôtel Le Marais",                                "2 Rue de Bretagne, 75003 Paris",                                 _dt(2026,3,17,11, 0), None,                  "Bagagens podem ficar na recepção até a saída.",               "Late checkout até 12h se possível."),
    ("Traslado Hotel → CDG",             ItineraryItemType.transferencia,   "Hôtel Le Marais",                                "2 Rue de Bretagne, 75003 Paris",                                 _dt(2026,3,17,14, 0), _dt(2026,3,17,15,30), "Motorista particular — saída às 14h.",                        None),
    ("Voo CDG → GRU",                    ItineraryItemType.voo,             "Aeroporto Charles de Gaulle (CDG) — Terminal 2E", "Route de Roissy, 95700 Roissy-en-France",                       _dt(2026,3,17,17, 0), _dt(2026,3,18, 6, 0), "Air France AF458. Check-in até 14h30.",                       "Franquia: 2 × 23 kg. Refeição a bordo inclusa."),
]

# ── Tóquio — Camila Santos ─────────────────────────────────────────────────────
# Viagem: 2026-08-05 a 2026-08-19 | 4 pessoas | amigos

_TOQUIO = [
    ("Voo GRU → NRT",                    ItineraryItemType.voo,             "Aeroporto de Guarulhos (GRU) — Terminal 3",      "Rodovia Hélio Smidt, s/n, Guarulhos, SP",                        _dt(2026,8, 5,23,55), _dt(2026,8, 7,19, 0), "Qatar Airways QR775 com escala em Doha. Check-in às 20h30.", "JR Pass 14 dias embarcado."),
    ("Traslado NRT → Hotel Shinjuku",    ItineraryItemType.transferencia,   "Aeroporto Narita (NRT) — Terminal 1",            "1-1 Furugome, Narita, Chiba, Japão",                            _dt(2026,8, 7,20,30), _dt(2026,8, 7,22, 0), "Limousine Bus reservado. Ponto: saída B.",                    None),
    ("Check-in — Shinjuku Granbell",     ItineraryItemType.hotel_checkin,   "Shinjuku Granbell Hotel",                        "2-14-5 Kabukicho, Shinjuku, Tóquio",                            _dt(2026,8, 7,22, 0), _dt(2026,8,19,12, 0), "2 quartos Standard Twin — 11 noites. Check-in tardio.",       "Café opcional ¥2.000/pessoa."),
    ("Shibuya, Harajuku e Omotesando",   ItineraryItemType.passeio,         "Shibuya Scramble Crossing",                      "2-2-1 Dogenzaka, Shibuya, Tóquio",                               _dt(2026,8, 8,10, 0), _dt(2026,8, 8,18, 0), "Cruzamento mais famoso do mundo, templo Meiji, lojas grife.", "JR Pass para deslocamentos."),
    ("Akihabara & Asakusa",              ItineraryItemType.passeio,         "Akihabara Electric Town",                        "Akihabara, Chiyoda City, Tóquio",                                _dt(2026,8, 9,10, 0), _dt(2026,8, 9,17, 0), "Eletrônica, mangá e cultura pop. Tarde: templo Senso-ji.",    None),
    ("Workshop de Culinária Japonesa",   ItineraryItemType.refeicao,        "Tsukiji Cooking Class",                          "4-16-2 Tsukiji, Chuo City, Tóquio",                             _dt(2026,8,10,18, 0), _dt(2026,8,10,21, 0), "Sushi, ramen e gyoza. Jantar ao final.",                      "Opção sem frutos do mar para a Camila."),
    ("Day Trip — Kyoto",                 ItineraryItemType.passeio,         "Estação de Kyoto",                               "Shimogyo Ward, Kyoto",                                           _dt(2026,8,11, 6,30), _dt(2026,8,11,22, 0), "Shinkansen Nozomi. Fushimi Inari, Arashiyama, Gion.",         "JR Pass cobre Shinkansen."),
    ("Day Trip — Osaka",                 ItineraryItemType.passeio,         "Estação de Osaka",                               "Umeda, Kita Ward, Osaka",                                        _dt(2026,8,12, 7, 0), _dt(2026,8,12,21, 0), "Castelo de Osaka, Dotonbori, takoyaki.",                      "Levar dinheiro em yen."),
    ("Jardins Hamarikyu & Baía de Tóquio", ItineraryItemType.passeio,      "Jardins Hamarikyu",                              "1-1 Hamarikyuteien, Chuo City, Tóquio",                          _dt(2026,8,15,10, 0), _dt(2026,8,15,14, 0), "Jardim Edo + cruzeiro yakatabune pela baía.",                 "Ingresso ¥300. Cruzeiro reservado."),
    ("Check-out — Shinjuku Granbell",    ItineraryItemType.hotel_checkout,  "Shinjuku Granbell Hotel",                        "2-14-5 Kabukicho, Shinjuku, Tóquio",                            _dt(2026,8,19,12, 0), None,                  "Bagagens na recepção até saída.",                             None),
    ("Traslado Hotel → NRT",             ItineraryItemType.transferencia,   "Shinjuku Granbell Hotel",                        "2-14-5 Kabukicho, Shinjuku, Tóquio",                            _dt(2026,8,19,14, 0), _dt(2026,8,19,16, 0), "Limousine Bus Shinjuku → Narita.",                            None),
    ("Voo NRT → GRU",                    ItineraryItemType.voo,             "Aeroporto Narita (NRT) — Terminal 1",            "1-1 Furugome, Narita, Chiba, Japão",                            _dt(2026,8,19,17,30), _dt(2026,8,20, 9, 0), "Qatar Airways QR776 com escala em Doha.",                     "Declarar compras acima de US$500."),
]

# ── Gramado — Carla Mendonça ──────────────────────────────────────────────────
# Viagem: 2026-06-20 a 2026-06-25 | 2 pessoas | casal | médio

_GRAMADO = [
    ("Transfer POA → Gramado",           ItineraryItemType.transferencia,   "Aeroporto Salgado Filho (POA)",                  "Av. Severo Dullius, 90010-000, Porto Alegre, RS",                _dt(2026,6,20,14, 0), _dt(2026,6,20,16,30), "Van privativa POA → Gramado.",                                "Duração ~2h. Motorista aguarda no desembarque."),
    ("Check-in — Chalé Gramado",         ItineraryItemType.hotel_checkin,   "Chalé Gramado Premium",                          "Rua Garibaldi, 500, Gramado, RS",                                _dt(2026,6,20,16,30), _dt(2026,6,25,12, 0), "Chalé com lareira, hidromassagem e café colonial incluso.",   "Pedido especial: flores no quarto."),
    ("Café Colonial de Boas-Vindas",     ItineraryItemType.refeicao,        "Chalé Gramado Premium",                          "Rua Garibaldi, 500, Gramado, RS",                                _dt(2026,6,20,18, 0), _dt(2026,6,20,20, 0), "Café colonial com embutidos, cucas e fondue de queijo.",      None),
    ("Passeio — Centro de Gramado",      ItineraryItemType.passeio,         "Rua Coberta de Gramado",                         "Av. Borges de Medeiros, Gramado, RS",                            _dt(2026,6,21,10, 0), _dt(2026,6,21,13, 0), "Chocolaterias, lojas artesanais e a famosa Rua Coberta.",     None),
    ("Almoço — Gastronomia Regional",    ItineraryItemType.refeicao,        "Ristorante Don Giovanni",                        "Rua Garibaldi, 300, Gramado, RS",                                _dt(2026,6,21,13, 0), _dt(2026,6,21,15, 0), "Culinária italiana gaúcha de tradição.",                      "Reserva confirmada."),
    ("Tour Vinícolas — Bento Gonçalves", ItineraryItemType.passeio,         "Vale dos Vinhedos",                              "Bento Gonçalves, RS",                                            _dt(2026,6,22, 9, 0), _dt(2026,6,22,18, 0), "3 vinícolas premium: Miolo, Casa Valduga e Pizzato.",         "Transfer incluído. Degustação de 4 rótulos por vinícola."),
    ("Jantar Especial — Lua de Mel",     ItineraryItemType.refeicao,        "Michelon Gastronomia",                           "Rua Madre Verônica, 100, Gramado, RS",                           _dt(2026,6,22,20, 0), _dt(2026,6,22,23, 0), "Menu degustação especial de lua de mel com harmonização.",   "Mesa decorada com flores. Confirmado."),
    ("Parque do Caracol — Cachoeira",    ItineraryItemType.passeio,         "Parque Estadual do Caracol",                     "Canela, RS",                                                     _dt(2026,6,23,10, 0), _dt(2026,6,23,14, 0), "Cachoeira de 131m. Teleférico panorâmico incluso.",           None),
    ("Check-out — Chalé Gramado",        ItineraryItemType.hotel_checkout,  "Chalé Gramado Premium",                          "Rua Garibaldi, 500, Gramado, RS",                                _dt(2026,6,25,12, 0), None,                  "Café da manhã de despedida incluso.",                         None),
    ("Transfer Gramado → POA",           ItineraryItemType.transferencia,   "Chalé Gramado Premium",                          "Rua Garibaldi, 500, Gramado, RS",                                _dt(2026,6,25,13, 0), _dt(2026,6,25,15,30), "Van privativa Gramado → POA.",                                None),
]

# ── Portugal + Espanha — Natália Costa ────────────────────────────────────────
# Viagem: 2026-05-08 a 2026-05-21 | 2 pessoas | casal | alto

_PORTUGAL_ESPANHA = [
    ("Voo GRU → LIS",                    ItineraryItemType.voo,             "Aeroporto de Guarulhos (GRU) — Terminal 3",      "Rodovia Hélio Smidt, s/n, Guarulhos, SP",                        _dt(2026,5, 8,21,30), _dt(2026,5, 9,11,45), "TAP Portugal TP088. Check-in às 18h30.",                      "Franquia: 2 × 23 kg."),
    ("Check-in — Bairro Alto Hotel",     ItineraryItemType.hotel_checkin,   "Bairro Alto Hotel",                              "Praça Luís de Camões, 2, 1200-243 Lisboa",                       _dt(2026,5, 9,14, 0), _dt(2026,5,13,12, 0), "Suite com vista para o Tejo — 3 noites.",                     "5★. Spa incluso no pacote."),
    ("Lisboa — Belém e Alfama",          ItineraryItemType.passeio,         "Torre de Belém",                                 "Av. Brasília, 1400-038 Lisboa",                                  _dt(2026,5,10, 9, 0), _dt(2026,5,10,18, 0), "Pastéis de Belém, Torre, Mosteiro Jerônimos, tramway 28.",    "Guia privativo em português."),
    ("Fado ao Vivo em Lisboa",           ItineraryItemType.refeicao,        "Casa de Fado Tasca do Chico",                    "Rua do Diário de Notícias, 39, Lisboa",                          _dt(2026,5,11,20, 0), _dt(2026,5,11,23, 0), "Jantar com espetáculo de fado autêntico em Alfama.",          "Reserva confirmada. Roupagem casual-chic."),
    ("Day Trip — Sintra",                ItineraryItemType.passeio,         "Palácio Nacional de Sintra",                     "Largo Rainha Dona Amélia, 2710-616 Sintra",                      _dt(2026,5,12, 9, 0), _dt(2026,5,12,18, 0), "Palácio da Pena, Quinta da Regaleira e vila histórica.",      "Transfer incluído."),
    ("Trem Lisboa → Porto",              ItineraryItemType.transferencia,   "Estação Oriente, Lisboa",                        "Av. Dom João II, 1990-023 Lisboa",                               _dt(2026,5,13,10, 0), _dt(2026,5,13,13, 0), "Alfa Pendular, 1ª classe — 2h50.",                            "Passagens já incluídas no pacote."),
    ("Check-in — Infante Sagres Porto",  ItineraryItemType.hotel_checkin,   "Hotel Infante de Sagres",                        "Praça Filipa de Lencastre, 62, 4050-259 Porto",                  _dt(2026,5,13,15, 0), _dt(2026,5,16,12, 0), "Quarto Superior — 2 noites. Café incluso.",                   "Boutique histórico 5★ no centro."),
    ("Porto — Ribeira e Cave do Vinho",  ItineraryItemType.passeio,         "Cais da Ribeira, Porto",                         "Cais da Ribeira, 4050-510 Porto",                                _dt(2026,5,14,10, 0), _dt(2026,5,14,19, 0), "Cave Graham's (degustação 3 rótulos), Livraria Lello, Ribeira.", "Guia privativo."),
    ("Voo Porto → Madrid",               ItineraryItemType.voo,             "Aeroporto Francisco Sá Carneiro (OPO)",          "Rua Nelson Mandela, 4470-413 Maia, Portugal",                    _dt(2026,5,16,14, 0), _dt(2026,5,16,16, 0), "Iberia IB3141. Check-in às 12h.",                             "Voo rápido, 1h15 de duração."),
    ("Check-in — NH Collection Madrid", ItineraryItemType.hotel_checkin,   "NH Collection Madrid Gran Vía",                  "Gran Vía, 21, 28013 Madrid",                                     _dt(2026,5,16,18, 0), _dt(2026,5,20,12, 0), "Quarto Standard — 3 noites. Café incluso.",                   "Gran Via, localização perfeita."),
    ("Madrid — Prado e Retiro",          ItineraryItemType.passeio,         "Museo del Prado",                                "Paseo del Prado, s/n, 28014 Madrid",                             _dt(2026,5,17, 9, 0), _dt(2026,5,17,18, 0), "Prado (Velázquez, Goya), Parque del Buen Retiro.",            "Guia privativo de arte em português."),
    ("Day Trip — Toledo Medieval",       ItineraryItemType.passeio,         "Catedral de Toledo",                             "Calle Cardenal Cisneros, 1, 45002 Toledo",                       _dt(2026,5,18, 9, 0), _dt(2026,5,18,19, 0), "Toledo medieval: Catedral, Alcázar e cidade judaica.",        "Transfer incluído. Almoço em restaurante típico."),
    ("Check-out — NH Collection Madrid",ItineraryItemType.hotel_checkout,  "NH Collection Madrid Gran Vía",                  "Gran Vía, 21, 28013 Madrid",                                     _dt(2026,5,20,12, 0), None,                  "Bagagens disponíveis na recepção até saída.",                 None),
    ("Voo MAD → GRU",                    ItineraryItemType.voo,             "Aeroporto Adolfo Suárez Madrid-Barajas (MAD)",  "28042 Madrid, Espanha",                                          _dt(2026,5,20,15,30), _dt(2026,5,21, 5, 0), "Iberia IB6824. Check-in às 13h.",                             "Franquia: 2 × 23 kg."),
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
    admin    = await get_admin(session)
    daniela  = await get_user_by_email(session, "daniela.costa@cadifetoure.com.br")
    bruno    = await get_user_by_email(session, "bruno.ferreira@cadifetoure.com.br")

    daniela_id = daniela.id if daniela else admin.id
    bruno_id   = bruno.id   if bruno   else admin.id

    otavio_lead  = await get_lead_by_phone(session, "+5511966666666")
    camila_lead  = await get_lead_by_phone(session, "+5511955555555")
    carla_lead   = await get_lead_by_phone(session, "+5551933330006")
    natalia_lead = await get_lead_by_phone(session, "+5511911110008")

    if otavio_lead:  await _seed_itinerary(session, otavio_lead,  daniela_id, _PARIS,            "Otávio (Paris)")
    if camila_lead:  await _seed_itinerary(session, camila_lead,  daniela_id, _TOQUIO,           "Camila (Tóquio)")
    if carla_lead:   await _seed_itinerary(session, carla_lead,   daniela_id, _GRAMADO,          "Carla (Gramado)")
    if natalia_lead: await _seed_itinerary(session, natalia_lead, bruno_id,   _PORTUGAL_ESPANHA, "Natália (Portugal+Espanha)")

    # Rafael: agendamento confirmado (não realizado) — sem itinerário


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
