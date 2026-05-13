"""
06_interacoes — Histórico de conversas cliente↔AYA para todos os 7 leads.

Cobertura:
  Otávio Grotto   → 4 trocas (Paris, qualificado → fechado)
  Camila Santos   → 4 trocas (Tóquio, qualificado → proposta)
  Rafael Mendes   → 3 trocas (Nova York, em progresso)
  Fernanda Castro → 5 trocas (Lisboa/Porto, qualificada)
  Ana Luiza Gomes → 5 trocas (Buenos Aires/Bariloche, qualificada)
  Maria Oliveira  → 4 trocas (Cancún, em_atendimento)
  João Silva      → 2 trocas (Europa vaga, lead novo)
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

_FERNANDA = [
    (
        "Oi! Eu e duas amigas queremos ir a Portugal em setembro para comemorar nossos 30 anos!",
        "Que ideia linda! Portugal em setembro é perfeito — tempo ótimo, menos turistas e "
        "preços mais acessíveis. Lisboa e Porto são o combo ideal para quem quer explorar "
        "história, gastronomia e cultura. Quantos dias vocês estão pensando em ficar?",
    ),
    (
        "Umas 2 semanas, mais ou menos. Queremos aproveitar bastante!",
        "14 dias é o tempo ideal para curtir Lisboa, Porto e ainda fazer algum day trip "
        "para Sintra ou Douro! Vocês têm passaporte em dia? E já têm datas específicas "
        "em setembro ou ainda são flexíveis?",
    ),
    (
        "Passaporte tenho sim! Pensamos em partir dia 12 de setembro.",
        "Ótimo! 12 de setembro, vocês 3 com passaporte em mãos — perfeito. Para montar "
        "o roteiro mais incrível, me conta: o estilo da turma é mais cultural (museus, "
        "monumentos), gastronômico (restaurantes, vinhos, petiscos) ou um mix dos dois?",
    ),
    (
        "Mix total! Adoramos museus mas também queremos comer bem e ouvir fado ao vivo.",
        "Ah, vão se apaixonar por Portugal! Fado, pastéis de Belém, vinho do Porto e "
        "monumentos do século XV — tudo junto! Para garantir hotéis boutique históricos "
        "no centro, qual o perfil de investimento do grupo? Econômico, intermediário ou "
        "alto padrão?",
    ),
    (
        "Alto padrão! Estamos economizando há um ano para essa viagem especial.",
        "Maravilha! Com alto padrão e 14 dias, vou preparar um roteiro exclusivo com "
        "hotéis boutique históricos, restaurantes premiados e experiências autênticas. "
        "Nossa consultora Fernanda já tem suas informações completas e vai entrar em "
        "contato em breve para apresentar as opções!",
    ),
]

_ANA_LUIZA = [
    (
        "Olá! Estou planejando minha lua de mel e pensei em Buenos Aires + Bariloche. É possível?",
        "Que combinação perfeita para uma lua de mel! Buenos Aires encanta com sua "
        "energia cosmopolita, gastronomia incrível e tango. E Bariloche oferece lagos "
        "turquesa, montanhas nevadas e chocolates irresistíveis. Quando vocês pretendem viajar?",
    ),
    (
        "Outubro seria ideal! Estávamos pensando em uns 10 dias.",
        "Outubro é excelente para os dois destinos — primavera argentina, flores, menos "
        "frio em Bariloche. 10 dias dá pra fazer 4 em Buenos Aires e 5 em Bariloche "
        "com conforto. Vocês dois têm passaporte válido?",
    ),
    (
        "Temos sim! Queríamos algo bem especial, sabe? É nossa lua de mel.",
        "Com certeza será inesquecível! Para uma lua de mel, penso em hotel com vista "
        "para o lago em Bariloche, jantar privê com fondue e champanhe, e em Buenos "
        "Aires uma aula de tango privativa e um restaurante premiado. Qual o perfil de "
        "investimento que vocês planejaram para essa viagem especial?",
    ),
    (
        "Luxo! Queremos o melhor. Já juntamos bastante para isso.",
        "Perfeito! Com padrão premium posso montar algo verdadeiramente especial — "
        "hotel de charme boutique em cada destino, experiências exclusivas e surpresas "
        "romanticas planejadas pela nossa consultora. Vocês têm preferência por "
        "atividades: mais aventura (trilhas, rafting) ou mais contemplativo (vinícolas, "
        "spa, passeios de barco)?",
    ),
    (
        "Os dois! Queremos trilhar durante o dia e relaxar à noite com um bom vinho.",
        "Combinação perfeita para um casal aventureiro e romântico! Já tenho tudo que "
        "preciso para montar um roteiro dos sonhos. Nossa consultora Marcos vai entrar "
        "em contato em breve com opções exclusivas para a lua de mel de vocês!",
    ),
]

_MARIA = [
    (
        "Olá! Quero ir ao Cancún em dezembro com meu marido, temos filhos não, só nós dois.",
        "Que destino maravilhoso para o casal! Cancún em dezembro tem clima perfeito — "
        "sol, mar turquesa e a brisa do Caribe. Vocês têm data específica em mente? "
        "E quantas noites pretendem ficar?",
    ),
    (
        "Queremos partir dia 20 de dezembro, umas 8 noites. Preferimos all inclusive.",
        "Perfeito! 20 de dezembro a 28, 2 pessoas em resort all inclusive — anotado! "
        "Cancún tem opções excelentes de all inclusive para casais. Vocês têm passaporte "
        "válido? E há alguma preferência — resort mais intimista, família ou aquele "
        "estilo 'a animação nunca para'?",
    ),
    (
        "Passaporte precisa verificar... acho que está vencido. Queremos algo mais tranquilo.",
        "Entendido! Resort mais intimista e tranquilo é ótimo para relaxar. Sobre o "
        "passaporte, é importante resolver logo pois os prazos de emissão podem levar "
        "algumas semanas. Para garantir o resort ideal para o casal, qual o perfil de "
        "investimento que vocês planejaram?",
    ),
    (
        "Algo intermediário, não precisa ser o mais caro mas queremos conforto.",
        "Ótima escolha! Existem resorts intermediários em Cancún com ótimo custo-benefício "
        "— piscinas lindas, praia privatitiva, buffet variado e entretenimento noturno. "
        "Nossa consultora vai entrar em contato para apresentar as melhores opções "
        "disponíveis para dezembro!",
    ),
]

_JOAO = [
    (
        "Oi, vim pelo anúncio. Quero viajar para a Europa mas ainda não decidi para onde.",
        "Olá, João! Que emocionante planejar uma viagem à Europa! Temos destinos "
        "incríveis: Portugal, Espanha, Itália, França... Para te ajudar a escolher, "
        "me conta: você viajaria sozinho ou com alguém? E o que mais te atrai — "
        "história e cultura, gastronomia, natureza ou um mix?",
    ),
    (
        "Talvez com amigos, mas ainda não decidi. Gosto de cultura e gastronomia. Portugal ou Espanha parecem interessantes.",
        "Ótima pedida! Portugal e Espanha são destinos incríveis e complementares — "
        "dá pra fazer os dois num único roteiro! Para ajudar a definir melhor, "
        "você tem alguma janela de datas em mente ou ainda está em fase de pesquisa? "
        "E quantos dias aproximadamente tem disponível para a viagem?",
    ),
]


async def run(session: AsyncSession) -> None:
    otavio = await get_lead_by_phone(session, "+5511966666666")
    camila = await get_lead_by_phone(session, "+5511955555555")
    rafael = await get_lead_by_phone(session, "+5511944444444")
    fernanda = await get_lead_by_phone(session, "+5511877777777")
    ana_luiza = await get_lead_by_phone(session, "+5511866666666")
    maria = await get_lead_by_phone(session, "+5511888888888")
    joao = await get_lead_by_phone(session, "+5511999999999")

    agenda = [
        (otavio, _PARIS),
        (camila, _TOQUIO),
        (rafael, _NOVA_YORK),
        (fernanda, _FERNANDA),
        (ana_luiza, _ANA_LUIZA),
        (maria, _MARIA),
        (joao, _JOAO),
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
