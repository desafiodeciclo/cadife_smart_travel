"""
06_interacoes — Histórico de conversas cliente↔AYA para os 3 leads principais.
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

from app.domain.entities.enums import TipoMensagem
from app.models.interacao import Interacao
from shared import get_lead_by_phone

# (mensagem_cliente, mensagem_ia)
_PARIS = [
    (
        "Olá! Quero planejar uma viagem especial para Paris com minha esposa.",
        "Que maravilha! Paris é um destino inesquecível! Para te ajudar a criar a "
        "experiência perfeita, me conta: qual período vocês pensam em viajar? "
        "E qual o estilo — algo mais romântico, cultural ou os dois?",
    ),
    (
        "Queremos ir em março, algo bem romântico. É nosso aniversário de casamento!",
        "Que lindo! Março é perfeito para Paris — o frio suave e as ruas menos cheias "
        "criam uma atmosfera muito especial. Quantas pessoas serão? Somente vocês dois?",
    ),
    (
        "Só nós dois. Temos passaporte válido e queremos um hotel no centro mesmo.",
        "Perfeito! Dois adultos, passaporte em mãos — ótimo! Para um roteiro no coração "
        "de Paris com atmosfera romântica, qual o perfil de investimento que vocês "
        "planejam? Econômico, conforto, alto padrão ou luxo?",
    ),
    (
        "Luxo mesmo! É uma ocasião especial.",
        "Entendido! Já tenho tudo que preciso para montar um roteiro incrível para vocês. "
        "Nossa consultora Daniela entrará em contato em breve para apresentar opções "
        "exclusivas de hotéis 5 estrelas e experiências únicas em Paris!",
    ),
]

_TOQUIO = [
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
        "Anotado sobre a alergia — muito importante! O Japão tem opções incríveis sem "
        "frutos do mar. Para 4 pessoas com 14 dias, qual o perfil de investimento? "
        "Econômico, intermediário ou alto padrão?",
    ),
    (
        "Alto padrão! Já economizamos bastante para essa viagem.",
        "Maravilha! Com alto padrão em 14 dias para o Japão, nossa consultora vai montar "
        "um roteiro exclusivo. Vou conectar vocês com a Daniela em breve!",
    ),
]

_NOVA_YORK = [
    (
        "Olá! Quero levar minha família para Nova York.",
        "Que destino incrível! Nova York tem algo para todos — desde shows da Broadway "
        "até o Central Park. Me conta: quantas pessoas serão na viagem?",
    ),
    (
        "4 pessoas, 2 adultos e 2 crianças de 8 e 12 anos. Queremos ir em julho.",
        "Família incrível! Julho é excelente para Nova York. As crianças vão adorar! "
        "Vocês têm passaporte? E já pensaram em quantos dias querem ficar?",
    ),
    (
        "10 dias. Passaporte... preciso verificar.",
        "Perfeito, 10 dias é um tempo ótimo! Sobre os passaportes, é bom verificar logo "
        "pois pode levar algum tempo para tirar/renovar. Qual o perfil de investimento "
        "para a família?",
    ),
]


async def run(session: AsyncSession) -> None:
    otavio = await get_lead_by_phone(session, "+5511966666666")
    camila = await get_lead_by_phone(session, "+5511955555555")
    rafael = await get_lead_by_phone(session, "+5511944444444")

    agenda = [
        (otavio, _PARIS),
        (camila, _TOQUIO),
        (rafael, _NOVA_YORK),
    ]

    for lead, messages in agenda:
        if not lead:
            continue
        exists = await session.execute(
            select(Interacao).where(Interacao.lead_id == lead.id).limit(1)
        )
        if exists.scalar_one_or_none():
            print(f"  [SKIP] Interações lead {lead.id}")
            continue
        for cliente_msg, ia_msg in messages:
            session.add(
                Interacao(
                    lead_id=lead.id,
                    mensagem_cliente=cliente_msg,
                    mensagem_ia=ia_msg,
                    tipo_mensagem=TipoMensagem.texto,
                    status_envio="sent",
                )
            )
        print(f"  [NEW]  {len(messages)} interações → lead {lead.id}")

    await session.commit()


if __name__ == "__main__":
    from shared import run_standalone
    run_standalone(run)
