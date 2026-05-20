"""
06_interacoes — Histórico de conversas cliente↔AYA para todos os 20 leads.

Cobertura (novas):
  Isabela Rocha    → 4 trocas (Orlando, família)
  Carla Mendonça   → 4 trocas (Gramado, romântico)
  Pedro Alves      → 4 trocas (Egito, casal aventureiro)
  Thiago Martins   → 3 trocas (Itália, cultural)
  Luciana Ferreira → 5 trocas (Grécia+Croácia, casal)
  Priscila Oliveira→ 4 trocas (Bali, bem-estar)
  Gabriel Nogueira → 4 trocas (Austrália, aventura)
  Sérgio Lima      → 4 trocas (Cancún, all inclusive)
  Natália Costa    → 5 trocas (Portugal+Espanha, cultural)
  Amanda Ribeiro   → 3 trocas (Dubai, luxo — parcial)
  Roberto Carvalho → 2 trocas (Lisboa — lead frio)
  Felipe Souza     → 2 trocas (genérico — novo)
  Eduardo Pinheiro → 1 troca  (Europa — lead perdido)
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

# ── conversas originais ────────────────────────────────────────────────────────

_PARIS = [
    ("Olá! Quero planejar uma viagem especial para Paris com minha esposa.",
     "Que maravilha! Paris é um destino inesquecível! Para te ajudar a criar a experiência perfeita, me conta: qual período vocês pensam em viajar? E qual o estilo — algo mais romântico, cultural ou os dois?"),
    ("Queremos ir em março, algo bem romântico. É nosso aniversário de casamento!",
     "Que lindo! Março é perfeito para Paris — o frio suave e as ruas menos cheias criam uma atmosfera muito especial. Quantas pessoas serão? Somente vocês dois?"),
    ("Só nós dois. Temos passaporte válido e queremos um hotel no centro mesmo.",
     "Perfeito! Dois adultos, passaporte em mãos — ótimo! Para um roteiro no coração de Paris com atmosfera romântica, qual o perfil de investimento que vocês planejam? Econômico, conforto, alto padrão ou luxo?"),
    ("Luxo mesmo! É uma ocasião especial.",
     "Entendido! Já tenho tudo que preciso para montar um roteiro incrível para vocês. Nossa consultora Daniela entrará em contato em breve para apresentar opções exclusivas de hotéis 5 estrelas e experiências únicas em Paris!"),
]

_TOQUIO = [
    ("Oi! Somos 4 amigas querendo ir ao Japão em agosto!",
     "Que aventura incrível! O Japão em agosto é animadíssimo — tem festivais tradicionais e a natureza exuberante. Vocês têm datas definidas? E qual cidade principal querem explorar?"),
    ("Tóquio principal, mas queremos conhecer Kyoto também. Ficamos em agosto.",
     "Tóquio + Kyoto é o combo perfeito! Dá pra fazer um roteiro fantástico em 2 semanas. Qual o perfil da turma — aventura, gastronomia, compras, templos?"),
    ("Tudo isso! Mas principalmente gastronomia e aventura. Uma de nós tem alergia a frutos do mar.",
     "Anotado sobre a alergia — muito importante! O Japão tem opções incríveis sem frutos do mar. Para 4 pessoas com 14 dias, qual o perfil de investimento? Econômico, intermediário ou alto padrão?"),
    ("Alto padrão! Já economizamos bastante para essa viagem.",
     "Maravilha! Com alto padrão em 14 dias para o Japão, nossa consultora vai montar um roteiro exclusivo. Vou conectar vocês com a Daniela em breve!"),
]

_NOVA_YORK = [
    ("Olá! Quero levar minha família para Nova York.",
     "Que destino incrível! Nova York tem algo para todos — desde shows da Broadway até o Central Park. Me conta: quantas pessoas serão na viagem?"),
    ("4 pessoas, 2 adultos e 2 crianças de 8 e 12 anos. Queremos ir em julho.",
     "Família incrível! Julho é excelente para Nova York. As crianças vão adorar! Vocês têm passaporte? E já pensaram em quantos dias querem ficar?"),
    ("10 dias. Passaporte... preciso verificar.",
     "Perfeito, 10 dias é um tempo ótimo! Sobre os passaportes, é bom verificar logo pois pode levar algum tempo para tirar/renovar. Qual o perfil de investimento para a família?"),
]

_FERNANDA = [
    ("Oi! Eu e duas amigas queremos ir a Portugal em setembro para comemorar nossos 30 anos!",
     "Que ideia linda! Portugal em setembro é perfeito — tempo ótimo, menos turistas e preços mais acessíveis. Lisboa e Porto são o combo ideal para quem quer explorar história, gastronomia e cultura. Quantos dias vocês estão pensando em ficar?"),
    ("Umas 2 semanas, mais ou menos. Queremos aproveitar bastante!",
     "14 dias é o tempo ideal para curtir Lisboa, Porto e ainda fazer algum day trip para Sintra ou Douro! Vocês têm passaporte em dia? E já têm datas específicas em setembro ou ainda são flexíveis?"),
    ("Passaporte tenho sim! Pensamos em partir dia 12 de setembro.",
     "Ótimo! 12 de setembro, vocês 3 com passaporte em mãos — perfeito. Para montar o roteiro mais incrível, me conta: o estilo da turma é mais cultural (museus, monumentos), gastronômico (restaurantes, vinhos, petiscos) ou um mix dos dois?"),
    ("Mix total! Adoramos museus mas também queremos comer bem e ouvir fado ao vivo.",
     "Ah, vão se apaixonar por Portugal! Fado, pastéis de Belém, vinho do Porto e monumentos do século XV — tudo junto! Para garantir hotéis boutique históricos no centro, qual o perfil de investimento do grupo?"),
    ("Alto padrão! Estamos economizando há um ano para essa viagem especial.",
     "Maravilha! Com alto padrão e 14 dias, vou preparar um roteiro exclusivo com hotéis boutique históricos, restaurantes premiados e experiências autênticas. Nossa consultora Diego já tem suas informações completas e vai entrar em contato em breve!"),
]

_ANA_LUIZA = [
    ("Olá! Estou planejando minha lua de mel e pensei em Buenos Aires + Bariloche. É possível?",
     "Que combinação perfeita para uma lua de mel! Buenos Aires encanta com sua energia cosmopolita, gastronomia incrível e tango. E Bariloche oferece lagos turquesa, montanhas nevadas e chocolates irresistíveis. Quando vocês pretendem viajar?"),
    ("Outubro seria ideal! Estávamos pensando em uns 10 dias.",
     "Outubro é excelente para os dois destinos — primavera argentina, flores, menos frio em Bariloche. 10 dias dá pra fazer 4 em Buenos Aires e 5 em Bariloche com conforto. Vocês dois têm passaporte válido?"),
    ("Temos sim! Queríamos algo bem especial, sabe? É nossa lua de mel.",
     "Com certeza será inesquecível! Para uma lua de mel, penso em hotel com vista para o lago em Bariloche, jantar privê com fondue e champanhe, e em Buenos Aires uma aula de tango privativa e um restaurante premiado. Qual o perfil de investimento?"),
    ("Luxo! Queremos o melhor. Já juntamos bastante para isso.",
     "Perfeito! Com padrão premium posso montar algo verdadeiramente especial — hotel de charme boutique em cada destino, experiências exclusivas e surpresas românticas planejadas pela nossa consultora. Vocês preferem mais aventura (trilhas, rafting) ou contemplativo (vinícolas, spa)?"),
    ("Os dois! Queremos trilhar durante o dia e relaxar à noite com um bom vinho.",
     "Combinação perfeita para um casal aventureiro e romântico! Já tenho tudo que preciso para montar um roteiro dos sonhos. Nossa consultora Marcos vai entrar em contato em breve com opções exclusivas para a lua de mel de vocês!"),
]

_MARIA = [
    ("Olá! Quero ir ao Cancún em dezembro com meu marido, só nós dois.",
     "Que destino maravilhoso para o casal! Cancún em dezembro tem clima perfeito — sol, mar turquesa e a brisa do Caribe. Vocês têm data específica em mente? E quantas noites pretendem ficar?"),
    ("Queremos partir dia 20 de dezembro, umas 8 noites. Preferimos all inclusive.",
     "Perfeito! 20 de dezembro a 28, 2 pessoas em resort all inclusive — anotado! Cancún tem opções excelentes de all inclusive para casais. Vocês têm passaporte válido? E há alguma preferência — resort mais intimista, família ou aquele estilo 'a animação nunca para'?"),
    ("Passaporte precisa verificar... acho que está vencido. Queremos algo mais tranquilo.",
     "Entendido! Resort mais intimista e tranquilo é ótimo para relaxar. Sobre o passaporte, é importante resolver logo pois os prazos de emissão podem levar algumas semanas. Para garantir o resort ideal para o casal, qual o perfil de investimento?"),
    ("Algo intermediário, não precisa ser o mais caro mas queremos conforto.",
     "Ótima escolha! Existem resorts intermediários em Cancún com ótimo custo-benefício — piscinas lindas, praia privativa, buffet variado e entretenimento noturno. Nossa consultora vai entrar em contato para apresentar as melhores opções disponíveis para dezembro!"),
]

_JOAO = [
    ("Oi, vim pelo anúncio. Quero viajar para a Europa mas ainda não decidi para onde.",
     "Olá, João! Que emocionante planejar uma viagem à Europa! Temos destinos incríveis: Portugal, Espanha, Itália, França... Para te ajudar a escolher, me conta: você viajaria sozinho ou com alguém? E o que mais te atrai — história e cultura, gastronomia, natureza ou um mix?"),
    ("Talvez com amigos, mas ainda não decidi. Gosto de cultura e gastronomia. Portugal ou Espanha parecem interessantes.",
     "Ótima pedida! Portugal e Espanha são destinos incríveis e complementares — dá pra fazer os dois num único roteiro! Para ajudar a definir melhor, você tem alguma janela de datas em mente ou ainda está em fase de pesquisa? E quantos dias aproximadamente tem disponível?"),
]

# ── novas conversas ────────────────────────────────────────────────────────────

_ISABELA = [
    ("Oi! Quero levar minha família para a Disney em Orlando!",
     "Que sonho de viagem! Orlando é incrível para famílias — a Disney World, Universal Studios e muito mais! Me conta: quantas pessoas vão na viagem? Tem crianças? E qual época do ano vocês preferem?"),
    ("Somos 4: eu, meu marido e duas filhas de 10 e 14 anos. Queremos ir em julho.",
     "Família perfeita para Orlando! Julho é a alta temporada, mas o clima é excelente. Passaportes em dia? E além da Disney, vocês querem incluir Universal Studios ou outros parques?"),
    ("Passaporte temos todos! Queremos Disney + Universal sim. Talvez as meninas queiram fazer compras também.",
     "Ótimo! Com 4 passaportes e interesse em Disney + Universal + compras, um roteiro de 13 dias seria ideal — dá para curtir tudo com calma sem correria. Qual o perfil de investimento da família? Econômico, conforto ou alto padrão?"),
    ("Alto padrão! É a viagem dos sonhos das meninas. Nada de economizar aqui.",
     "Maravilha! Com alto padrão em Orlando, posso incluir Disney Resort, Park Hopper Pass, jantar no Be Our Guest e muito mais. Nossa consultora Daniela vai montar o roteiro dos sonhos para vocês!"),
]

_CARLA = [
    ("Oi! Eu e meu marido queremos fazer uma lua de mel nacional. Pensamos em Gramado.",
     "Que escolha encantadora! Gramado e Canela têm um charme europeu único no Brasil — chocolates, fondue, natureza exuberante e aquela atmosfera romântica incomparável. Vocês já têm datas em mente?"),
    ("Queremos ir em junho, uns 5 dias. Seria nossa lua de mel.",
     "Junho é perfeito para Gramado — o frio, as chaminés acesas e os festivais criam um clima verdadeiramente especial para uma lua de mel. Para 2 pessoas em 5 dias, o que vocês priorizam: chalé com lareira, degustação de vinhos, culinária local?"),
    ("Tudo isso! Queremos chalé romântico, vinhos e boa gastronomia.",
     "Perfeito! Já imagino um chalé boutique com lareira e hidromassagem, café colonial completo, jantar especial e tour pelas vinícolas premium da região. Para garantir a melhor experiência, qual o perfil de investimento? Conforto, alto padrão?"),
    ("Intermediário a alto. Queremos qualidade mas sem exageros.",
     "Ótima escolha! Existe um equilíbrio perfeito entre conforto e experiências únicas em Gramado nessa faixa. Nossa consultora Daniela tem os chalés e restaurantes ideais para a lua de mel de vocês!"),
]

_PEDRO = [
    ("Olá! Sempre sonhei em conhecer o Egito — as pirâmides, o Nilo... É possível?",
     "Que sonho magnífico! O Egito é uma das experiências mais transformadoras do mundo — pirâmides de 4.500 anos, templos faraônicos, o Nilo majestoso e o caótico e fascinante Cairo. Vocês viajariam em casal, família ou grupo?"),
    ("Eu e minha esposa. Queremos ir em outubro.",
     "Outubro é excelente para o Egito — o calor já está mais ameno, especialmente no Sul. Para um casal com interesse em história e aventura, o combo Cairo + Cruzeiro no Nilo até Luxor é clássico e inesquecível. Vocês têm passaporte?"),
    ("Temos sim! Quanto tempo precisaríamos? Nunca fomos ao Egito.",
     "Para uma primeira vez sem pressa, sugiro 11 a 12 dias: 3 dias no Cairo (pirâmides, Esfinge, museu egípcio), cruzeiro 4 noites Cairo↔Luxor, e 2 dias em Luxor (Vale dos Reis, Templo de Karnak). Qual o perfil de investimento para vocês?"),
    ("Algo intermediário. Queremos conforto sem gastar uma fortuna.",
     "Ótimo! O Egito tem excelentes hotéis e cruzeiros de médio-alto padrão com ótimo custo-benefício. Nossa consultora Patricia vai montar um roteiro incrível com todas as maravilhas do mundo antigo!"),
]

_THIAGO = [
    ("Oi! Minha esposa e eu queremos visitar a Itália — Roma, Florença e Veneza.",
     "Que roteiro clássico e absolutamente deslumbrante! Itália é um dos destinos mais ricos do mundo em arte, história e gastronomia. Vocês têm preferência por alguma época do ano?"),
    ("Setembro. Somos apaixonados por arte renascentista e gastronomia italiana.",
     "Setembro é perfeito para a Itália — clima agradável e menos turistas do que julho/agosto. Para um casal apaixonado por arte e gastronomia, 13 dias distribuídos em Roma (4), Florença (5) e Veneza (3) seria ideal. Vocês têm passaporte?"),
    ("Temos! Queremos guia em português para os museus e restaurantes autênticos.",
     "Perfeito! Guia privativo em português é altamente recomendado para os museus do Vaticano e Uffizi — a profundidade das explicações é incrível. Nossa consultora Patricia vai preparar um roteiro com os melhores restaurantes e experiências gastronômicas!"),
]

_LUCIANA = [
    ("Olá! Meu namorado e eu queremos ir à Grécia. Estamos comemorando 5 anos juntos!",
     "Que celebração especial! A Grécia é absolutamente mágica — Santorini com seus pôres do sol dourados, Mykonos com suas praias cristalinas... Vocês já têm algum destino específico em mente?"),
    ("Santorini com certeza! Talvez Mykonos também. Vi que Dubrovnik na Croácia é linda também.",
     "Que itinerário dos sonhos! Santorini + Mykonos + Dubrovnik é uma combinação mediterrânea perfeita. Para 14 dias, dá para explorar os três destinos com calma. Vocês têm passaporte em dia?"),
    ("Sim, os dois têm! Queremos algo bem especial — suíte com vista para a caldera.",
     "A suíte com vista para a caldera em Santorini é um dos cenários mais românticos do mundo! Para um casal celebrando 5 anos, penso em spa à beira da caldera, jantar ao pôr do sol em Oia e passeio de catamarã. Qual o perfil de investimento?"),
    ("Premium! Estamos guardando para isso há 2 anos.",
     "Com padrão premium em Santorini, Mykonos e Dubrovnik terei opções verdadeiramente espetaculares — hotéis esculpidos nas rochas, jantares privês ao pôr do sol e experiências exclusivas. Nossa consultora Bruno vai entrar em contato em breve!"),
    ("Perfeito! Mal posso esperar para ver as opções.",
     "Já estou ansiosa para montar esse roteiro especial para vocês! Fique de olho no WhatsApp — a Bruno vai apresentar as melhores suítes cave hotels de Santorini e villas em Mykonos nas próximas horas!"),
]

_PRISCILA = [
    ("Oi! Estou planejando uma viagem para Bali com 3 amigas. Queremos algo mais espiritual e relaxante.",
     "Que escolha incrível! Bali é um destino que transforma a alma — os templos sagrados, os arrozais de Ubud, o spa balinês e a energia espiritual do lugar são únicos no mundo. Vocês já têm época em mente?"),
    ("Agosto ou setembro. Somos 4 amigas e queremos misturar yoga, spa e praia.",
     "Combinação perfeita! Ubud para o lado espiritual e wellness (retiro de yoga, templos, arrozais) e Seminyak/Canggu para praias e vida noturna. 12 dias é ideal para os dois. Todas têm passaporte?"),
    ("Todas têm! Queremos uma villa com piscina privativa em Ubud.",
     "Uma villa com piscina privativa em Ubud rodeada de natureza é absolutamente divina! Além disso, posso incluir um spa balinês completo de meio dia, aula de culinária balinesa e visita ao templo Tirta Empul. Qual o perfil de investimento?"),
    ("Alto padrão. Queremos algo premium mas não ridículo.",
     "Perfeito! Bali oferece um luxo muito acessível comparado à Europa. Com alto padrão, posso garantir villas incríveis, spas premiados e experiências únicas. Nossa consultora Bruno vai apresentar as melhores opções!"),
]

_GABRIEL = [
    ("Olá! Sempre sonhei em mergulhar na Grande Barreira de Coral na Austrália.",
     "Que sonho épico! A Grande Barreira de Coral é o maior recife do mundo — mergulhar ali é uma das experiências mais surreais que existem. Você viajaria sozinho ou com alguém?"),
    ("Com um amigo. Também queremos ver Sydney.",
     "Sydney + Cairns (para a Grande Barreira) é o roteiro clássico australiano! Sydney tem a ópera, a Harbour Bridge, praias de Bondi e vida noturna incrível. Para dois amigos aventureiros, 18 dias seria ideal. Passaportes em dia?"),
    ("Sim! Queremos também fazer snorkeling no recife e talvez ver cangurus.",
     "Incrível! Além do mergulho no recife, posso incluir um cruzeiro de 3 dias pelas ilhas da Grande Barreira, Wildlife Sanctuary para ver cangurus e coalas, e Blue Mountains day trip de Sydney. Qual o perfil de investimento?"),
    ("Alto padrão. É a viagem dos sonhos dos dois.",
     "Maravilha! A Austrália tem alojamentos e cruzeiros incríveis de alto padrão. Nossa consultora Marcos vai montar um roteiro épico para os dois aventureiros!"),
]

_SERGIO = [
    ("Oi! Quero passar o réveillon em Cancún com minha esposa.",
     "Que forma incrível de virar o ano! Cancún no Réveillon tem shows incríveis nos resorts, fogos de artifício sobre o mar do Caribe e uma festa que não tem fim. Vocês preferem resort all inclusive ou algo mais independente?"),
    ("All inclusive! Queremos pagar tudo de uma vez e não se preocupar com mais nada.",
     "Excelente escolha! Os resorts all inclusive de Cancún são perfeitos para isso — comida, bebida, shows e praia inclusas. Para 2 pessoas, quantas noites vocês planejam? E têm passaporte?"),
    ("Umas 9 noites, partir dia 18. Temos passaporte sim.",
     "Perfeito! 18 a 27 de dezembro, 2 pessoas all inclusive — anotado! Para o réveillon posso garantir resorts com festa especial de Ano Novo incluída. Querem algo mais intimista ou aquele resort gigante com vários restaurantes e piscinas?"),
    ("Gigante e animado! Mas também queremos conhecer Chichén Itzá.",
     "Ótima pedida! Posso incluir a excursão de Chichén Itzá no roteiro — é uma das 7 maravilhas do mundo moderno, vale muito a pena! Nossa consultora Diego vai apresentar os melhores resorts all inclusive com festa de réveillon garantida!"),
]

_NATALIA = [
    ("Olá! Meu marido e eu somos professores de história e sonhamos em visitar Portugal e Espanha juntos.",
     "Que combinação perfeita para amantes de história! Ibéria tem 3.000 anos de civilização — mouros, romanos, descobrimentos, arte barroca... Quantos dias vocês têm disponíveis para a viagem?"),
    ("Umas 2 semanas. Queremos Lisboa, Porto e Madrid. Temos passaporte.",
     "13 dias é ideal para os três destinos! Lisboa (4 dias), Porto (3 dias) e Madrid + Toledo (5 dias) — dá para explorar com profundidade. Vocês preferem guias privativos ou gostam de explorar mais por conta própria?"),
    ("Guias privativos em português! Adoramos profundidade histórica nos museus.",
     "Perfeito para vocês! Guia privativo que explica a história em detalhes no Museu Nacional do Azulejo, Palácio da Pena, Museu do Prado e Toledo medieval é uma experiência transformadora. Qual o perfil de investimento?"),
    ("Alto padrão. Queremos hotéis boutique históricos e restaurantes autênticos.",
     "Excelente! Hotéis boutique em palácios históricos restaurados de Lisboa e Porto, e restaurantes com culinária portuguesa/espanhola premiada. Posso incluir um tour vinícola no Douro, espetáculo de fado e flamenco ao vivo. Nossa consultora Bruno vai preparar um roteiro histórico incrível!"),
    ("Perfeito! Isso é exatamente o que queríamos.",
     "Fico feliz! Vocês vão se apaixonar ainda mais pela história ibérica! A Bruno já tem todas as informações e vai entrar em contato hoje com as melhores opções de hotéis e guias especializados."),
]

_AMANDA = [
    ("Oi! Quero ir a Dubai com meu marido. Quero o melhor do melhor.",
     "Dubai é o sinônimo de luxo e excesso — de forma absolutamente deslumbrante! Burj Al Arab, skydive sobre o Palm, jantar no topo do Burj Khalifa... Quando vocês pensam em viajar?"),
    ("Em novembro ou dezembro. Temos passaporte e queremos experiências únicas.",
     "Novembro/dezembro é a melhor época para Dubai — clima perfeito, 28°C, sem aquele calor extremo do verão. Para experiências únicas em Dubai, penso em voo de helicóptero sobre o Palm, safari no deserto VIP com jantar e entretenimento árabe, e visita ao Burj Khalifa. Quantos dias?"),
    ("Uns 8 dias. Pode ser bastante?",
     "8 dias é perfeito para Dubai! Dá pra explorar tudo com calma e ainda fazer day trip para Abu Dhabi (Louvre Abu Dhabi e Grande Mesquita Sheikh Zayed). Para um perfil premium, qual a faixa de investimento que vocês têm em mente?"),
]

_ROBERTO = [
    ("Oi, vim pelo anúncio. Tenho interesse em viajar para Portugal.",
     "Olá, Roberto! Portugal é um destino incrível — Lisboa, Porto, Algarve, Madeira... Tem tanto para explorar! Para te ajudar a montar o roteiro ideal, me conta: você viajaria sozinho ou com alguém? E qual época do ano seria melhor?"),
    ("Sozinho. Talvez em outubro. Mas ainda estou só pesquisando.",
     "Entendo, pesquisar é o primeiro passo! Solo em Portugal é fantástico — muita liberdade para explorar no seu ritmo. Quando você se sentir pronto para dar os próximos passos, estaremos aqui para ajudar. Posso enviar um guia gratuito de Portugal para você se inspirar?"),
]

_FELIPE = [
    ("Oi! Quero viajar para o Nordeste brasileiro. Tenho interesse em praias.",
     "Oi, Felipe! O Nordeste tem algumas das praias mais bonitas do Brasil — Jericoacoara, Maragogi, Fernando de Noronha, Lençóis Maranhenses... Qual tipo de praia você prefere? Mais tranquila e isolada ou agitada com infraestrutura?"),
    ("Ainda estou decidindo. Quero opções.",
     "Perfeito! Posso sugerir diferentes perfis: Jericoacoara (aventura e kitesurf), Maragogi (piscinas naturais e snorkeling), Porto Seguro (animação e festas) ou Fernando de Noronha (natureza preservada e mergulho). Você viajaria sozinho, com família ou amigos?"),
]

_EDUARDO = [
    ("Oi, quero saber sobre viagens para a Europa.",
     "Olá, Eduardo! A Europa tem destinos incríveis para todos os gostos. Para te ajudar a encontrar o roteiro ideal, me conta: qual tipo de experiência você busca — história e cultura, praias mediterrâneas, natureza alpina ou grandes cidades?"),
]


async def run(session: AsyncSession) -> None:
    otavio   = await get_lead_by_phone(session, "+5511966666666")
    camila   = await get_lead_by_phone(session, "+5511955555555")
    isabela  = await get_lead_by_phone(session, "+5511966660003")
    carla    = await get_lead_by_phone(session, "+5551933330006")
    rafael   = await get_lead_by_phone(session, "+5511944444444")
    fernanda = await get_lead_by_phone(session, "+5511877777777")
    ana_luiza= await get_lead_by_phone(session, "+5511866666666")
    maria    = await get_lead_by_phone(session, "+5511888888888")
    joao     = await get_lead_by_phone(session, "+5511999999999")
    pedro    = await get_lead_by_phone(session, "+5511933333100")
    thiago   = await get_lead_by_phone(session, "+5511955550004")
    luciana  = await get_lead_by_phone(session, "+5521988880001")
    priscila = await get_lead_by_phone(session, "+5511944440005")
    gabriel  = await get_lead_by_phone(session, "+5531977770002")
    sergio   = await get_lead_by_phone(session, "+5521977770011")
    natalia  = await get_lead_by_phone(session, "+5511911110008")
    amanda   = await get_lead_by_phone(session, "+5511922220007")
    roberto  = await get_lead_by_phone(session, "+5511833330010")
    felipe   = await get_lead_by_phone(session, "+5511900000009")
    eduardo  = await get_lead_by_phone(session, "+5511855550012")

    agenda = [
        (otavio,    _PARIS),
        (camila,    _TOQUIO),
        (isabela,   _ISABELA),
        (carla,     _CARLA),
        (rafael,    _NOVA_YORK),
        (fernanda,  _FERNANDA),
        (ana_luiza, _ANA_LUIZA),
        (maria,     _MARIA),
        (joao,      _JOAO),
        (pedro,     _PEDRO),
        (thiago,    _THIAGO),
        (luciana,   _LUCIANA),
        (priscila,  _PRISCILA),
        (gabriel,   _GABRIEL),
        (sergio,    _SERGIO),
        (natalia,   _NATALIA),
        (amanda,    _AMANDA),
        (roberto,   _ROBERTO),
        (felipe,    _FELIPE),
        (eduardo,   _EDUARDO),
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
