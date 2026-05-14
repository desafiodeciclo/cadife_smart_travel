# 13 — ROOT CAUSE ANALYSIS
## Cadife Smart Travel — Análise de Causa Raiz dos Problemas
**Data:** 2026-05-14 | **Versão:** 1.0.0

---

## 1. MAPA COMPLETO DE CAUSAS RAIZ

### PROBLEMA 1: IA assume "lua de mel" sem confirmação

**Sintoma:** Quando um casal menciona Portugal, Paris ou Europa, a AYA responde como se a viagem fosse lua de mel, sem perguntar.

**Causa Raiz — MULTICAMADA:**

```
CAMADA 1 (Principal) — Exemplo explícito no system prompt:
  _ORCHESTRATOR_SYSTEM_TEMPLATE contém:
  "Lua de mel em Portugal — que combinação incrível! Já tem data em mente?"
  → Esse exemplo ensina o LLM: casal + Portugal = lua de mel
  → Few-shot implícito que gera viés direto

CAMADA 2 — Base de conhecimento RAG:
  perfis_e_solucoes.md → PERSONA 2 lista Portugal como destino de lua de mel econômica
  → RAG recupera esse chunk para queries sobre Portugal + casal
  → Contexto semântico reforça associação "Portugal = lua de mel"

CAMADA 3 — Instrução contraditória (PERSONA 8):
  "Acionar este perfil com sensibilidade e sem fazer perguntas 
   desnecessárias sobre a motivação."
  → Ensina o LLM a NÃO perguntar sobre ocasião para casais
  → Exatamente o oposto do comportamento correto

CAMADA 4 — Campo ausente no schema:
  Tabela briefing não tem campo "ocasiao"
  → A IA não tem onde persistir a ocasião da viagem
  → Sem campo para coletar, não há incentivo para perguntar

CAUSA FUNDAMENTAL: Ausência de definição explícita da ocasião como campo obrigatório
do briefing + exemplo no system prompt que reforça inferência incorreta.
```

**Fix imediato:**
1. Remover exemplo "Lua de mel em Portugal" do system prompt
2. Adicionar regra "NUNCA inferir ocasião" no system prompt
3. Adicionar campo `ocasiao` no briefing e na tool `persist_lead_data`
4. Adicionar pergunta de ocasião à sequência do briefing

---

### PROBLEMA 2: IA perde contexto da conversa

**Sintoma:** Em conversas longas, a AYA re-pergunta informações que o cliente já forneceu.

**Causa Raiz:**

```
CAUSA 1 — Janela de contexto limitada:
  orchestrator usa conversation_history[-6:]
  → Apenas 3 turnos visíveis ao LLM
  → Dados de turnos anteriores invisíveis no histórico

CAUSA 2 — persist_lead_data não chamada em todos os turnos:
  Se o LLM extraiu a informação mas não chamou persist_lead_data,
  o dado não está no DB e sai da janela de contexto
  → Quando o LLM não vê mais no histórico, re-pergunta

CAUSA 3 — Triagem falha silenciosamente:
  Se TriagemAgent falhar → retorna is_new_lead=True
  → CRM_BLOCK não mostra dados existentes
  → LLM não sabe que dados foram coletados

CAUSA FUNDAMENTAL: Dependência excessiva do histórico de conversa em vez
de persistir cada informação coletada imediatamente no DB.
```

**Fix:**
1. Aumentar `conversation_history[-6:]` para `[-10:]`
2. Garantir que `persist_lead_data` é chamada imediatamente quando um campo é mencionado
3. Melhorar fallback da triagem (consultar DB diretamente)
4. Adicionar validação Pydantic no JSON da triagem

---

### PROBLEMA 3: Atendimento não finaliza (fluxo não conclui)

**Sintoma:** O ciclo de briefing → qualificação → agendamento não é concluído de forma consistente.

**Causa Raiz:**

```
CAUSA 1 — Confusion tracker não persiste entre workers/restarts:
  _field_repetition_tracker é in-memory
  → Em multi-worker, contador zerado entre requisições
  → Confusão da IA não é detectada corretamente

CAUSA 2 — Conflito entre orchestrador e curadoria_service:
  Ambos podem tentar oferecer agendamento na mesma resposta
  → Regex de detecção tem falsos negativos
  → Cliente pode receber duas mensagens contraditórias

CAUSA 3 — confirm_scheduling depende de slots disponíveis:
  Se get_proximos_slots_disponiveis() não consulta Calendar real
  → Double-booking possível
  → Agendamento criado mas conflita com compromisso existente

CAUSA 4 — Sem handoff automático:
  Quando confusion_count >= 2, apenas alerta via Slack
  → Nenhuma ação automática de escalação para consultor
  → Fluxo trava sem resolução

CAUSA FUNDAMENTAL: Falta de mecanismo de escalação automática e verificação
real de disponibilidade no Google Calendar.
```

---

### PROBLEMA 4: Lead não mantém continuidade

**Sintoma:** Cliente que retorna após horas/dias é tratado como novo cliente.

**Causa Raiz:**

```
CAUSA 1 — Triagem falha → is_new_lead=True (mais comum):
  Timeout ou rate limit do qwen free → exceção → return fallback
  → Fallback sempre retorna is_new_lead=True
  → Cliente recorrente vira "novo lead"

CAUSA 2 — Sessão de banco expirada em BackgroundTask:
  A db session passada para BackgroundTask pode estar expirada
  → get_lead_context_by_wa_id falha silenciosamente
  → Triagem retorna lead vazio → is_new_lead=True

CAUSA 3 — telefone_hash inconsistente (raro):
  Se HASH_KEY muda (rotação de chave), o hash do mesmo telefone muda
  → upsert_lead_with_resilience não encontra lead existente
  → Cria novo lead duplicado

CAUSA FUNDAMENTAL: Triagem com modelo gratuito (rate limited) + fallback
que sempre retorna is_new_lead=True + falta de fallback direto ao DB.
```

**Fix:**
1. Fallback da triagem deve consultar o DB diretamente (sem LLM):
   ```python
   except Exception:
       # Fallback: busca direta ao DB sem usar TriagemAgent
       lead_db = await lead_repo.get_by_phone_hash(wa_id)
       if lead_db:
           briefing_db = await briefing_repo.get_by_lead(lead_db.id)
           return build_triagem_from_db(lead_db, briefing_db)
       return DEFAULT_NEW_LEAD_TRIAGEM
   ```

---

### PROBLEMA 5: Google Calendar não conclui o fluxo

**Sintoma:** Agendamento criado no DB mas sem Meet link, ou falha silenciosa.

**Causa Raiz:**

```
CAUSA 1 — Credenciais não configuradas:
  GOOGLE_SERVICE_ACCOUNT_PATH não existe
  → _build_service() retorna None
  → criar_evento_curadoria() retorna None
  → meet_link=NULL no DB
  → Cliente não recebe link

CAUSA 2 — Disponibilidade não verificada no Calendar real:
  get_proximos_slots_disponiveis() pode não consultar Calendar
  → Slots oferecidos podem já estar ocupados
  → Double-booking ocorre

CAUSA 3 — Event ID não persistido:
  Google Calendar cria evento com ID único
  → ID não é salvo no banco
  → Impossível atualizar/cancelar o evento depois

CAUSA FUNDAMENTAL: Credenciais Google não configuradas em ambiente de 
desenvolvimento/staging + falta de persistência do event_id.
```

---

### PROBLEMA 6: IA deduz informações incorretamente

**Sintoma:** Além de "lua de mel", a IA faz outras inferências não confirmadas.

**Causa Raiz:**

```
CAUSA 1 — RAG injetando contexto de personas:
  perfis_e_solucoes.md descreve 10 personas com "sinais de reconhecimento"
  → RAG recupera personas baseado em palavras-chave da mensagem
  → LLM absorve características da persona como fatos do cliente

Exemplo: Cliente menciona "sou aposentada" → RAG recupera PERSONA 4
→ LLM assume que a cliente quer ir a Portugal, tem medo, não fala inglês
→ Assumptions não confirmadas

CAUSA 2 — System prompt sem separação clara RAG vs fatos:
  O RAG context é injetado diretamente no system prompt
  → LLM pode confundir "exemplos de personas" com "dados deste cliente"

CAUSA 3 — few-shot examples no system prompt (destinos):
  Os exemplos de frases no system prompt incluem destinos específicos
  → Cria associações implícitas (Lisboa = lua de mel, Cancún = família)

CAUSA FUNDAMENTAL: A base de conhecimento contém personas descritivas que 
o RAG usa para contextualizar, mas o LLM as interpreta como intenções 
do cliente atual, não como guias de abordagem.
```

**Fix:**
1. Reformular `perfis_e_solucoes.md` para deixar claro que são guias de abordagem, não características assumidas
2. Adicionar aviso explícito no RAG context: `"[GUIAS DE ATENDIMENTO — NÃO ASSUMA SOBRE O CLIENTE ATUAL]"`
3. Adicionar regra no system prompt: "NUNCA assuma características do cliente baseado em palavras-chave"

---

### PROBLEMA 7: WhatsApp não executa o ciclo completo

**Sintoma:** Ciclo completo (briefing → qualificação → agendamento → Meet) frequentemente falha em algum ponto.

**Causa Raiz:**

```
CAUSA 1 — Estado distribuído inconsistente:
  Cada componente tem seu estado (DB, Redis in-memory, LangGraph state)
  → Sem sincronização, podem divergir

CAUSA 2 — Ausência de idempotência no webhook:
  Meta re-tenta webhooks em falha → mensagem processada múltiplas vezes
  → Briefs duplicados, respostas duplicadas

CAUSA 3 — Falta de transaction coordinator:
  persist_lead_data cria commits internos no LangGraph
  → Se o processo falha após o commit mas antes do reply WhatsApp
  → Briefing atualizado mas cliente não recebeu confirmação
  → Na próxima mensagem, o estado parece avançado mas o cliente não sabe

CAUSA FUNDAMENTAL: Ausência de idempotência e ausência de compensating 
transactions para falhas parciais.
```

---

## 2. MATRIZ PRIORIDADE × ESFORÇO

| Problema | Impacto | Esforço Fix | Prioridade |
|----------|---------|-------------|-----------|
| Inferência "lua de mel" | ALTO | BAIXO | 🔴 Crítica |
| Campo `ocasiao` no briefing | ALTO | BAIXO | 🔴 Crítica |
| Fallback da triagem (DB direto) | ALTO | MÉDIO | 🔴 Crítica |
| Janela de contexto [-6:] → [-10:] | MÉDIO | BAIXO | 🟡 Alta |
| State in-memory → Redis | MÉDIO | MÉDIO | 🟡 Alta |
| Distributed lock wa_id | MÉDIO | MÉDIO | 🟡 Alta |
| Idempotência webhook (wamid) | MÉDIO | MÉDIO | 🟡 Alta |
| Verificação Calendar real | ALTO | ALTO | 🟡 Alta |
| google_event_id persistido | MÉDIO | BAIXO | 🟡 Alta |
| RAG context com aviso de persona | BAIXO | BAIXO | 🟢 Média |
| Handoff automático para consultor | MÉDIO | ALTO | 🟢 Média |
| Notificação FCM seletiva | BAIXO | BAIXO | 🟢 Média |
| PgBouncer connection pooling | BAIXO | MÉDIO | 🟢 Média |
