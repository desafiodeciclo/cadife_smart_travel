# 03 — AI AND LANGGRAPH ANALYSIS
## Cadife Smart Travel — Auditoria Profunda da IA e do Pipeline LangGraph
**Data:** 2026-05-14 | **Versão:** 1.0.0

---

## 1. VISÃO GERAL DO PIPELINE LANGGRAPH

```
security_gate → triagem → rag_mandatory → build_context
     → orchestrator → validate_output → confusion_tracker → END
```

### 1.1 Nós do Grafo e Responsabilidades

| Nó | Modelo | Função | Temperatura |
|----|--------|--------|-------------|
| `security_gate` | — (regex) | Bloqueia prompt injection pré-LLM | — |
| `triagem` | qwen-2.5-72b:free | CRM lookup, identifica lead, next_field | 0.0 |
| `rag_mandatory` | — (ChromaDB) | Busca híbrida obrigatória antes do LLM | — |
| `build_context` | — (template) | Monta system prompt com CRM + RAG | — |
| `orchestrator` | gemini-2.0-flash-001 | Resposta conversacional + function calling | 0.3 |
| `validate_output` | — (regex) | Bloqueia alucinações e code leak | — |
| `confusion_tracker` | — (contador) | Detecta campo repetido, alerta silencioso | — |

---

## 2. ANÁLISE DO NÓ TRIAGEM

### 2.1 Prompt do TriagemAgent

```python
_TRIAGEM_SYSTEM = """
Você é um agente de triagem da Cadife Tour. Sua ÚNICA função é obter o contexto do
cliente no CRM e retornar um JSON estruturado — sem conversar, sem adicionar texto extra.

PASSOS OBRIGATÓRIOS:
1. Chame get_lead_context_by_wa_id com o wa_id fornecido.
2. Determine next_field_to_collect seguindo esta ordem:
   destino → data_ida → qtd_pessoas → perfil → orcamento → tem_passaporte → completo
...
"""
```

### 2.2 Problemas Identificados

**PROBLEMA 1 — Falha silenciosa da triagem:**
```python
except Exception as exc:
    logger.warning("triagem_agent_failed", ...)
    return {
        "exists": False,
        "is_new_lead": True,
        "next_field_to_collect": "destino",
        ...
    }
```
Qualquer falha da triagem (timeout, rate limit, parse error) resulta em tratar o cliente como **novo lead**, mesmo sendo um cliente recorrente. Isso causa:
- Saudação incorreta ("Olá, sou a AYA da Cadife Tour..." para cliente com histórico)
- Perda de contexto do briefing
- Re-coleta de dados já fornecidos

**PROBLEMA 2 — Dependência de parse JSON no LLM:**
O TriagemAgent retorna um JSON puro mas pode "vazar" markdown (```json ... ```). O código trata isso:
```python
if "```" in raw:
    match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", raw, re.DOTALL)
```
Mas se o modelo retornar JSON malformado por outra razão, `json.loads` vai falhar e cair no fallback.

**SOLUÇÃO:** Adicionar schema validation com Pydantic após o parse, e um fallback mais inteligente que tenta recuperar do DB diretamente se a triagem falhar.

---

## 3. ANÁLISE DO NÓ RAG MANDATORY

### 3.1 Implementação Atual

```python
ctx = rag_service.retrieve_with_metadata_filter(
    rag_query,
    k=4,
    destino=destino_tag,
    perfil=perfil_tag,
)
```

### 3.2 Cache RAG em Memória

```python
_rag_cache: dict[str, tuple[str, float]] = {}
_RAG_CACHE_TTL_S = 1800  # 30 minutos
_RAG_CACHE_MAX_SIZE = 500
```

**Problema:** Cache em memória de processo único. Com múltiplos workers uvicorn (`--workers 4`), cada processo tem seu próprio cache — queries repetidas serão feitas no ChromaDB por cada processo. A solução adequada é usar Redis como cache compartilhado.

### 3.3 Enriquecimento de Query

```python
rag_query_parts = [safe_message]
if briefing_ctx.get("destino"):
    rag_query_parts.append(f"destino {briefing_ctx['destino']}")
if briefing_ctx.get("perfil"):
    rag_query_parts.append(f"perfil {briefing_ctx['perfil']}")
```

**Observação positiva:** A query enriquecida com destino e perfil do briefing melhora a relevância do RAG. A lógica de priorizar tags da mensagem atual (Zona B) antes do briefing salvo (Zona A) está correta.

---

## 4. ANÁLISE DO SYSTEM PROMPT — PROBLEMA "LUA DE MEL"

### 4.1 A Causa Raiz da Inferência Indevida

Este é o problema crítico identificado. A causa tem **múltiplas camadas**:

#### CAMADA 1 — Exemplo Explícito no System Prompt

```python
_ORCHESTRATOR_SYSTEM_TEMPLATE = """
...
USE em vez disso expressões naturais:
- Confirmação curta (3-4 palavras): "Anotado!", "Perfeito!", "Boa escolha!"
- Escuta ativa — repita um detalhe antes de perguntar o próximo:
    · "Lua de mel em Portugal — que combinação incrível! Já tem data em mente?"
    ·"Família de 4 em Cancún — show! Isso é para quando?"
...
"""
```

**PROBLEMA GRAVE:** O exemplo `"Lua de mel em Portugal — que combinação incrível!"` ensina explicitamente o modelo que **Portugal + qualquer contexto de viagem = lua de mel**. Este é um few-shot example implícito que cria viés direto na geração.

#### CAMADA 2 — Base de Conhecimento RAG (perfis_e_solucoes.md)

O arquivo `perfis_e_solucoes.md` contém:

```markdown
## PERSONA 2 — "O CASAL EM LUA DE MEL ECONÔMICA"
**Destino mais buscado**: Nordeste Brasileiro, Argentina, Portugal low-cost

### Sinal de Reconhecimento na Conversa
Cliente menciona: "lua de mel", "recém-casados", "romantismo", 
"primeira viagem internacional"... → Acionar este perfil.
```

Quando o RAG recupera este chunk para queries sobre Portugal ou viagem de casal, **o contexto semântico "Portugal = lua de mel" é injetado no system prompt do orchestrador**. O modelo absorve essa associação.

#### CAMADA 3 — PERSONA 8 (Casal em Reconexão)

```markdown
## PERSONA 8 — "O CASAL EM CRISE (VIAGEM COMO RECONEXÃO)"
Destino mais buscado: Maldivas, Bali, Caribe (ilhas menores), Toscana

### Sinal de Reconhecimento na Conversa
Cliente menciona: "só eu e minha esposa/marido", "faz tempo que não viajamos juntos"...
→ Acionar este perfil com sensibilidade e sem fazer perguntas desnecessárias sobre a motivação.
```

A instrução `"sem fazer perguntas desnecessárias sobre a motivação"` ensina o modelo a **não perguntar** o motivo da viagem para casais — exatamente o oposto do comportamento correto esperado.

#### CAMADA 4 — Metadata Tagger com perfil_tag

O `metadata_tagger.py` mapeia perfis para filtros ChromaDB. Se o `perfil_tag` for interpretado como `"lua_de_mel"` ou `"romantico"` para qualquer casal, o RAG vai preferir chunks de personas 2 e 8, reforçando o viés.

### 4.2 Comportamento Observado vs Esperado

| Situação | Comportamento Atual (ERRADO) | Comportamento Correto |
|----------|------------------------------|----------------------|
| Casal mencionando Portugal | Assume "lua de mel" | Pergunta: "Essa viagem tem alguma ocasião especial?" |
| Casal + "primeira vez fora do Brasil" | Assume "lua de mel econômica" (Persona 2) | Coleta perfil normalmente |
| Qualquer viagem para Paris | Sugere contexto romântico | Pergunta o tipo de ocasião |
| Casal com "só eu e minha esposa" | Pergunta sem perguntar (Persona 8) | Pergunta diretamente a ocasião |

### 4.3 Correções Necessárias

**FIX 1 — Remover o exemplo "lua de mel" do system prompt:**
```python
# REMOVER:
# "Lua de mel em Portugal — que combinação incrível! Já tem data em mente?"

# SUBSTITUIR por exemplo neutro:
# "Portugal em dezembro — ótima escolha! Já tem data em mente?"
```

**FIX 2 — Adicionar regra explícita no system prompt:**
```python
═══════════════════════════════════════════════════════════
REGRA CRÍTICA — NUNCA INFERIR OCASIÃO DA VIAGEM:
═══════════════════════════════════════════════════════════
· NUNCA assuma que uma viagem é "lua de mel", "aniversário", "férias", etc.
· SEMPRE pergunte explicitamente após coletar destino + perfil de viajantes:
  "Essa viagem tem alguma ocasião especial? Como férias, lua de mel, aniversário, família, negócios ou outro?"
· A ocasião especial é um CAMPO DO BRIEFING, não uma inferência.
· Isso vale para qualquer destino, qualquer combinação de viajantes.
```

**FIX 3 — Adicionar campo "ocasiao" ao briefing:**
```python
# Na tool persist_lead_data, adicionar:
"ocasiao": {
    "type": "string",
    "enum": ["ferias", "lua_de_mel", "aniversario", "familia", "negocios", "intercambio", "outro"],
    "description": "Ocasião da viagem — APENAS quando confirmado explicitamente pelo cliente"
}
```

**FIX 4 — Corrigir PERSONA 8 na base de conhecimento:**
```markdown
### Sinal de Reconhecimento na Conversa
IMPORTANTE: A AYA deve PERGUNTAR a ocasião — nunca assumir.
"Essa viagem tem alguma ocasião especial para vocês?"
```

**FIX 5 — Remover/reorganizar exemplos no fluxo_atendimento.txt:**
Adicionar explicitamente à pergunta de perfil:
```
5. Ocasião: "Essa viagem tem alguma ocasião especial? (férias, lua de mel, aniversário, negócios, outro?)"
```

---

## 5. ANÁLISE DO ORCHESTRADOR

### 5.1 Function Calling (Tools)

| Tool | Trigger | Status |
|------|---------|--------|
| `query_project_scope` | Dúvidas sobre destinos/serviços Cadife | ✅ Bem implementada |
| `persist_lead_data` | Salvar campo confirmado do briefing | ⚠️ Vide seção 5.2 |
| `check_availability` | Quando briefing ≥ 60% | ✅ Implementada |
| `confirm_scheduling` | Cliente confirma horário | ✅ Implementada |
| `generate_travel_image` | Fim do briefing, destino confirmado | ✅ Implementada |

### 5.2 Problema na persist_lead_data

A tool `persist_lead_data` aceita `perfil` como:
```json
"perfil": {
  "type": "string",
  "enum": ["casal", "familia", "solo", "grupo", "amigos"]
}
```

**Problema:** O campo `perfil` não inclui informações sobre a **ocasião** (lua de mel, férias, etc.). Quando o modelo "sente" que é lua de mel, ele tenta incorporar isso em outros campos (ex: `observacoes`), o que gera inconsistência.

### 5.3 Truncamento de Histórico

```python
# _node_orchestrator
messages.extend(state["conversation_history"][-6:])
```

O orchestrador usa apenas os **últimos 6 turnos** do histórico. Para conversas longas (briefing completo pode levar 8-12 turnos), informações coletadas no início podem ser perdidas.

**Mitigação existente:** O `memory_summary` (compressão de mensagens antigas) é injetado no system prompt. Mas a qualidade da compressão depende do LLM de resumo.

**Risco real:** Cliente já informou destino há 10 turnos → isso pode ter saído do `[-6:]` → orquestrador não "vê" mais na conversa → reperguncia destino. O CRM_BLOCK mitiga isso parcialmente (dados salvos aparecem), mas se o campo ainda não foi `persist`ido, a informação se perde.

### 5.4 Tool Call Loop Máximo

```python
max_tool_rounds: int = 4
```

Com 4 rounds de tool calls, o fluxo pode ser:
1. `query_project_scope` (RAG on-demand)
2. `persist_lead_data` (salvar campo)
3. `check_availability` (buscar slots)
4. `generate_travel_image` (gerar imagem)

Esse limite é adequado para o fluxo normal. Mas em cenários complexos (ex: múltiplos campos para persistir), pode ser insuficiente.

---

## 6. ANÁLISE DO VALIDATE_OUTPUT

### 6.1 Detecção de Alucinações

```python
_HALLUCINATION_PATTERNS = [
    (re.compile(r"(custa|preço|valor|fica)\s*r?\$\s*[\d.,]+", re.I), "price_generated"),
    (re.compile(r"(disponível|disponibilidade|tem voo|tem hotel)", re.I), "availability_confirmed"),
    (re.compile(r"(reservo|confirmo sua vaga|garanto)", re.I), "booking_promised"),
]
```

**Avaliação:** Os padrões são funcionais mas há falsos positivos potenciais. Exemplo: `"tem hotel disponível para você verificar"` seria bloqueado mesmo sendo uma frase válida no contexto de recomendação.

**Padrão ausente:** Nomes de preços em extenso ("dois mil reais") não são detectados.

### 6.2 Code Leak Detection

```python
_CODE_LEAK_RE = re.compile(r'(?:print\s*\(|default_api\.|functions\.\w+\s*\()', re.I)
```

**Avaliação:** Detecta os padrões mais comuns de vazamento de chamada de ferramenta (Gemini às vezes emite `default_api.fn(args)` como texto). A detecção via regex + fallback para `_try_parse_text_tool_call` é uma solução robusta.

---

## 7. ANÁLISE DO CONFUSION TRACKER

### 7.1 Implementação

```python
_field_repetition_tracker: dict[str, tuple[str, int]] = {}
_CONFUSION_THRESHOLD = 2

def _update_confusion_counter(wa_id: str, next_field: str) -> int:
    # Conta quantas vezes o mesmo campo aparece consecutivamente
    if next_field == prev_field:
        count += 1
    else:
        count = 1
    ...
```

### 7.2 Problemas

**CRÍTICO — Estado em memória:** O `_field_repetition_tracker` é um dicionário em memória de processo. Problemas:
1. **Multi-worker:** Cada processo uvicorn tem seu próprio tracker — o contador é zerado quando a requisição cai em worker diferente
2. **Restart:** Reinício do servidor zera todo o histórico de confusão
3. **Memory leak:** Leads inativos acumulam entradas que só são limpas quando `next_field="completo"`

**MÉDIO — Alerta sem ação:** Quando `confusion_count >= 2`, o sistema só alerta via Slack/log. Não há handoff automático para consultor humano.

---

## 8. ANÁLISE DO MODELO DE FALLBACK

```python
_ORCHESTRATOR_FREE_MODELS: list[str] = [
    settings.OPENROUTER_FALLBACK_MODEL,
    "nvidia/llama-3.1-nemotron-ultra-253b-v1:free",
    "meta-llama/llama-3.3-70b-instruct:free",
]
```

**Avaliação:** Chain de fallback adequada. Modelos gratuitos como fallback reduzem custo em caso de quota exceeded no modelo principal.

**Problema potencial:** Modelos gratuitos têm menor capacidade de manter as regras complexas do system prompt (especialmente a proibição de inferir ocasião de viagem e as instruções de formatação). A qualidade de resposta do fallback pode divergir significativamente do modelo primário.

---

## 9. CHECKLIST DE CORREÇÕES PRIORITÁRIAS

### Prioridade 1 — Crítico (impacta UX diretamente)
- [ ] Remover exemplo "Lua de mel em Portugal" do system prompt
- [ ] Adicionar campo `ocasiao` ao briefing e à tool `persist_lead_data`
- [ ] Adicionar regra explícita "NUNCA inferir ocasião" no system prompt
- [ ] Corrigir PERSONA 8 em `perfis_e_solucoes.md`

### Prioridade 2 — Importante (impacta confiabilidade)
- [ ] Mover `_rag_cache` e `_field_repetition_tracker` para Redis
- [ ] Melhorar fallback da triagem (consultar DB diretamente se LLM falhar)
- [ ] Validar JSON da triagem com Pydantic antes de usar

### Prioridade 3 — Melhoria (impacta qualidade)
- [ ] Adicionar padrões de alucinação para valores em extenso
- [ ] Considerar aumentar `conversation_history[-6:]` para `[-10:]`
- [ ] Adicionar handoff automático para consultor quando `confusion_count >= 2`
