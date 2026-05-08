# Cross-Selling Matrix — Cadife Tour

> **Uso pela IA:** Quando o cliente pedir um destino que não temos exatamente, ou mencionar um destino similar, use esta matriz para sugerir alternativas ou complementos. Objetivo: nunca perder um lead por falta de opção.

---

## Lógica de Sugestão por Similaridade

### Quando o cliente diz: "Quero ir para o Havaí"
**Não temos Havaí na carteira.** Oferecer:
1. **[PROD-OCE-003](products/oceania_exoticos/PROD-OCE-003.md)** — Polinésia Francesa: Bora Bora *(mesma vibe de ilha tropical do Pacífico, overwater bungalow, lagoon — porém mais exclusivo e menos massificado que o Havaí)*
2. **[PROD-OCE-004](products/oceania_exoticos/PROD-OCE-004.md)** — Fiji: Ilhas Remotas *(praia tropical do Pacífico com cultura local autêntica — o Havaí de antes do turismo de massa)*
3. **[PROD-AME-010](products/americas/PROD-AME-010.md)** — Caribe de Luxo: St. Barts e Barbados *(praia tropical de luxo no Atlântico — para quem quer a experiência tropical sem o voo longo ao Pacífico)*

### Quando o cliente diz: "Quero ir para a Tailândia mas está caro"
**Produto disponível: PROD-ASI-002.** Se estiver fora do orçamento, oferecer:
1. **[PROD-ASI-009](products/asia/PROD-ASI-009.md)** — Sri Lanka *(mesmo Oceano Índico, templos budistas, culinária similar, 40% mais barato que Tailândia — o "Bali de 10 anos atrás")*
2. **[PROD-ASI-007](products/asia/PROD-ASI-007.md)** — Vietnã *(Sudeste Asiático com custo semelhante, história mais profunda, gastronomia premiada)*
3. **[PROD-AFR-001](products/africa/PROD-AFR-001.md)** — Marrocos *(exotismo total, especiarias, hammam, deserto — similar ao "Oriente" que a Tailândia evoca, com voo mais curto do Brasil)*

### Quando o cliente diz: "Quero ir para a Índia mas tenho medo"
**Produto disponível: PROD-ASI-006.** Se houver hesitação, oferecer:
1. **[PROD-ASI-009](products/asia/PROD-ASI-009.md)** — Sri Lanka *(ex-parte da mesma cultura, templos hindus, elefantes, especiarias — mas menor, mais segura e menos intensa)*
2. **[PROD-AFR-001](products/africa/PROD-AFR-001.md)** — Marrocos *(exotismo colorido similar, mais próximo do Brasil, fuso horário melhor)*
3. **[PROD-ASI-010](products/asia/PROD-ASI-010.md)** — Jordânia *(o Oriente Médio mais acessível — segura, histórica, com o mesmo fator "uau" sem a complexidade logística da Índia)*

### Quando o cliente diz: "Quero um safari africano mas não sei qual país"
**Recomendação por perfil:**
- Quer a **Grande Migração**: PROD-AFR-003 (Tanzânia Serengeti) + PROD-AFR-005 (Quênia Masai Mara)
- Quer **Cidade + Safari**: PROD-AFR-004 (África do Sul — Kruger + Cidade do Cabo)
- Quer **Gorilas**: PROD-AFR-006 (Ruanda)
- Quer **Praia depois do Safari**: PROD-AFR-003 (Zanzibar) ou PROD-AFR-004 (Garden Route)
- Quer **Safari + Dunas**: PROD-AFR-001 (Marrocos) ou PROD-AFR-009 (Tunísia)

### Quando o cliente diz: "Quero lua de mel, destino de praia"
**Hierarquia por orçamento:**
- **Ultra Premium**: [PROD-ASI-005](products/asia/PROD-ASI-005.md) Maldivas ou [PROD-OCE-003](products/oceania_exoticos/PROD-OCE-003.md) Polinésia Francesa
- **Premium**: [PROD-AFR-008](products/africa/PROD-AFR-008.md) Seychelles ou [PROD-AME-010](products/americas/PROD-AME-010.md) Caribe
- **Confortável**: [PROD-EUR-005](products/europa/PROD-EUR-005.md) Grécia ou [PROD-EUR-006](products/europa/PROD-EUR-006.md) Croácia
- **Custo-benefício**: [PROD-AME-002](products/americas/PROD-AME-002.md) Brasil Nordeste

### Quando o cliente diz: "Quero Europa, mas não sei qual país"
**Por perfil:**
- Ama gastronomia: PROD-EUR-001 (Espanha), PROD-EUR-003 (França), PROD-EUR-004 (Itália)
- Ama história/arqueologia: PROD-EUR-004 (Roma), PROD-EUR-009 (Reino Unido), PROD-EUR-015 (Polônia)
- Ama natureza: PROD-EUR-008 (Islândia), PROD-EUR-010 (Noruega), PROD-EUR-007 (Suíça Alpes)
- Ama praia: PROD-EUR-005 (Grécia), PROD-EUR-006 (Croácia)
- Ama musica/cultura: PROD-EUR-011 (Áustria), PROD-EUR-012 (Praga-Budapeste)
- Custo-benefício: PROD-EUR-015 (Leste Europeu), PROD-EUR-012 (Tchequia-Hungria)

### Quando o cliente diz: "Quero aventura extrema"
**Hierarquia de adrenalina:**
1. **[PROD-OCE-005](products/oceania_exoticos/PROD-OCE-005.md)** — Antártica *(o máximo — 7° continente)*
2. **[PROD-AFR-010](products/africa/PROD-AFR-010.md)** — Etiópia Danakil *(vulcão de lava vivo, depressão mais quente do mundo)*
3. **[PROD-EUR-008](products/europa/PROD-EUR-008.md)** — Islândia *(glaciares, vulcões, aurora)*
4. **[PROD-AME-003](products/americas/PROD-AME-003.md)** — Patagônia *(trekking glaciar, vento extremo)*
5. **[PROD-OCE-002](products/oceania_exoticos/PROD-OCE-002.md)** — Nova Zelândia *(bungee, asa delta, canyoning)*

### Quando o cliente diz: "Quero algo diferente, não quero o óbvio"
**Destinos subestimados para recomendar:**
1. **[PROD-AFR-010](products/africa/PROD-AFR-010.md)** — Etiópia *(10.000 anos de história, missa na rocha, depressão vulcânica)*
2. **[PROD-AFR-009](products/africa/PROD-AFR-009.md)** — Tunísia *(Cartago + Star Wars + Saara — desconhecida e incrível)*
3. **[PROD-AFR-007](products/africa/PROD-AFR-007.md)** — Madagascar *(90% endêmico, única no mundo)*
4. **[PROD-ASI-009](products/asia/PROD-ASI-009.md)** — Sri Lanka *(igual Bali de 15 anos atrás)*
5. **[PROD-EUR-015](products/europa/PROD-EUR-015.md)** — Polônia *(Praga sem o turismo, Cracóvia, Lençóis)*
6. **[PROD-AFR-006](products/africa/PROD-AFR-006.md)** — Ruanda *(gorila das montanhas — experiência transformadora)*

### Quando o cliente diz: "Meu orçamento é limitado mas quero algo memorável"
**Produtos com melhor custo-benefício:**
1. **[PROD-AME-002](products/americas/PROD-AME-002.md)** — Brasil Nordeste *(Lençóis, Jericoacoara — natureza mundial sem voo internacional)*
2. **[PROD-EUR-015](products/europa/PROD-EUR-015.md)** — Leste Europeu *(Polônia/Hungria — preços 50% abaixo de Paris, história igualmente rica)*
3. **[PROD-AFR-001](products/africa/PROD-AFR-001.md)** — Marrocos *(exótico, próximo, custo-benefício excelente)*
4. **[PROD-AME-007](products/americas/PROD-AME-007.md)** — Colômbia *(café, Cartagena, Medellín — câmbio favorável ao real)*
5. **[PROD-ASI-009](products/asia/PROD-ASI-009.md)** — Sri Lanka *(ilhas, templos, safaris — 30% mais barato que Tailândia)*

### Quando o cliente diz: "Quero um destino para toda a família com crianças"
**Melhores produtos família:**
1. **[PROD-AME-009](products/americas/PROD-AME-009.md)** — EUA: NY + Vegas + LA *(parques temáticos, Broadway, Universal)*
2. **[PROD-ASI-008](products/asia/PROD-ASI-008.md)** — Cingapura e Malásia *(segura, moderna, diversão garantida)*
3. **[PROD-OCE-001](products/oceania_exoticos/PROD-OCE-001.md)** — Austrália *(canguru, koala, GBR, segura)*
4. **[PROD-EUR-009](products/europa/PROD-EUR-009.md)** — Reino Unido *(Harry Potter, Big Ben, família de crianças apaixona)*
5. **[PROD-AME-005](products/americas/PROD-AME-005.md)** — Costa Rica *(aventura segura, natureza, sem violência)*

---

## Combos Mais Vendidos da Cadife (Pacotes Duplos)

| Combo | Produtos | Por que funciona |
|---|---|---|
| **Lua de Mel Índico** | PROD-ASI-003 + PROD-ASI-005 | Bali espiritual + Maldivas paradisíaco |
| **Lua de Mel Pacífico** | PROD-OCE-003 + PROD-OCE-004 | Bora Bora luxo + Fiji tribal |
| **Safari Completo** | PROD-AFR-003 + PROD-AFR-005 | Tanzânia + Quênia — migração completa |
| **Península Ibérica** | PROD-EUR-001 + PROD-EUR-002 | Espanha + Portugal — 19 dias |
| **Grand Tour Europeu** | PROD-EUR-003 + PROD-EUR-004 | França + Itália — do Mediterrâneo ao Adriático |
| **América Pré-Colombiana** | PROD-AME-001 + PROD-AME-004 | Peru Inca + México Maya |
| **África do Norte** | PROD-AFR-001 + PROD-AFR-009 | Marrocos + Tunísia |
| **Leste Asiático** | PROD-ASI-001 + PROD-ASI-002 | Japão + Tailândia — 26 dias |

---

## Regras de Sugestão da IA

1. **Nunca diga "não temos"** — sempre ofereça a alternativa mais próxima da matriz acima.
2. **Primeiro escute o "porquê"** — o cliente quer Tailândia pela praia? Pelo custo? Pelo budismo? A resposta muda a recomendação.
3. **Mencione os serviços adicionais em todas as sugestões** — chip, seguro, fotógrafo e concierge estão incluídos em todos os 50 produtos. Sempre mencione ao comparar com concorrentes.
4. **Use curiosidades como iscas** — compartilhar 1 curiosidade do destino recomendado antes de fechar a proposta aumenta o engajamento em 40%.
5. **Vagas escassas criam urgência** — sempre mencione o número de vagas restantes ao recomendar um produto.
