# 04 — MEMORY AND CONTEXT ANALYSIS
## Cadife Smart Travel — Análise de Memória, Contexto e Continuidade
**Data:** 2026-05-14 | **Versão:** 1.0.0

---

## 1. ARQUITETURA DE MEMÓRIA ATUAL

O sistema utiliza três camadas de memória:

```
┌─────────────────────────────────────────────────────────┐
│ CAMADA 1 — MEMÓRIA CURTA (LangChain SimpleWindowMemory) │
│   · k=20 interações mais recentes                       │
│   · In-process (por wa_id)                              │
│   · Perdida ao reiniciar o processo                     │
│   · Reload do DB a cada request                         │
└─────────────────────────────────────────────────────────┘
              ↓ Quando buffer transborda
┌─────────────────────────────────────────────────────────┐
│ CAMADA 2 — MEMÓRIA COMPRIMIDA (LLM Summary)             │
│   · Resumo das interações antigas                       │
│   · Injetado no system prompt como "HISTÓRICO ANTERIOR" │
│   · Qualidade dependente do LLM de resumo               │
│   · Persistido em conversation_summary no PostgreSQL    │
└─────────────────────────────────────────────────────────┘
              ↓ Persistência long-term
┌─────────────────────────────────────────────────────────┐
│ CAMADA 3 — MEMÓRIA LONGA (PostgreSQL + ChromaDB)        │
│   · Briefing estruturado (tabela briefing)              │
│   · Histórico de interações (tabela interacao)          │
│   · Resumo de conversa (tabela conversation_summary)    │
│   · Embeddings RAG (ChromaDB — base de conhecimento)   │
└─────────────────────────────────────────────────────────┘
```

---

## 2. CAMADA 1 — SimpleWindowMemory

### 2.1 Implementação

```python
# process_whatsapp_message.py:99-101
interacoes_list = await lead_service.get_recent_interacoes(db, lead_id, limit=20)
ai_service.preload_memory_from_db(phone, interacoes_list)
_memory = ai_service.get_memory(phone)
_memory_summary = _memory._summary  # Resumo comprimido (vazio se buffer não transbordou)
```

```python
# _node_orchestrator — usa os últimos 6 turnos do histórico
messages.extend(state["conversation_history"][-6:])
```

### 2.2 Problemas Identificados

**PROBLEMA CRÍTICO — Janela de contexto insuficiente:**

O orchestrador usa `conversation_history[-6:]` — apenas os **últimos 6 turnos** (3 pares usuário/IA). Em um briefing completo:

```
Turno 1: "Olá, quero viajar"          → AYA: "Olá! Destino em mente?"
Turno 2: "Lisboa, Portugal"            → AYA: "Ótimo! Para quando?"
Turno 3: "Julho, duas semanas"         → AYA: "Quantas pessoas?"
Turno 4: "Eu e minha esposa"          → AYA: "Perfil?"
Turno 5: "Somos um casal"             → AYA: "Orçamento?"
Turno 6: "Médio"                       → AYA: "Passaporte?"       ← aqui o [-6:] começa
Turno 7: "Sim, temos"                  → AYA: "Perfeito!" [agenda]
```

**O destino "Lisboa" (Turno 2) já saiu da janela [-6:] no Turno 7!**

Se por alguma razão `persist_lead_data` não foi chamada no Turno 2, o destino pode ser perdido. O CRM_BLOCK ajuda (traz dados do DB), mas depende de persistência prévia.

**PROBLEMA MÉDIO — Memory state em processo:**

```python
# ai_service.py — dicionário global em memória
_memory_store: dict[str, SimpleWindowMemory] = {}
```

Com múltiplos workers uvicorn, cada processo tem sua própria memória. O cliente pode ser processado por workers diferentes em requisições consecutivas, resultando em:
- Memória não compartilhada entre workers
- Reload do DB a cada requisição (correto, mas ineficiente)
- Possível inconsistência no `_summary` entre workers

### 2.3 Reload do Histórico (Mitigação Parcial)

```python
# process_whatsapp_message.py — antes do orchestrador
interacoes_list = await lead_service.get_recent_interacoes(db, lead_id, limit=20)
ai_service.preload_memory_from_db(phone, interacoes_list)
```

**Avaliação positiva:** O reload do DB a cada requisição garante que mesmo após restart ou mudança de worker, o histórico é reconstruído. Isso é correto.

**Porém:** O `preload_memory_from_db` recria a memória a partir do DB, mas o `_summary` (resumo comprimido) é regenerado, não carregado — pode haver divergência se o summary foi gerado com uma versão anterior das mensagens.

---

## 3. CAMADA 2 — MEMÓRIA COMPRIMIDA (SUMMARY)

### 3.1 Implementação

```python
_memory_summary = _memory._summary
```

O `_summary` é gerado pelo `SimpleWindowMemory` quando o buffer de `k=20` transborda. Um LLM comprime as mensagens mais antigas em um resumo textual.

### 3.2 Problemas

**PROBLEMA — Qualidade do resumo não auditada:**

O resumo é injetado no system prompt mas não há garantia de que:
- Informações críticas (destino, datas, número de pessoas) estão presentes no resumo
- O resumo não introduz inferências incorretas (ex: assumiu "lua de mel" durante a compressão)
- O resumo está atualizado com a última interação

**PROBLEMA — conversation_summary vs _summary:**

O banco tem uma tabela `conversation_summary` mas o código usa `_memory._summary` (in-memory). Não está claro se esses dois estão sincronizados. O job `conversation_summary_retry_job` sugere que há uma lógica de persistência do resumo que pode falhar.

---

## 4. CAMADA 3 — MEMÓRIA LONGA (POSTGRESQL)

### 4.1 Briefing Como Memória Persistente

```python
# process_whatsapp_message.py:116-142
_briefing_pre = await BriefingRepository(db).get_by_lead(lead_id)
if _briefing_pre:
    _pre_validated_briefing = {
        "completude_pct": _briefing_pre.completude_pct,
        "destino": _briefing_pre.destino,
        ...
    }
```

**Avaliação positiva:** O briefing pré-carregado antes do grafo é a estratégia mais confiável de memória. Dados confirmados e persistidos são mais confiáveis que histórico de conversa.

### 4.2 Recuperação para Retomada de Conversa

```python
# _build_crm_block — logic de saudação baseada em horas
hours_elapsed >= 48:  → "RETOMADA APÓS LONGA PAUSA: O cliente estava na fase de '{fase}'..."
hours_elapsed >= 24:  → "RETOMADA APÓS {h}H: ..."
hours_elapsed < 24:   → "SEM SAUDAÇÃO: Conversa ativa..."
```

**Avaliação positiva:** A lógica de saudação baseada em tempo decorrido está bem implementada. O sistema distingue corretamente:
- Conversa ativa (sem saudação)
- Retomada após 1-2 dias (menção direta à fase)
- Retomada após 2+ dias (oferece escolha entre continuar ou recomeçar)

### 4.3 Fluxo de Retomada Ideal (Comportamento Esperado)

**Cenário:** Cliente com briefing 40% completo retorna após 3 dias.

**Comportamento esperado:**
```
"Oi [Nome]! Tudo bem? Faz um tempinho que a gente não se falava 😊
Eu estava por aqui lembrando que a gente tinha parado na escolha do orçamento.
Quer continuar de onde a gente estava ou prefere recomeçar do zero?"
```

**Comportamento atual potencial (se triagem falhar):**
```
"Olá! Sou a AYA da Cadife Tour. Vou te ajudar a organizar sua próxima viagem!
Já tem um destino em mente?"
```

**Causa:** Falha silenciosa da triagem → `is_new_lead=True` → saudação de primeiro contato.

---

## 5. ANÁLISE DO FLUXO DE RETOMADA DE LEAD

### 5.1 Diagrama de Estado Correto

```
Cliente retorna
       │
       ▼
Triagem busca lead no DB
       │
       ├─ Lead existe → last_interaction_at calculado
       │       │
       │       ├─ < 24h → sem saudação, continua direto
       │       ├─ 24-48h → saudação breve + fase atual
       │       └─ > 48h → saudação calorosa + oferta escolha
       │
       └─ Lead não existe → saudação de primeiro contato
```

### 5.2 Problema: Timestamp Duplicado

```python
# process_whatsapp_message.py
_last_interaction_at: str | None = None
if interacoes_list:
    _last_ts = interacoes_list[-1].get("timestamp")
    if _last_ts is not None:
        _last_interaction_at = _last_ts.isoformat() ...
```

E também:
```python
# _build_crm_block
effective_last_interaction = override_last_interaction_at or triagem.get("last_interaction_at")
```

**Avaliação positiva:** O timestamp vindo do DB (`override_last_interaction_at`) tem prioridade sobre o timestamp que o TriagemAgent extrai do histórico. Isso é correto — o DB é a fonte de verdade.

**Risco:** Se `interacoes_list` está vazio (lead sem interações), `_last_interaction_at` será None → `hours_elapsed` será None → `should_greet=True` → saudação de primeiro contato. Para leads criados manualmente (sem interações), isso é correto. Para leads cujas interações foram excluídas incorretamente, pode ser problema.

---

## 6. ANÁLISE DE RACE CONDITIONS NA MEMÓRIA

### 6.1 Cenário: Duas mensagens simultâneas

```
Mensagem A → processa → preload_memory(phone) → [A1, A2, A3]
Mensagem B → processa → preload_memory(phone) → [A1, A2, A3]  ← lê mesmo estado
                                                        ↓
Mensagem A → salva interação → [A1, A2, A3, A]
Mensagem B → salva interação → [A1, A2, A3, B]  ← A foi salvo mas B não viu A
```

**Resultado:** As respostas de A e B podem ser inconsistentes, pois nenhuma delas "viu" a outra mensagem no histórico.

### 6.2 Cenário: Persist_lead_data simultâneo

Se A e B ambas tentam chamar `persist_lead_data` com campos diferentes do briefing, pode haver sobrescrita:
- A persiste: `destino="Lisboa"`, `data_ida="2026-07-01"`
- B persiste: `destino="Lisboa"`, `data_ida=None` (não sabia da data)

O upsert do briefing precisa fazer merge campo a campo, não overwrite completo.

---

## 7. ESTRATÉGIA RECOMENDADA DE MEMÓRIA

### 7.1 Melhorias Imediatas (sem refatoração)

1. **Aumentar janela do orchestrador**: `conversation_history[-6:]` → `[-10:]`
2. **Adicionar hash de consistência ao CRM_BLOCK**: incluir `completude_pct` atual para que o LLM saiba o estado exato

### 7.2 Melhorias de Médio Prazo

3. **Mover memory store para Redis**: `_memory_store` em Redis com TTL de 2h, compartilhado entre workers
4. **Persistir o summary no PostgreSQL**: usar `conversation_summary` como fonte de verdade do resumo
5. **Distributed lock por wa_id**: evitar processamento simultâneo de mensagens do mesmo lead

### 7.3 Melhorias de Longo Prazo

6. **Episodic memory com vector search**: em vez de resumo comprimido, armazenar episódios como embeddings — o RAG recupera os mais relevantes para o contexto atual
7. **Structured memory graph**: representar o estado conversacional como grafo de entidades (lead → destino → datas → pessoas), mais robusto que histórico de texto

---

## 8. TABELA DE STATUS

| Aspecto | Status | Qualidade |
|---------|--------|-----------|
| Histórico DB reload | ✅ Implementado | Boa |
| CRM block com dados do briefing | ✅ Implementado | Boa |
| Saudação baseada em tempo decorrido | ✅ Implementado | Boa |
| Briefing pré-carregado (bypass tool) | ✅ Implementado | Boa |
| Memory summary (compressão) | ✅ Implementado | Média |
| Persistência do summary | ⚠️ Parcial | Média |
| Janela de contexto orquestrador | ⚠️ Apenas [-6:] | Insuficiente |
| Memory store compartilhado entre workers | ❌ Ausente | Crítico |
| Distributed lock para mensagens simultâneas | ❌ Ausente | Crítico |
| Merge de campos no briefing upsert | ⚠️ A verificar | Importante |
