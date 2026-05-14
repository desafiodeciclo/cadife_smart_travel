# 06 — REDIS AND CACHE ANALYSIS
## Cadife Smart Travel — Análise de Redis e Camada de Cache
**Data:** 2026-05-14 | **Versão:** 1.0.0

---

## 1. ARQUITETURA DE CACHE ATUAL

```
┌─────────────────────────────────────────────┐
│  REDIS (redis[hiredis])                     │
│  · Sessões JWT (token revogation)           │
│  · Rate limiting (slowapi)                  │
│  · Notification debounce (60s TTL)          │
│  · APScheduler locks (job deduplication)    │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  IN-MEMORY (por processo)                   │
│  · RAG cache (_rag_cache dict)              │
│  · Confusion tracker (_field_repetition)    │
│  · Memory store (_memory_store)             │
│  · Compiled LangGraph (_compiled_graph)     │
└─────────────────────────────────────────────┘
```

---

## 2. CLIENTE REDIS

### 2.1 Implementação

```python
# infrastructure/cache/redis_client.py
# Lazy-initialized async Redis singleton
# Health check helper
# TTL-based cache invalidation
```

### 2.2 Configuração

```bash
REDIS_URL=redis://host:port/db
# Alternativas:
REDIS_HOST=
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0
REDIS_PREFIX=DEV_  # ou STAGING_, PROD_
```

**Avaliação:** Singleton pattern é correto para conexões Redis. A separação por prefixo (DEV_, STAGING_, PROD_) evita colisões entre ambientes.

### 2.3 Degradação Graciosa

O sistema tolera Redis indisponível para a maioria dos usos (rate limit falha aberto, cache miss, etc.). Não há ponto de falha crítico que pare o sistema se o Redis cair.

**Exceção:** O APScheduler usa Redis para locks de jobs — sem Redis, jobs podem ser executados em duplicata em ambientes multi-instância.

---

## 3. USOS DO REDIS

### 3.1 Rate Limiting (slowapi)

```python
# security/rate_limiter.py
RATE_LIMIT_WEBHOOK=100/minute
RATE_LIMIT_IA=30/minute
RATE_LIMIT_DEFAULT=60/minute
```

**Avaliação:** Configurado e implementado. Os limites são adequados para o volume esperado.

**Problema identificado:** O rate limiting usa IP como chave por padrão. Para o webhook da Meta, todos os requests vêm do IP da Meta — o rate limit efetivo é shared entre todos os clientes da Cadife, não por cliente individual.

**Solução:** Usar `wa_id` (telefone) como chave de rate limit para o webhook, não o IP.

### 3.2 Notification Debounce

```python
# notification_debounce_service.py
# Debounce de 60s entre notificações do mesmo lead
```

**Avaliação:** Correto — evita spam de notificações FCM para o mesmo lead em rajadas de mensagens.

### 3.3 APScheduler Locks

O APScheduler usa Redis para garantir que jobs periódicos não sejam executados em paralelo por múltiplas instâncias.

**Avaliação:** Essencial para ambientes multi-instância. Sem isso, `lead_expiration_job` poderia arquivar os mesmos leads múltiplas vezes.

---

## 4. CACHE IN-MEMORY — ANÁLISE CRÍTICA

### 4.1 RAG Cache

```python
# multi_agent_orchestrator.py
_rag_cache: dict[str, tuple[str, float]] = {}
_RAG_CACHE_TTL_S = 1800  # 30 minutos
_RAG_CACHE_MAX_SIZE = 500
```

**Problema 1 — Multi-worker inconsistência:**

Com `uvicorn --workers 4`, cada processo tem seu próprio `_rag_cache`. A query `"Lisboa portugal lua de mel"` pode ser feita no ChromaDB 4 vezes (uma por worker) em vez de ser cacheada.

**Problema 2 — Memory leak potencial:**

O eviction é feito em `_rag_cache_evict()` chamado antes de cada inserção. Se o sistema receber queries muito variadas (muitos `wa_id` diferentes com queries únicas), o cache pode crescer até `_RAG_CACHE_MAX_SIZE=500` entradas antes de eviction.

**Problema 3 — Cache invalidation:**

Quando novos documentos são ingeridos na base de conhecimento (`ingestion_pipeline`), o `_rag_cache` em memória NÃO é invalidado. Respostas stale podem ser servidas por até 30 minutos após atualização da base.

**Solução:** Migrar para Redis com TTL:
```python
async def get_rag_context(cache_key: str) -> str | None:
    return await redis.get(f"rag:{cache_key}")

async def set_rag_context(cache_key: str, ctx: str, ttl: int = 1800) -> None:
    await redis.setex(f"rag:{cache_key}", ttl, ctx)
```

### 4.2 Confusion Tracker

```python
# multi_agent_orchestrator.py
_field_repetition_tracker: dict[str, tuple[str, int]] = {}
```

**Problema 1 — Multi-worker:**
Contadores de confusão não são compartilhados entre workers. Um lead pode ficar preso no mesmo campo por 6 tentativas (3 em cada worker) antes de qualquer alerta ser disparado.

**Problema 2 — Memory leak:**
Leads inativos acumulam entradas indefinidamente. A única limpeza ocorre quando `next_field="completo"`, mas leads abandonados nunca chegam a esse estado.

**Problema 3 — Restart:**
Reinício do processo zera todos os contadores — qualquer detecção de confusão em andamento é perdida.

**Solução:**
```python
# Redis com TTL de 24h por wa_id
CONFUSION_KEY = "confusion:{wa_id}"
await redis.hincrby(CONFUSION_KEY, "stuck_field", 1)
await redis.expire(CONFUSION_KEY, 86400)  # 24h TTL
```

### 4.3 Memory Store (SimpleWindowMemory)

```python
# ai_service.py
_memory_store: dict[str, SimpleWindowMemory] = {}
```

**Problema — Multi-worker + Restart:**
Mesmos problemas do confusion tracker. Porém este tem uma mitigação: `preload_memory_from_db` recria a memória do DB a cada request.

**Avaliação:** A recriação do DB mitiga o problema de multi-worker, mas adiciona latência extra (query ao DB + reconstrução dos objetos LangChain).

### 4.4 Compiled LangGraph

```python
# multi_agent_orchestrator.py
_compiled_graph = None

def _get_graph():
    global _compiled_graph
    if _compiled_graph is None:
        _compiled_graph = _build_graph()
    return _compiled_graph
```

**Avaliação positiva:** O grafo compilado é cacheado por processo e recriado apenas quando None. Isso é correto — o grafo é stateless e pode ser compartilhado entre requisições do mesmo processo.

**Sem problemas identificados** neste cache específico.

---

## 5. TTLs E POLÍTICAS DE EXPIRAÇÃO

| Cache | Tipo | TTL | Problema |
|-------|------|-----|----------|
| RAG context | In-memory | 30 min | Multi-worker, sem invalidação |
| Confusion tracker | In-memory | Indefinido | Memory leak para leads inativos |
| Memory store | In-memory | Indefinido | Memory leak, mas reload do DB |
| Notification debounce | Redis | 60s | OK |
| Rate limit counters | Redis | 1 min | OK |
| JWT (refresh tokens) | Redis | 7 dias | OK |
| APScheduler locks | Redis | Job TTL | OK |

---

## 6. RACE CONDITIONS COM REDIS

### 6.1 Cenário: Lock de lead para processamento

**Problema atual:** Não há Redis distributed lock para serializar o processamento de mensagens do mesmo `wa_id`.

**Consequência:** Mensagens enviadas rapidamente (ex: 3 mensagens em 1 segundo) podem ser processadas em paralelo com histórico inconsistente.

**Solução:**
```python
from redis.asyncio import Redis
from contextlib import asynccontextmanager

@asynccontextmanager
async def lead_processing_lock(redis: Redis, wa_id: str, ttl: int = 30):
    lock = redis.lock(f"lead_lock:{wa_id}", timeout=ttl)
    try:
        await lock.acquire()
        yield
    finally:
        await lock.release()

# Uso:
async with lead_processing_lock(redis_client, wa_id):
    await process_whatsapp_message.execute(payload, db)
```

### 6.2 Cenário: Notificação FCM duplicada

**Problema atual:** O debounce (60s) pode falhar em multi-instância se duas instâncias processarem a mesma qualificação simultaneamente (TOCTOU — time-of-check time-of-use).

**Solução:** Usar Redis `SET NX EX` (set if not exists com TTL) como atomic lock:
```python
was_set = await redis.set(f"notif:{lead_id}", "1", nx=True, ex=60)
if was_set:
    await send_notification(...)
```

---

## 7. RECOMENDAÇÕES

### 7.1 Imediatas

1. **Migrar `_rag_cache` para Redis** — compartilhamento entre workers + invalidação após ingestion
2. **Migrar `_field_repetition_tracker` para Redis** — com TTL de 24h por `wa_id`
3. **Implementar distributed lock por `wa_id`** — serializar processamento de mensagens

### 7.2 Médio Prazo

4. **Rate limit por `wa_id` no webhook** — não por IP (que é sempre o IP da Meta)
5. **Atomicidade na notificação FCM** — usar `SET NX EX` para eliminar race condition de duplicata
6. **Cache de briefing em Redis** — evitar query ao DB antes de cada request (TTL de 5 min, invalidado ao salvar)

### 7.3 Longo Prazo

7. **Redis Cluster** para alta disponibilidade
8. **Redis Streams** como alternativa leve ao Kafka para mensagens WhatsApp
9. **Redis Search** para cache mais inteligente de queries RAG similares (fuzzy matching)
