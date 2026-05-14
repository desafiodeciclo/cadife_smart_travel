# 12 — SCALABILITY AND CONCURRENCY
## Cadife Smart Travel — Análise de Escalabilidade e Concorrência
**Data:** 2026-05-14 | **Versão:** 1.0.0

---

## 1. GARGALOS DE ESCALABILIDADE IDENTIFICADOS

### 1.1 Estado em Memória de Processo (Crítico)

Existem 4 estruturas de dados em memória que impedem escalabilidade horizontal:

| Estrutura | Localização | Problema |
|-----------|------------|---------|
| `_rag_cache` | `multi_agent_orchestrator.py` | Cache duplicado por worker |
| `_field_repetition_tracker` | `multi_agent_orchestrator.py` | Contador não compartilhado |
| `_memory_store` | `ai_service.py` | Memória isolada por worker |
| `_compiled_graph` | `multi_agent_orchestrator.py` | OK — stateless, pode ser compartilhado |

Com `uvicorn --workers 4`:
- 4 caches RAG independentes
- 4 confusion trackers independentes
- 4 memory stores independentes

### 1.2 BackgroundTask vs Kafka (em Desenvolvimento)

```python
# Dev: KAFKA_ENABLED=false → BackgroundTasks (compartilha loop de eventos)
# Prod: KAFKA_ENABLED=true → Kafka (isolado)
```

**Problema de desenvolvimento:** BackgroundTasks competem com requests HTTP pelo mesmo event loop asyncio. Sob carga, a responsividade do webhook pode ser comprometida por processamentos IA pesados em background.

**Impacto em produção:** Com Kafka habilitado, esse problema não existe — consumers são processos separados.

### 1.3 ChromaDB Local

```bash
CHROMA_PERSIST_DIR=./chroma_db
```

ChromaDB local (SQLite/DuckDB em disco) não escala horizontalmente. Múltiplas instâncias da aplicação competem pelo mesmo arquivo de banco de dados.

**Problema:** Em produção com múltiplas instâncias, ChromaDB local não é viável.

**Solução:** Migrar para ChromaDB HTTP server (separado, com múltiplos clients) ou PGVector (PostgreSQL extension, já mencionado no CLAUDE.md como plano para prod).

### 1.4 Google Calendar (Síncrono em Thread Executor)

```python
# google_calendar_service.py
return await asyncio.get_event_loop().run_in_executor(
    None,
    _criar_evento_sync,
    ...
)
```

A API `googleapiclient` é síncrona — executada em thread pool via `run_in_executor`. O pool de threads padrão do Python (`ThreadPoolExecutor`) tem limite baseado em CPU count. Sob alta carga de agendamentos, esse pool pode saturar.

---

## 2. ANÁLISE DE CONCORRÊNCIA

### 2.1 Race Condition: Mensagens Simultâneas do Mesmo Lead

**Cenário:**
```
T=0: Mensagem A chega → BackgroundTask-A inicia
T=0.1: Mensagem B chega → BackgroundTask-B inicia
T=1: BackgroundTask-A lê histórico [msg1, msg2, msg3]
T=1: BackgroundTask-B lê histórico [msg1, msg2, msg3] (idêntico — B ainda não viu A)
T=3: BackgroundTask-A processa → persiste interação com resposta-A
T=3: BackgroundTask-B processa → persiste interação com resposta-B (sem ver resposta-A)
```

**Resultado:**
- O cliente recebe duas respostas (A e B)
- A histórico ficará: [msg1, msg2, msg3, A, B] — em qualquer ordem
- A próxima mensagem verá as respostas A e B como se fossem independentes

**Frequência:** Alta — usuários WhatsApp frequentemente enviam múltiplas mensagens consecutivas.

**Solução:** Distributed lock por `wa_id` no Redis:
```python
async with redis.lock(f"wa_lock:{wa_id}", timeout=30, blocking_timeout=10):
    await process_whatsapp_message.execute(payload, db)
```

### 2.2 Race Condition: persist_lead_data Concorrente

**Cenário com Kafka (múltiplos consumers):**
```
Consumer-1 processa Mensagem-A → persist_lead_data(destino="Lisboa")
Consumer-2 processa Mensagem-B → persist_lead_data(perfil="casal")
```

**Risco:** Se ambos fazem upsert do briefing simultâneo, um pode sobrescrever o campo do outro (dependendo da implementação do upsert).

**Solução:** Upsert campo a campo com `COALESCE` ou `ON CONFLICT DO UPDATE SET field = EXCLUDED.field WHERE briefing.field IS NULL`.

### 2.3 Race Condition: Notificação FCM Duplicada

**Cenário:**
```
Mensagem-A → lead atinge 60% → enfileira notificação FCM
Mensagem-B (simultânea) → lead ainda 60% → enfileira notificação FCM (duplicata)
```

**Mitigação atual:** `notification_debounce_service.py` com 60s de debounce.

**Problema:** O debounce em Redis usa `SET NX` (set if not exists)? Se sim, é atômico e correto. Se não, há race condition no próprio debounce.

---

## 3. LIMITES DE CONCORRÊNCIA ATUAIS

### 3.1 Banco de Dados (PostgreSQL)

```python
# database.py — configuração do pool
# Pool padrão SQLAlchemy: 5 conexões ativas + 10 overflow
```

Para produção com múltiplas instâncias da aplicação:
```
4 workers uvicorn × 15 conexões pool = 60 conexões ao DB
+ Kafka consumers = +N conexões
```

PostgreSQL por padrão aceita 100 conexões simultâneas. Risco de esgotamento com escala horizontal.

**Solução:** PgBouncer como connection pooler externo.

### 3.2 Redis (Conexões)

Redis é single-threaded mas altamente eficiente. O gargalo é o número de conexões abertas, não a capacidade de processamento. Com asyncio, uma única conexão Redis pode ser multiplexada eficientemente.

### 3.3 Kafka (Consumer Throughput)

```
Partições: 3 (estimado)
Consumers: 1 por partição
Throughput máximo: ~30 msg/s por partição = ~90 msg/s total
```

O throughput de 90 msg/s é mais que suficiente para um MVP. Para escala, adicionar partições e consumers.

---

## 4. ANÁLISE DE THROUGHPUT END-TO-END

### 4.1 Bottleneck Atual

```
Tempo de processamento por mensagem:
├── Triagem (qwen free): 2-8s
├── RAG: 100-500ms
├── Orchestrator (gemini-flash): 3-10s
├── DB operations: 100-300ms
└── WhatsApp send: 200-800ms

Total: ~6-20s por mensagem
```

Com 1 worker processando mensagens do mesmo lead em série:
```
Throughput por lead: 3-10 mensagens/minuto
Throughput global: depende do número de leads ativos simultâneos
```

### 4.2 Limitações de Rate nos LLMs

```
OPENROUTER_MODEL=google/gemini-2.0-flash-001
Rate limit: dependente do plano OpenRouter

OPENROUTER_TRIAGEM_MODEL=qwen/qwen-2.5-72b-instruct:free
Rate limit: limitado (modelo gratuito) — potencial de 429s
```

Os modelos gratuitos (qwen free, llama free) têm rate limits muito mais restritivos. Em escala, o sistema vai sofrer 429 frequentemente no agente de triagem.

**Solução:** Migrar triagem para modelo pago com rate limit adequado ao volume esperado.

---

## 5. PLANO DE ESCALABILIDADE

### 5.1 Escala Atual (MVP)

```
Capacidade estimada atual:
- 100-500 leads ativos simultâneos
- 1000-5000 mensagens/dia
- 1 instância uvicorn + 4 workers
```

### 5.2 Escala Curto Prazo

```
Para 5000-20000 leads:
- Migrar state in-memory → Redis
- PgBouncer para connection pooling
- ChromaDB HTTP server separado
- 2-3 instâncias da aplicação
- Kafka com mais partições
```

### 5.3 Escala Médio Prazo

```
Para 20000-100000 leads:
- PGVector (Postgres extension) em vez de ChromaDB
- Dedicated AI workers (processos separados para pipeline LangGraph)
- Redis Cluster
- PostgreSQL read replicas
- CDN para assets estáticos
```

---

## 6. SUMÁRIO DE PROBLEMAS DE CONCORRÊNCIA

| Problema | Severidade | Solução |
|----------|-----------|---------|
| Estado in-memory (4 estruturas) | Alta | Migrar para Redis |
| Mensagens simultâneas do mesmo lead | Alta | Distributed lock Redis por wa_id |
| ChromaDB local com múltiplas instâncias | Média | ChromaDB HTTP ou PGVector |
| ThreadPoolExecutor para Google Calendar | Média | google-cloud-calendar async |
| Rate limit modelos gratuitos | Alta | Migrar triagem para modelo pago |
| Connection pool DB em escala | Média | PgBouncer |
| Debounce FCM atômico | Média | Verificar SET NX no Redis |
