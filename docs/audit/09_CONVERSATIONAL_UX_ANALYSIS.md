# 09 — CONVERSATIONAL UX ANALYSIS
## Cadife Smart Travel — Análise da Experiência Conversacional
**Data:** 2026-05-14 | **Versão:** 1.0.0

---

## 1. IDENTIDADE E PERSONALIDADE DA AYA

### 1.1 Definição no System Prompt

```
"Você é a AYA, consultora de curadoria de viagens da Cadife Tour.
Seu estilo é o de uma especialista simpática conversando no WhatsApp
— direta, calorosa e sem enrolação."
```

**Avaliação:** Persona bem definida. "Direta, calorosa e sem enrolação" é um brief de persona claro e executável pelo LLM.

### 1.2 Restrições de Linguagem

```
LINGUAGEM — FRASES PROIBIDAS:
- "Como modelo de linguagem..."
- "Estou aqui para ajudar"
- "Sinto muito, mas não tenho acesso..."
- "Processando sua solicitação..."
- "Claro! Posso ajudá-lo com isso."
- Listas numeradas longas com 3+ itens
```

**Avaliação positiva:** As proibições estão bem mapeadas para os padrões robóticos mais comuns dos LLMs.

**Frases ausentes na proibição:**
- "Fico feliz em ajudar!" — muito genérica
- "Certamente!" / "Com certeza!" — robótico
- "Boa tarde/noite!" no meio de conversa ativa — quebra de contexto

---

## 2. FLUXO CONVERSACIONAL — PROBLEMAS IDENTIFICADOS

### 2.1 CRÍTICO — Inferência de Ocasião da Viagem

**Problema documentado:** A IA assume "lua de mel" para viagens que envolvem:
- Casal + Portugal
- Casal + Paris
- Casal + qualquer destino europeu
- "Primeira viagem internacional" + casal

**Causa raiz** (detalhada em `03_AI_AND_LANGGRAPH_ANALYSIS.md`):
- Exemplo explícito no system prompt: `"Lua de mel em Portugal — que combinação incrível!"`
- Base de conhecimento: PERSONA 2 associa "Portugal low-cost + casal = lua de mel"
- PERSONA 8: instrução para não perguntar motivação de casais

**Comportamento correto esperado:**

```
Cliente: "Quero viajar com minha esposa para Lisboa em julho."

AYA (CORRETO):
"Lisboa em julho — excelente escolha! 😊
Essa viagem tem alguma ocasião especial?
Como férias, lua de mel, aniversário, ou só um momento especial de vocês dois?"

AYA (ERRADO — ATUAL):
"Lua de mel em Lisboa — que combinação incrível! ✨
Já têm as datas definidas para julho?"
```

### 2.2 MÉDIO — Saudação Repetida

**Regra no system prompt:**
```
9. Não repita saudações nem se reapresente no meio de uma conversa ativa.
```

**Problema:** Se a triagem falhar e retornar `is_new_lead=True` para um cliente recorrente, a AYA se apresenta novamente, quebrando a continuidade conversacional.

**Comportamento errado:**
```
[Cliente com 3 turnos de conversa prévia]
Cliente: "Oi, continuando nossa conversa..."
AYA: "Olá! Sou a AYA da Cadife Tour. Como posso te ajudar a organizar sua próxima viagem?"
```

### 2.3 MÉDIO — Confirmação Excessiva

**Regra no system prompt:**
```
8. Dados já coletados: NUNCA reconfirme ou re-pergunte campos salvos no CRM.
```

**Problema:** O CRM_BLOCK lista dados já coletados, mas se o histórico está no `[-6:]` e o dado foi coletado no turno 7+, o orquestrador pode não "ver" o dado no histórico conversacional — mesmo que esteja no CRM_BLOCK.

**Mitigação atual:** O CRM_BLOCK lista explicitamente: `"DADOS JÁ NO CRM — NÃO PERGUNTE NOVAMENTE: destino='Lisboa', perfil='casal'"`.

**Risco residual:** O modelo pode ignorar a instrução do CRM_BLOCK e re-perguntar por campos que estão fora da janela de conversação.

### 2.4 BAIXO — Comprimento das Respostas

**Regra no system prompt:**
```
6. Respostas de briefing: máximo 2 frases curtas. Proibido parágrafos longos.
7. Confirmação implícita: use no máximo 3-4 palavras antes de perguntar o próximo campo.
```

**Avaliação:** As regras existem mas os modelos de linguagem tendem a ser verbosos. O `temperature=0.3` ajuda a manter respostas mais concisas, mas não garante.

**Verificação necessária:** Auditar logs de conversas reais para medir comprimento médio das respostas da AYA.

---

## 3. ANÁLISE DO FLUXO DE BRIEFING

### 3.1 Sequência Definida

```
Destino → Datas → Nº de pessoas → Perfil → Orçamento → Passaporte
```

**Avaliação:** Sequência lógica e bem definida. A ordem prioriza os campos com maior impacto no planejamento (destino é a base de tudo).

### 3.2 Pergunta Faltante — OCASIÃO

A sequência atual não inclui a pergunta de ocasião. **Esta é a causa principal do problema de inferência.**

**Sequência corrigida:**
```
Destino → Datas → Nº de pessoas → Perfil → OCASIÃO → Orçamento → Passaporte
```

**Texto sugerido para a pergunta de ocasião:**
```
"Perfeito 😊
Essa viagem tem alguma ocasião especial?
Como:
• férias
• lua de mel
• aniversário
• viagem em família
• negócios
• intercâmbio
• outro"
```

### 3.3 Pergunta de Perfil

**Pergunta atual:**
```python
"perfil": 'Pergunte o PERFIL em 1 frase: "É em família, casal, solo ou grupo de amigos?"',
```

**Problema:** A pergunta "É em família, casal, solo ou grupo de amigos?" é um múltiplo choice, mas o tom sugerido ("É em família?") pode ser percebido como inferência ("você acha que sou casado?").

**Pergunta melhorada:**
```
"Quantas pessoas vão viajar com você e qual o perfil do grupo?"
```

---

## 4. ANÁLISE DO UX DE RETOMADA

### 4.1 Cenários de Retomada

**Cenário A — Retomada em < 24h (conversa ativa):**
```
AYA: [SEM saudação] → vai direto ao ponto
"Continuando aqui, a próxima pergunta é sobre o orçamento..."
```
✅ Correto

**Cenário B — Retomada após 24-48h:**
```
AYA: "Oi [Nome]! De volta por aqui — a gente estava na escolha das datas, né? Vamos continuar!"
```
✅ Correto

**Cenário C — Retomada após 48h+:**
```
AYA: "Oi [Nome]! Tudo bem? Faz um tempinho que a gente não se falava 😊
Eu estava por aqui lembrando que a gente tinha parado na [fase].
Quer continuar de onde a gente estava ou prefere recomeçar do zero?"
```
✅ Correto — oferece escolha

**Cenário D — Triagem falhou (qualquer intervalo):**
```
AYA: "Olá! Sou a AYA da Cadife Tour. Vou te ajudar a organizar sua próxima viagem!"
```
❌ ERRADO — cliente recorrente recebe saudação de primeiro contato

---

## 5. ANÁLISE DO UX PÓS-BRIEFING

### 5.1 Transição para Agendamento

Quando briefing ≥ 60%, a AYA deve:
1. Confirmar que encaminhará para consultor
2. Gerar imagem do destino (generate_travel_image)
3. Oferecer slots de curadoria (check_availability)
4. Apresentar os slots de forma calorosa

**Problema identificado:** O `curadoria_service.gerar_mensagem_oferta_curadoria` pode sobrescrever a resposta do orchestrador se o orchestrador já mencionar scheduling. A regex de detecção não é 100% confiável.

**Risco:** O cliente pode receber duas mensagens de oferta de agendamento — uma do orchestrador e uma do curadoria_service.

**Solução:** Priorizar sempre a resposta do orchestrador (que tem contexto completo) e usar o fallback do curadoria_service apenas quando o orchestrador definitivamente não mencionou scheduling.

### 5.2 Confirmação do Agendamento

```
AYA: "Agendamento confirmado! 🎉
Veja detalhes:
• Data: [data]
• Hora: [hora]
• Consultor: [nome]
• Google Meet: [link]

Nos vemos em breve! Qualquer dúvida, é só chamar. 😊"
```

**Avaliação:** Bom template. O Meet link é o elemento mais importante — deve ser apresentado de forma destacada.

---

## 6. ANÁLISE DE EDGE CASES CONVERSACIONAIS

### 6.1 Cliente pergunta sobre preços

**Comportamento atual:**
```
AYA: "Ótima pergunta! Essa informação precisa ser verificada com nossos consultores,
que têm acesso direto às operadoras. Assim que completarmos seu briefing, eles
entrarão em contato com todos os detalhes. 😊"
```
✅ Correto

**Risco de alucinação:** Detectado por `_HALLUCINATION_PATTERNS` e substituído pelo `_HALLUCINATION_FALLBACK`. Implementação adequada.

### 6.2 Cliente envia áudio

**Comportamento atual:**
1. Transcreve via Whisper (se disponível)
2. Processa transcrição como texto
3. Se transcrição falhar: `"Áudio não suportado nestes momentos, prefira o meio texto."`

**Problema:** A mensagem de fallback é pouco amigável. Melhoria sugerida:
```
"Recebi seu áudio! Tive uma dificuldade técnica para processá-lo agora.
Pode me escrever o que falou? Assim consigo te ajudar melhor! 😊"
```

### 6.3 Cliente muda de ideia sobre o destino

**Cenário:** Cliente disse "Lisboa" (salvo no briefing), depois diz "Na verdade, prefiro Cancún".

**Comportamento esperado:**
- AYA deve entender que houve mudança
- Chamar `persist_lead_data` com o novo destino
- Recalcular RAG query com novo destino

**Risco:** O CRM_BLOCK mostrará `destino='Lisboa'` mas o cliente agora quer Cancún. O orchestrador precisa reconhecer a mudança e atualizar.

**Regra ausente no system prompt:**
```
Se o cliente mencionar explicitamente que mudou de ideia sobre algum campo,
use persist_lead_data para sobrescrever o valor anterior.
```

### 6.4 Cliente com dúvidas sobre documentação (visto, passaporte)

**Comportamento esperado:**
- RAG recupera informações relevantes do knowledge base (`destinos.txt`, `faq.txt`)
- AYA responde com base no RAG, sem inventar

**Avaliação:** O RAG-first garante que informações sobre vistos e passaportes vêm da base de conhecimento, não do conhecimento geral do LLM. Isso é correto — regras de visto mudam e o conhecimento geral do LLM pode estar desatualizado.

---

## 7. CHECKLIST DE QUALIDADE CONVERSACIONAL

| Aspecto | Status | Ação Necessária |
|---------|--------|----------------|
| Persona bem definida | ✅ | Nenhuma |
| Proibição de frases robóticas | ✅ | Adicionar mais frases |
| Sequência de briefing definida | ✅ | Adicionar campo ocasião |
| Pergunta de ocasião | ❌ | Implementar urgente |
| Saudação baseada em tempo | ✅ | Nenhuma (exceto falha de triagem) |
| Evitar re-perguntar campos salvos | ✅ | Melhorar robustez |
| Não inferir lua de mel | ❌ | Corrigir system prompt + base RAG |
| Handoff para consultor | ✅ | Melhorar critério de disparo |
| Concisão de respostas | ⚠️ | Monitorar via logs |
| Fallback de áudio | ⚠️ | Melhorar mensagem de fallback |
| Detecção de mudança de destino | ❌ | Adicionar regra ao system prompt |
