# AUDITORIA TÉCNICA — ARQUITETURA DE INTELIGÊNCIA ARTIFICIAL
## Cadife Smart Travel — AYA (Assistente de Viagens Automática)

> **Classificação:** Documento Interno — Confidencial  
> **Data:** Maio de 2026  
> **Versão:** 1.0.0  
> **Escopo:** Backend FastAPI — Arquitetura completa de IA, RAG, Agentes e Segurança  
> **Auditor:** Arquiteto Principal de IA — Claude Sonnet 4.6  

---

## SUMÁRIO EXECUTIVO

O sistema Cadife Smart Travel implementa um assistente de IA conversacional chamado **AYA** integrado ao WhatsApp Cloud API. A arquitetura combina um orquestrador multi-agente baseado em **LangGraph**, sistema RAG híbrido com **PGVector**, proteção de prompt injection com 163+ padrões multilíngues, e pipeline assíncrono completo com FastAPI e APScheduler.

O sistema demonstra maturidade técnica acima da média para um MVP de 25 dias, com pontos fortes evidentes em segurança defensiva, observabilidade e resiliência. Porém apresenta gargalos arquiteturais críticos que precisam ser endereçados antes de escalar para produção de alto volume.

### Scores Técnicos Globais

| Dimensão | Score | Classificação |
|----------|-------|---------------|
| Maturidade de IA | 7.2 / 10 | **Bom** |
| Segurança | 8.1 / 10 | **Muito Bom** |
| Escalabilidade | 4.8 / 10 | **Crítico** |
| Observabilidade | 6.5 / 10 | **Regular** |
| Resiliência / Fallback | 7.0 / 10 | **Bom** |
| Qualidade de Código | 8.0 / 10 | **Muito Bom** |
| **SCORE GERAL** | **6.9 / 10** | **Regular-Bom** |

---

## PARTE 1 — VISÃO GERAL DA ARQUITETURA DE IA

### 1.1 Mapa Completo da Arquitetura

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║                        CADIFE SMART TRAVEL — ARQUITETURA DE IA                 ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║                                                                                  ║
║  CAMADA DE ENTRADA:                                                              ║
║  WhatsApp Cloud API (Meta)                                                       ║
║    └── POST /webhook/whatsapp → FastAPI                                          ║
║         ├── Middleware: RequestId, Timeout, AuditTrail, SecurityHeaders         ║
║         ├── HMAC-SHA256 (X-Hub-Signature-256)                                   ║
║         ├── HTTP 200 IMEDIATO (< 5s SLA Meta)                                   ║
║         └── Rate Limit: slowapi + Redis                                          ║
║                                                                                  ║
║  CAMADA DE PROCESSAMENTO — IA:                                                   ║
║    BackgroundTasks → ProcessWhatsAppMessage (UseCase)                            ║
║      └── LangGraph StateGraph — 7 nós:                                           ║
║           [1] security_gate   → 163 regex, 7 idiomas, Unicode norm              ║
║           [2] triagem         → TriagemAgent (Qwen3-80B free)                   ║
║           [3] rag_mandatory   → Hybrid Search (PGVector, k=4, RRF)              ║
║           [4] build_context   → XML-isolated system prompt                      ║
║           [5] orchestrator    → OrquestradorAgent (Gemini 2.0 Flash)            ║
║           [6] validate_output → Code leak + hallucination detection             ║
║           [7] confusion_track → Slack alert + latency log                       ║
║                                                                                  ║
║  CAMADA DE PERSISTÊNCIA:                                                         ║
║    PostgreSQL 16 (asyncpg, pool 10+20) | PGVector (RAG embeddings)              ║
║    Redis 7 (rate limit, cache)         | S3/LocalStack (mídia)                  ║
║    NotificationQueue (DLQ + retry exponencial)                                   ║
║                                                                                  ║
║  CAMADA DE APRESENTAÇÃO:                                                         ║
║    WhatsApp send_message() | FCM Firebase (< 2s SLA) | API REST (JWT + RBAC)    ║
║                                                                                  ║
║  PROVEDORES EXTERNOS DE IA (via OpenRouter):                                     ║
║    Gemini 2.0 Flash (chat) | Qwen3-80B (triagem, free)                          ║
║    GPT-4o Audio (transcrição) | Gemini Embedding 2 (RAG)                        ║
║    Recraft-v3 (imagens) | Llama 3.3-70B (fallback)                              ║
╚══════════════════════════════════════════════════════════════════════════════════╝
```

### 1.2 Fluxograma Lógico Completo de IA

```
Usuário (WhatsApp)
      │
      ▼
Meta Cloud API → POST /webhook/whatsapp
      │
      ├─ 1. Verificar HMAC-SHA256 (X-Hub-Signature-256)
      │      → 403 se inválido
      │
      ├─ 2. HTTP 200 IMEDIATO (SLA < 5s Meta)
      │
      └─ 3. BackgroundTasks → ProcessWhatsAppMessage
                  │
                  ├─ 4. Roteamento de mídia:
                  │      text  → direto ao orchestrator
                  │      audio → FFmpeg OGG→WAV → GPT-4o-audio → fallback Whisper
                  │      image → base64 → Gemini vision
                  │
                  ├─ 5. SECURITY GATE (pré-LLM, 0 tokens)
                  │      163 regex × 7 idiomas + Unicode normalization
                  │      → BLOCKED: SECURITY_REFUSAL_MSG → WhatsApp
                  │      → SAFE: continua
                  │
                  ├─ 6. TRIAGEM AGENT (Qwen3-80B free)
                  │      Tool: get_lead_context_by_wa_id(wa_id)
                  │      Output: {exists, nome, status, briefing, next_field}
                  │
                  ├─ 7. RAG MANDATORY (PGVector Hybrid)
                  │      Query enriquecida: +destino +perfil do briefing
                  │      Vector search (k=12) + Keyword overlap + RRF → top-4
                  │      PriceGuardrail + AvailabilityGuardrail (strategy=remove)
                  │
                  ├─ 8. BUILD CONTEXT
                  │      <system_instructions> CRM block + next_field
                  │      <rag_context> docs seguros
                  │      <user_content> input sanitizado
                  │
                  ├─ 9. ORCHESTRATOR AGENT (Gemini 2.0 Flash)
                  │      temp=0.3, max 4 tool rounds
                  │      Tools: query_project_scope, persist_lead_data,
                  │             check_availability, generate_travel_image
                  │
                  ├─ 10. VALIDATE OUTPUT
                  │       Code leak: print(, default_api., exec
                  │       Hallucination: R$, disponível, garanto vaga
                  │       → Fallback: "consultor verificará"
                  │
                  ├─ 11. CONFUSION TRACKER
                  │       Campo repetido 2x → Slack alert
                  │       Log: latency_ms, response_len, rag_size
                  │
                  └─ 12. SEND RESPONSE
                          WhatsApp send_message() + retry exponencial
                          FCM → consultor app
                          NotificationQueue (DLQ, max 3 retries)
```

### 1.3 Inventário Completo de Componentes

| Componente | Arquivo | Tecnologia |
|-----------|---------|-----------|
| Gateway Webhook | `routes/webhook.py` | FastAPI |
| Orquestrador IA | `services/multi_agent_orchestrator.py` | LangGraph |
| Agente de Triagem | `multi_agent_orchestrator.py::triagem_node` | OpenRouter/Qwen3 |
| Agente Principal | `multi_agent_orchestrator.py::orchestrator_node` | OpenRouter/Gemini |
| RAG Service | `services/rag_service.py` | PGVector + RRF |
| Pipeline Ingestão | `services/ingestion_pipeline.py` | LangChain + tiktoken |
| Security Gate | `services/prompt_security.py` | Regex multilingue |
| Context Guardrails | `services/context_guardrails.py` | Regex + Protocol |
| Model Router | `services/model_router.py` | httpx async |
| AI Tools | `services/ai_tools.py` | OpenAI function calling |
| AI Service (legado) | `services/ai_service.py` | LangChain |
| Observabilidade | `services/observability.py` | Langfuse |
| Notification Queue | `jobs/notification_worker.py` | APScheduler |
| PII Encryption | `infrastructure/security/pii_encryption.py` | Fernet + HMAC |
| Rate Limiter | `infrastructure/security/rate_limiter.py` | slowapi + Redis |
| JWT Auth | `infrastructure/security/jwt.py` | python-jose HS256 |

---

## PARTE 2 — MODELOS DE IA UTILIZADOS

### 2.1 Inventário e Análise de Modelos

**Gemini 2.0 Flash — Conversação Principal**

| Atributo | Valor |
|---------|-------|
| Provider | Google (via OpenRouter) |
| Model ID | `google/gemini-2.0-flash-001` |
| Finalidade | OrquestradorAgent — resposta conversacional |
| Custo | ~$0.10/1M input, $0.40/1M output |
| Latência | 800ms–2.5s |
| Contexto | 1M tokens |
| Function calling | Sim (OpenAI-compatible) |
| Fallback | Qwen3-80B free → Llama 3.3-70B free |
| Risco principal | Emite tool calls como texto Python (`default_api.fn()`) |

**Qwen3-80B — Triagem de Leads**

| Atributo | Valor |
|---------|-------|
| Provider | Alibaba (via OpenRouter) |
| Model ID | `qwen/qwen3-next-80b-a3b-instruct:free` |
| Finalidade | TriagemAgent — CRM lookup + classificação |
| Custo | $0.00 (free tier) |
| Latência | 1.5s–4s |
| **Risco** | **Free tier sem SLA — função crítica sem garantia** |

**GPT-4o Audio Preview — Transcrição de Áudio**

| Atributo | Valor |
|---------|-------|
| Provider | OpenAI (via OpenRouter) |
| Model ID | `openai/gpt-4o-audio-preview` |
| Finalidade | Transcrição de áudios WhatsApp |
| Pipeline | OGG/Opus → FFmpeg (subprocess) → WAV → base64 → LLM |
| Fallback | Whisper Large v3 |
| Risco | FFmpeg subprocess síncrono bloqueia o event loop asyncio |

**Gemini Embedding 2 Preview — Embeddings RAG**

| Atributo | Valor |
|---------|-------|
| Model ID | `google/gemini-embedding-2-preview` |
| Finalidade | Vetores para busca semântica RAG |
| **Risco** | **Modelo "preview" sem SLA — pode ser descontinuado sem aviso** |
| Fallback | Nenhum implementado |

**Recraft-v3 — Geração de Imagens**

| Atributo | Valor |
|---------|-------|
| Finalidade | Imagens inspiracionais de destinos |
| Custo | ~$0.04/imagem |
| Latência | 5s–15s |
| Riscos | Sem fallback, sem cache, sem filtro NSFW |

### 2.2 Tabela Comparativa de Modelos

| Modelo | Provider | Custo/1M tok | Latência | SLA | Risco |
|--------|---------|-------------|---------|-----|-------|
| Gemini 2.0 Flash | Google | $0.10/$0.40 | Baixa | Produção | Baixo |
| GPT-4o Audio | OpenAI | $2.50/$10 | Média | Produção | Baixo |
| Qwen3-80B (free) | Alibaba | $0 | Alta | **Nenhum** | **Alto** |
| Llama 3.3-70B (free) | Meta | $0 | Alta | **Nenhum** | **Alto** |
| Gemini Embed 2 | Google | Preview | Baixa | **Nenhum** | **Crítico** |
| Recraft-v3 | Recraft | $0.04/img | Alta | Produção | Médio |

> **ALERTA CRÍTICO:** Funções críticas de triagem e embeddings dependem de modelos **sem SLA garantido**.

---

## PARTE 3 — ESTRATÉGIA DE FALLBACK DE MODELOS

### 3.1 Cadeias de Fallback Atuais

```
TRIAGEM AGENT:
  Qwen3-80B:free
    ├─[200 OK]──▶ Sucesso
    └─[429/503]
          ▼
  Llama 3.3-70B:free
    ├─[200 OK]──▶ Sucesso
    └─[Falha]───▶ ⚠️ FALHA TOTAL — sem fallback final

ORCHESTRATOR AGENT:
  Gemini 2.0 Flash
    ├─[200 OK]──▶ Sucesso
    └─[429/503]
          ▼
  OPENROUTER_FALLBACK_MODEL (Qwen3-80B:free)
    ├─[200 OK]──▶ Sucesso
    └─[429/503]
          ▼
  nvidia/llama-nemotron-embed-vl-1b-v2:free
  ⚠️⚠️ MODELO DE EMBEDDINGS USADO COMO CHAT — ERRO CRÍTICO ⚠️⚠️
    └─[Qualquer]
          ▼
  Llama 3.3-70B:free
    ├─[200 OK]──▶ Sucesso
    └─[Falha]───▶ return "" (resposta vazia ao usuário)
```

### 3.2 Problemas Identificados

| Problema | Severidade |
|---------|-----------|
| `nvidia/llama-nemotron-embed-vl-1b-v2:free` como fallback de chat | **Crítico** |
| Free tier sem SLA em triagem crítica | **Alto** |
| Sem exponential backoff entre tentativas de fallback | **Alto** |
| Sem circuit breaker para isolar providers com falha | **Médio** |
| Fallback final retorna `""` (silêncio para o usuário) | **Médio** |
| Docstring desatualizado (menciona Mistral, código usa Qwen) | **Baixo** |

### 3.3 Arquitetura de Fallback Enterprise Recomendada

```python
# Model Router com Circuit Breaker + Roteamento por Intenção

ROUTING_RULES = {
    "saudacao_faq":    ["llama-3.1-8b-paid"],           # economy
    "briefing_extract": ["qwen3-14b-paid"],             # balanced
    "destino_rag":     ["gemini-2.0-flash-001"],        # premium
    "negociacao":      ["gpt-4o-mini"],                 # premium
}

# Circuit breaker: isola provider após 3 falhas em 60s
# Exponential backoff: 1s, 2s, 4s, 8s entre tentativas
# Fallback nunca usa modelo de embeddings como chat
```

---

## PARTE 4 — CHUNKING, EMBEDDINGS E SISTEMA RAG

### 4.1 Pipeline de Ingestão

```
knowledge_base/ (txt, md, pdf)
      │
      ▼ SHA256 hash check (deduplicação)
      │
      ▼ RecursiveCharacterTextSplitter
        chunk_size = 500 tokens (cl100k_base)
        chunk_overlap = 50 tokens (10%)
      │
      ▼ MetadataTagger (LLM → JSON)
        destino: Nordeste, Europa, Ásia, ...
        tema: Praias, Montanhas, Luxo, ...
        perfil: Casal, Família, Solo, ...
      │
      ▼ OpenAIEmbeddings (Gemini Embed 2 via OpenRouter)
      │
      ▼ PGVector.add_documents()
        collection: cadife_knowledge_base
```

### 4.2 Busca Híbrida — RRF

```python
# Fluxo completo de retrieval:

Vector Search (PGVector, k = query_k × 3 candidatos)
      +
Keyword Score: |query_tokens ∩ doc_tokens| / |query_tokens|
      ↓
RRF Fusion:
  score = 1/(60 + rank_vector) + 0.5/(60 + rank_keyword)
      ↓
Top-k por RRF score
      ↓
PriceGuardrail (remove chunks com R$, US$, €, preço, desconto)
AvailabilityGuardrail (remove "temos vagas", "voo confirmado")
      ↓
Contexto RAG seguro (texto concatenado)
```

### 4.3 Problemas Críticos do RAG

| Problema | Severidade | Detalhe |
|---------|-----------|---------|
| Sem índice HNSW no PGVector | **Crítico** | Scan sequencial em produção com >10k chunks |
| PGVector síncrono (psycopg3) | **Alto** | Bloqueia event loop asyncio |
| Embeddings em modelo "preview" | **Alto** | Sem SLA, pode ser descontinuado |
| Sem fallback de embeddings | **Alto** | RAG para completamente se modelo falhar |
| Overlap 10% (50 tokens) | **Médio** | Risco de perda semântica em fronteiras |
| Tokenizador sem stopwords PT-BR | **Médio** | Keyword scoring impreciso |
| Sem cross-encoder reranking | **Médio** | RRF é fusão simples, não semântica |
| `_try_count()` retorna sempre 0 | **Baixo** | Monitoramento de índice impossível |

### 4.4 Índice HNSW — Ação Imediata

```sql
-- Executar ANTES de produção (via Alembic migration):
CREATE INDEX ON langchain_pg_embedding
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Sem este índice: sequential scan
-- Impacto: 10ms → 2000ms+ com >10k chunks
```

### 4.5 Comparativo de Vector Databases

| Banco | Custo Extra | Escala | Latência | Recomendação |
|-------|------------|--------|---------|-------------|
| PGVector (atual) | $0 | Médio | Médio | MVP ✅ |
| Qdrant self-hosted | $0 | Alto | Baixo | Produção ✅ |
| ChromaDB | $0 | Baixo | Baixo | Dev only |
| Pinecone | $$$ | Altíssimo | Baixo | Enterprise |

---

## PARTE 5 — ORQUESTRADOR DE IA (LANGGRAPH)

### 5.1 Grafo de Execução (Sequencial)

```
START
  │
  ▼
[security_gate] ──(blocked)──────────────────▶ END
  │ (safe)
  ▼
[triagem] ── Qwen3-80B free, tool: get_lead_context_by_wa_id
  │
  ▼
[rag_mandatory] ── PGVector hybrid k=4, guardrails
  │
  ▼
[build_context] ── XML-isolated system prompt (stage-aware)
  │
  ▼
[orchestrator] ── Gemini 2.0 Flash, 4 tools, max 4 rounds, temp=0.3
  │
  ▼
[validate_output] ── code leak regex + hallucination regex
  │
  ▼
[confusion_tracker] ── Slack alert + latency log
  │
  ▼
END
```

**Padrão de execução:** 100% sequencial — sem paralelismo de nós

### 5.2 Análise Crítica do Estado

```python
class OrchestratorState(TypedDict):
    wa_id: str
    message: str
    conversation_history: list[dict]   # ⚠️ SEM LIMITE DE TAMANHO
    db: Optional[AsyncSession]          # ⚠️ NÃO SERIALIZÁVEL
    safe_message: str
    blocked: bool
    triagem: dict[str, Any]
    rag_context: str
    system_prompt: str
    response: str
    hallucination_detected: bool
    confusion_count: int
    start_ts: float
```

| Problema no Estado | Severidade |
|-------------------|-----------|
| `db: AsyncSession` (não serializável) | **Crítico** — crash em checkpointing |
| `conversation_history` sem limite | **Alto** — context window overflow possível |
| Sem checkpointing persistido | **Médio** — crash = estado perdido |

### 5.3 Latência e Custo por Nó

| Nó | Tokens | Latência | Custo | Avaliação |
|----|--------|---------|-------|-----------|
| security_gate | 0 | < 5ms | $0 | Excelente |
| triagem (Qwen free) | ~2.000 | 1.5s–4s | $0 | **Arriscado** |
| rag_mandatory | ~50 | 50–200ms | ~$0 | Bom |
| build_context | 0 | < 1ms | $0 | Excelente |
| orchestrator (Gemini) | ~4.500 | 800ms–2.5s | ~$0.002 | Bom |
| validate_output | 0 | < 1ms | $0 | Excelente |
| confusion_tracker | 0 | < 1ms | $0 | Bom |

### 5.4 Riscos Críticos do Orquestrador

| Risco | Probabilidade | Impacto |
|------|--------------|---------|
| Gemini emite tool call como texto Python | Alta | Alto |
| Triagem falha em free tier (sem contexto CRM) | Alta | Alto |
| Histórico ilimitado → context overflow | Alta | Médio |
| Race condition em `_memories[phone]` | Baixa | Médio |
| `db` expirada durante execução | Média | Médio |

---

## PARTE 6 — SISTEMA DE FERRAMENTAS (TOOLS)

### 6.1 Inventário de Tools

| Tool | Finalidade | Risco Principal |
|------|-----------|----------------|
| `get_lead_context_by_wa_id` | Busca CRM por WhatsApp ID | Dados pessoais no contexto LLM |
| `query_project_scope` | RAG on-demand | Indirect prompt injection via query |
| `persist_lead_data` | Upsert briefing no CRM | LLM persiste alucinações no banco |
| `check_availability` | Slots de calendário | Data sem validação de formato |
| `generate_travel_image` | Imagem inspiracional | Prompt inapropriado, sem NSFW filter |

### 6.2 Vulnerabilidades das Tools

| Tool | Vulnerabilidade | Severidade |
|------|----------------|-----------|
| `persist_lead_data` | Dados do LLM persistem sem whitelist validation | **Alto** |
| `query_project_scope` | Query sem sanitização → indirect injection | **Médio** |
| `generate_travel_image` | Prompt vem do LLM sem filtro NSFW | **Médio** |
| Todas | Sem RBAC por tool | **Médio** |

### 6.3 Tool Calls como Texto Python (Bug Detectado)

```python
# Gemini 2.0 Flash ocasionalmente emite (INCORRETO):
default_api.persist_lead_data(phone="5511999", data={"destino": "Salvador"})

# Sistema espera (CORRETO):
{"name": "persist_lead_data", "arguments": {"phone": "5511999", ...}}

# Mitigação atual: validate_output bloqueia "default_api." como code leak
# Gap: se detecção falhar, tool call é perdida silenciosamente
```

---

## PARTE 7 — SISTEMA DE FILAS E PROCESSAMENTO ASSÍNCRONO

### 7.1 Arquitetura Atual

```
FastAPI BackgroundTasks (in-process):
  Webhook → HTTP 200 → background_tasks.add_task(process_whatsapp_message)
  ⚠️ Sem retry automático — falha = mensagem WhatsApp perdida permanentemente
  ⚠️ Em múltiplos workers: processamento duplicado sem coordenação

APScheduler (in-process, UTC):
  Job 1: lead_expiration     → Cron: 02:00 UTC diário
  Job 2: proposta_expiration → Interval: 5 minutos
  Job 3: notification_worker → Interval: 15 segundos (⚠️ viola SLA FCM < 2s)

NotificationQueue (PostgreSQL):
  pending → processing → completed
               └── failed → retry (exponential: 60s, 120s, 240s) → dead_letter_queue
  Crash recovery: processing_started_at timeout ✅
```

### 7.2 Problemas Críticos

| Problema | Severidade |
|---------|-----------|
| Notification polling 15s viola SLA FCM < 2s | **Alto** |
| BackgroundTasks sem retry — mensagem perdida em falha | **Alto** |
| Multi-worker sem coordenação (race condition) | **Alto** |
| APScheduler in-process — jobs param em restart | **Médio** |
| Sem idempotência no webhook (re-entrega Meta = duplo) | **Médio** |

### 7.3 Arquitetura Recomendada (Enterprise)

```
Webhook → publica evento → Redis Streams / Celery

Consumer Groups:
  ai_processor:        Celery workers com retry automático
  notification_sender: FCM dispatch com idempotência (message_id dedup)
  audit_logger:        Eventos de auditoria → PostgreSQL

Garantias: idempotência, at-least-once delivery, ordering por wa_id
```

---

## PARTE 8 — AGENTES DE IA

### 8.1 Inventário de Agentes

| Agente | Modelo | SLA | Autonomia | Status |
|-------|--------|-----|----------|--------|
| TriagemAgent | Qwen3-80B (free) | Nenhum | Baixa | Risco alto |
| OrquestradorAgent (AYA) | Gemini 2.0 Flash | Produção | Média | OK |
| AI Service (legado) | Configurável | Produção | Média | **Redundante** |

### 8.2 Problema Crítico: Dois Pipelines Concorrentes

```
Pipeline A: multi_agent_orchestrator.py
  └── Usado por: routes/webhook.py (WhatsApp)

Pipeline B: ai_service.py
  └── Usado por: routes/ia.py (/ia/processar)

Consequências:
  - Comportamentos divergentes para o mesmo cliente
  - Memória inconsistente entre pipelines
  - Manutenção dobrada
  - Risco de resposta inconsistente

Solução: Unificar em único pipeline multi_agent_orchestrator.py
```

### 8.3 Arquitetura Multi-Agente Enterprise Recomendada

```
Supervisor Agent (Planner)
  ├── Retrieval Agent (RAG + CRM lookup)
  ├── Conversation Agent (AYA / Gemini)
  ├── Memory Agent (compress, summarize, profile)
  └── Critic Agent (validate, hallucination detection)

Comunicação: LangGraph edges condicionais + shared state
Checkpointing: PostgreSQL via LangGraph Checkpointer nativo
```

---

## PARTE 9 — MEMÓRIA E ESTADO

### 9.1 Sistema de Memória Atual

| Tipo | Implementação | Problema |
|------|--------------|---------|
| Curto prazo | `conversation_history` in state | Sem limite — context overflow |
| Sessão (legado) | `SimpleWindowMemory` (20 pares) | Só no pipeline legado |
| Longo prazo | `interacoes` table | OK |
| Comprimida | `conversation_summaries` | Não ativa no novo pipeline |
| RAG | PGVector | OK |
| Cache | Redis (subutilizado) | Não usado para contexto CRM |

### 9.2 Problemas Críticos

```python
# Memory leak em ai_service.py:
_memories: dict[str, SimpleWindowMemory] = {}
# Cresce indefinidamente — com 10k usuários = OOM eventual
# Sem TTL, sem limpeza automática

# Histórico ilimitado no orchestrator:
conversation_history: list[dict]
# 50+ mensagens = context window potencialmente violado
# Sem compressão ativa no novo pipeline
```

### 9.3 Hierarquia de Memória Recomendada

```
Working Memory  → Redis TTL 2h  → contexto da conversa atual (sub-ms)
Episodic Memory → PostgreSQL    → últimas 30 interações (< 10ms)
Semantic Memory → PGVector      → base RAG (< 200ms)
Long-term       → PostgreSQL    → resumos comprimidos (histórico)
User Profile    → leads.briefing → preferências persistentes
```

---

## PARTE 10 — SEGURANÇA DA IA

### 10.1 Score de Segurança: 8.1/10

### 10.2 Defesas Implementadas (Camadas)

```
Camada 1 — Prompt Injection (163 padrões, pré-LLM, 0 tokens):
  EN: ignore instructions, act as, jailbreak, DAN mode, eval(, exec(
  PT: ignore instruções, esqueça regras, você agora é, aja como
  RU/ZH/KO/FA/BN: padrões multilíngues equivalentes
  Terminal: ls -la, cat .env, os.system, subprocess
  Unicode: fullwidth Latin normalization (ａ→a)

Camada 2 — XML Isolators:
  <system_instructions> → não pode ser injetado pelo usuário
  <rag_context>         → separado do input do usuário
  <user_content>        → tags escaped ANTES de inserir no prompt

Camada 3 — RAG Guardrails (pós-retrieval):
  PriceGuardrail:        remove chunks com R$, US$, preço, desconto
  AvailabilityGuardrail: remove "temos vagas", "voo confirmado"
  Estratégia:            "remove" (chunk excluído completamente)

Camada 4 — Output Validation (pós-LLM):
  Code leak:        print(, default_api., exec(, __import__
  Hallucination:    R$ [0-9]+, disponível, garanto sua vaga
  Fallback response: "consultor verificará essa informação"

Camada 5 — Infra de Segurança:
  HMAC-SHA256:   assinatura webhook Meta (constant-time compare)
  JWT HS256:     access 1h, refresh 7d
  Argon2:        hash de senhas
  Fernet (AES):  criptografia de PII (nome, telefone)
  HMAC hash:     telefone_hash pesquisável sem descriptografar
  Rate limit:    slowapi + Redis (100/min webhook, 30/min IA)
```

### 10.3 Vulnerabilidades e Gaps

| Vulnerabilidade | Severidade | Status |
|----------------|-----------|--------|
| Indirect Prompt Injection via RAG documents | **Alto** | Sem mitigação |
| `persist_lead_data` persiste dados LLM sem whitelist | **Alto** | Validação parcial |
| `generate_travel_image` sem filtro NSFW | **Médio** | Sem mitigação |
| Histórico longo pode carregar injeções antigas | **Médio** | Sem mitigação |
| JWT HS256 simétrico (múltiplos serviços) | **Médio** | Aceitável MVP |
| `preferred_date` sem validação de formato | **Baixo** | Sem mitigação |

### 10.4 Mitigações Críticas Recomendadas

```python
# 1. Sanitizar documentos ANTES de indexar no RAG:
class DocumentSanitizer:
    INJECTION_PATTERNS = [r"ignore.*instru[çc][ão]", r"system\s*:"]
    def sanitize(self, doc: Document) -> Document:
        for p in self.INJECTION_PATTERNS:
            if re.search(p, doc.page_content, re.I):
                raise ValueError(f"Documento suspeito bloqueado")
        return doc

# 2. Whitelist de destinos antes de persistir no CRM:
VALID_DESTINOS = {"Salvador", "Florianópolis", "Europa", "Cancún", ...}
def validate_before_persist(data: dict) -> BriefingExtracted:
    if "destino" in data and data["destino"] not in VALID_DESTINOS:
        raise ValueError(f"Destino inválido recusado: {data['destino']}")
    return BriefingExtracted(**data)
```

---

## PARTE 11 — OBSERVABILIDADE E MONITORAMENTO

### 11.1 Stack de Observabilidade

| Componente | Status | Cobertura |
|-----------|--------|----------|
| structlog (logs JSON) | Implementado | Alta |
| Langfuse (LLM tracing) | Implementado (opcional) | Média |
| AuditTrailMiddleware | Implementado | Média |
| RequestIdMiddleware | Implementado | Alta |
| Slack alerts | Implementado | Pontual |
| Prometheus/Grafana | Estrutura presente, sem dados | Baixa |
| OpenTelemetry traces | **Ausente** | Nenhuma |
| Cost tracking | **Ausente** | Nenhuma |
| Business metrics | **Ausente** | Nenhuma |
| Health check completo | **Ausente** | Mínima |

### 11.2 Gaps Críticos

**Gap 1: Sem tracking de custo por conversa**  
Impossível calcular ROI do canal IA ou controlar budget.

**Gap 2: Health check incompleto**  
Não verifica dependências (PGVector, Redis, OpenRouter, FCM).

**Gap 3: Sem métricas de qualidade do RAG**  
Não rastreia: chunks retornados, guardrails ativados, fallbacks de filtro.

### 11.3 Observabilidade Enterprise Recomendada

```
FastAPI + OpenTelemetry auto-instrumentation
  │
  ├── Traces → Jaeger/Tempo
  │    └── Spans por nó LangGraph (model, tokens, latency, tools_called)
  │
  ├── Metrics → Prometheus → Grafana
  │    ├── ai_latency_ms{agent, p50, p95, p99}
  │    ├── ai_tokens_used{model, type}
  │    ├── ai_cost_usd_total{model}
  │    ├── rag_chunks{retrieved, guardrail_removed}
  │    ├── fallback_triggered_total{from, to}
  │    └── notification_status_total{status}
  │
  ├── Logs → Loki/Elasticsearch
  │    └── structlog JSON + trace_id correlation
  │
  └── Langfuse (obrigatório em produção)
       ├── Prompts versionados
       ├── Cost per session/wa_id
       └── Hallucination rate (% respostas bloqueadas)
```

---

## PARTE 12 — CUSTOS E PERFORMANCE

### 12.1 Custo por Request

| Componente | Tokens | Custo Estimado |
|-----------|--------|---------------|
| Triagem (Qwen free) | ~2.000 | $0.000 |
| RAG embedding query | ~50 | ~$0.000 |
| Orchestrator (Gemini Flash) | ~4.500 | ~$0.002 |
| **Total (texto típico)** | ~8.000 | **~$0.003** |
| **Total (com áudio)** | +~3.000 | **~$0.013** |
| **Total (com imagem)** | +1 img | **~$0.043** |

### 12.2 Waterfall de Latência

```
security_gate     2ms
DB pool acquire   5ms
triagem (free)    1.500–4.000ms  ← GARGALO PRINCIPAL
rag_retrieval     150ms
build_context     1ms
orchestrator      800–2.500ms
validate_output   1ms
whatsapp_send     300ms
─────────────────────────
TOTAL (texto):    ~4.0s
TOTAL (tools):    ~6.0s
TOTAL (áudio):    ~8.0s
```

### 12.3 Quick Wins de Performance

```python
# 1. Cache CRM no Redis (triagem: 2s → 50ms)
await redis.setex(f"crm:{wa_id}", 300, json.dumps(context))

# 2. Triagem + RAG em paralelo (-1.5s total)
triagem, rag = await asyncio.gather(
    asyncio.create_task(run_triagem(state)),
    asyncio.create_task(run_rag(state))
)

# 3. PGVector em thread pool (sem bloquear event loop)
docs = await asyncio.get_event_loop().run_in_executor(
    None, vs.similarity_search, query, candidate_k
)

# 4. FFmpeg em thread pool (sem bloquear event loop)
wav = await asyncio.get_event_loop().run_in_executor(
    None, _convert_to_wav, audio_bytes, src_fmt
)
```

---

## PARTE 13 — ESCALABILIDADE ENTERPRISE

### 13.1 Gaps de Escalabilidade

| Dimensão | Atual | Enterprise |
|---------|-------|-----------|
| Workers | 1 Uvicorn | Kubernetes HPA |
| Filas | BackgroundTasks | Celery + Redis Streams |
| DB connections | pool 10+20 | PgBouncer externo |
| Rate limiting | slowapi per-process | Kong/Nginx per-cluster |
| Vector DB | PGVector single | Qdrant cluster |
| Scheduler | APScheduler in-process | Celery Beat / K8s CronJob |
| Observability | structlog + Langfuse | OpenTelemetry + Grafana |

### 13.2 Gargalos Críticos

**1. Single Worker + Subprocess Bloqueante**
```
Dockerfile: uvicorn main:app --host 0.0.0.0 --port 8000
            (sem --workers)

FFmpeg subprocess.run() → bloqueia event loop asyncio
PGVector similarity_search() → chamada síncrona em context async

Impacto: degradação severa sob carga, sem isolamento de falhas
```

**2. Race Condition em Multi-Worker**
```
Worker1 + Worker2 + Worker3 lendo notification_queue simultaneamente
→ FCM enviado 3x ao consultor

Solução: SELECT FOR UPDATE SKIP LOCKED na query de notificações
```

### 13.3 Roadmap de Escalabilidade

```
FASE 1 — Correções Imediatas (1-2 semanas):
  ✦ HNSW index no PGVector
  ✦ FFmpeg e PGVector → run_in_executor (async)
  ✦ Cache Redis para contexto CRM (5 min TTL)
  ✦ TTL em _memories dict (prevenir memory leak)
  ✦ Health check endpoint completo
  ✦ Backoff entre fallbacks de modelo
  ✦ Remover nvidia/llama-nemotron do fallback de chat
  ✦ Idempotência webhook (dedup por message_id Meta)

FASE 2 — Resiliência (2-4 semanas):
  ✦ Celery + Redis substituindo BackgroundTasks
  ✦ Circuit breaker para OpenRouter
  ✦ SELECT FOR UPDATE SKIP LOCKED na notification_queue
  ✦ Unificar ai_service.py + multi_agent_orchestrator.py
  ✦ Modelo de triagem pago (com SLA garantido)
  ✦ Fallback de embeddings implementado

FASE 3 — Escala (1-3 meses):
  ✦ Kubernetes + Helm charts
  ✦ HPA baseado em queue depth
  ✦ PgBouncer para connection pooling externo
  ✦ OpenTelemetry traces distribuídos
  ✦ LangGraph Checkpointer (PostgreSQL)

FASE 4 — Enterprise (3-6 meses):
  ✦ Inferência local (Ollama/GPU) para tasks simples
  ✦ Multi-region deploy
  ✦ Qdrant cluster para vector search escalável
  ✦ Semantic cache (Redis vector similarity)
  ✦ Model router semântico por intenção
  ✦ Disaster recovery (RTO < 15min, RPO < 1min)
```

---

## PARTE 14 — ROADMAP TÉCNICO

### 14.1 Matriz Impacto × Esforço

```
              ALTO IMPACTO
                    │
  Celery+Redis      │  Cache CRM Redis    HNSW index
  Triagem pago      │  PGVector async     Unificar pipelines
  Circuit breaker   │  FFmpeg async       Idempotência webhook
                    │
 ALTO ──────────────┼────────────────── BAIXO
 ESFORÇO            │                  ESFORÇO
                    │
  Kubernetes        │  Health check      Backoff fallbacks
  GPU workers       │  TTL _memories     Remover embed model
  Multi-region      │  Cost tracking     Logs de custo
                    │
              BAIXO IMPACTO
```

### 14.2 Quick Wins (< 1 semana)

| Ação | Arquivo | Tempo | Impacto |
|------|---------|-------|---------|
| Cache CRM Redis (5 min TTL) | `ai_tools.py` | 2h | Latência -2s |
| HNSW index PGVector | Alembic migration | 1h | RAG 10x mais rápido |
| FFmpeg → run_in_executor | `model_router.py` | 1h | Sem bloqueio event loop |
| PGVector → run_in_executor | `rag_service.py` | 1h | Sem bloqueio event loop |
| TTL em `_memories` | `ai_service.py` | 30min | Previne memory leak |
| Health check completo | `routes/health.py` | 2h | Monitoramento |
| Remover nvidia/llama-nemotron | `multi_agent_orchestrator.py` | 15min | Elimina fallback incorreto |
| Backoff entre fallbacks | `multi_agent_orchestrator.py` | 1h | Menos cascata 429 |
| Idempotência webhook | `routes/webhook.py` | 2h | Sem duplicação |

---

## PARTE 15 — RESULTADO FINAL E SCORECARD

### 15.1 Scorecard por Dimensão

| Dimensão | Score | Detalhes |
|---------|-------|---------|
| Arquitetura Geral | **7.8** | Clean Arch correto, async parcial |
| Sistema de IA | **6.6** | LangGraph bom, fallback com erros |
| Segurança | **8.1** | Defesas multicamada acima da média |
| Escalabilidade | **4.8** | Free tier + 1 worker = gargalo crítico |
| Observabilidade | **6.5** | structlog + Langfuse, sem métricas de negócio |
| Qualidade de Código | **8.0** | Modular, bem tipado, docstrings |

### 15.2 Score Final

```
╔══════════════════════════════════════════════════════════╗
║              SCORECARD FINAL — CADIFE AI                 ║
╠══════════════════════════════════════════════════════════╣
║                                                          ║
║  Arquitetura Geral     ████████░░  7.8 / 10              ║
║  Sistema de IA         ██████░░░░  6.6 / 10              ║
║  Segurança             ████████░░  8.1 / 10              ║
║  Escalabilidade        ████░░░░░░  4.8 / 10  ← CRÍTICO   ║
║  Observabilidade       ██████░░░░  6.5 / 10              ║
║  Qualidade de Código   ████████░░  8.0 / 10              ║
║                                                          ║
║  SCORE GERAL           ██████░░░░  6.9 / 10              ║
║  Maturidade de IA MVP       7.2 / 10  BOM                ║
║  Prontidão para Produção    4.5 / 10  REQUER ATENÇÃO     ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
```

### 15.3 Top 5 Riscos Críticos

| # | Risco | Probabilidade | Impacto | Ação |
|---|-------|--------------|---------|------|
| 1 | Free tier sem SLA na triagem | Alta | Alto | Migrar para modelo pago |
| 2 | PGVector sem índice HNSW | Alta | Alto | Migration SQL imediata |
| 3 | BackgroundTasks sem retry | Alta | Alto | Implementar Celery |
| 4 | `nvidia/llama-nemotron` (embed) como chat fallback | Baixa | Alto | Remover do fallback chain |
| 5 | Indirect prompt injection via RAG docs | Média | Alto | Sanitizar docs na ingestão |

### 15.4 Top 5 Pontos Fortes

| # | Ponto Forte | Detalhe |
|---|------------|---------|
| 1 | Segurança de prompt injection multicamada | 163 padrões, 7 idiomas, XML isolators — benchmark para MVP |
| 2 | RAG-First com guardrails | Mandatory RAG + price/availability removal antes do LLM |
| 3 | LangGraph StateGraph estruturado | 7 nós com responsabilidades únicas e fluxo condicional |
| 4 | Fila de notificações robusta | DLQ, exponential backoff, crash recovery — produção-ready |
| 5 | Clean Architecture | 4 camadas, 40 services modulares, repository pattern aplicado |

---

## CONCLUSÃO

O sistema **AYA / Cadife Smart Travel** representa uma implementação de IA significativamente acima da média para um MVP de 25 dias. A arquitetura defensiva de prompt injection (163 padrões multilíngues), o pipeline RAG-First com guardrails de preço/disponibilidade, e o LangGraph orquestrado com validação de output demonstram consciência real dos riscos de IA em produção.

Os cinco desafios prioritários para maturidade enterprise são:

1. **Escalabilidade de workers** — BackgroundTasks → Celery + Redis
2. **Free tier sem SLA** — triagem crítica em modelo sem garantia
3. **Gargalos síncronos** — PGVector e FFmpeg bloqueando o event loop
4. **Dois pipelines concorrentes** — ai_service.py + multi_agent_orchestrator.py
5. **Sem índice HNSW** — RAG em produção com >10k chunks terá latência inaceitável

Com as **quick wins identificadas** (estimadas em 2–3 semanas), o score de prontidão para produção saltaria de **4.5 para 7.0+**, tornando o sistema robusto para o volume inicial de clientes da Cadife.

---

*Relatório gerado em: Maio de 2026*  
*Codebase analisado: /opt/cadife/app — 156+ arquivos Python*  
*Branch auditado: servidor*  
*Auditor: Arquiteto Principal de IA — Claude Sonnet 4.6*
