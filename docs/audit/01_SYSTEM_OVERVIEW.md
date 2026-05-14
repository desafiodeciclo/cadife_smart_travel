# 01 — SYSTEM OVERVIEW
## Cadife Smart Travel — Análise Completa da Arquitetura Atual
**Data:** 2026-05-14 | **Versão:** 1.1.0

---

## 1. VISÃO GERAL DO SISTEMA

O Cadife Smart Travel é uma plataforma de atendimento turístico inteligente composta por três camadas principais:

| Camada | Tecnologia | Função |
|--------|-----------|--------|
| **WhatsApp Bot (AYA)** | FastAPI + LangGraph + OpenRouter | Pré-atendimento IA 24/7, coleta de briefing, qualificação de leads |
| **Backend API** | FastAPI + PostgreSQL + Kafka + Redis | Orquestração, persistência, notificações, agendamento |
| **App Flutter** | Flutter + Riverpod + GoRouter | CRM da agência + portal do cliente |

---

## 2. ARQUITETURA DE CAMADAS (CLEAN ARCHITECTURE)

```
backend/app/
├── domain/           → Entidades, enums, interfaces (zero dependências externas)
├── application/      → Use cases, DTOs, workers
│   ├── use_cases/    → process_whatsapp_message.py (fluxo central)
│   ├── services/     → lead_scoring_service.py, lead_state_machine.py
│   └── workers/      → whatsapp_consumer.py, agendamento_consumer.py
├── infrastructure/   → I/O: DB, Redis, Kafka, Google, Firebase, S3
│   ├── persistence/  → models/, repositories/, database.py
│   ├── cache/        → redis_client.py, decorator.py
│   ├── config/       → settings.py (Pydantic BaseSettings)
│   ├── security/     → rate_limiter.py, JWT
│   ├── logging/      → structlog config
│   ├── metrics/      → métricas internas
│   └── adapters/     → firebase.py, whatsapp_adapter.py, storage/
├── services/         → Serviços de negócio (IA, RAG, WhatsApp, etc.)
│   ├── multi_agent_orchestrator.py  ← NÚCLEO DA IA
│   ├── rag_service.py
│   ├── google_calendar_service.py
│   ├── kafka_producer.py
│   ├── whatsapp_service.py          ← deveria estar em adapters/
│   └── fcm_service.py               ← deveria estar em adapters/
├── jobs/             → APScheduler jobs (lead_expiration, proposta, notification_worker, etc.)
├── models/           → Re-exports/aliases dos modelos ORM por domínio
├── schemas/          → Pydantic schemas de resposta/entrada (document, lead, travel)
├── core/             → config.py, database.py, dependencies.py, security.py
├── routes/           → Endpoints FastAPI
└── presentation/     → Middlewares, schemas, API layer
```

**Avaliação:** A separação de camadas é bem definida, porém há duas inconsistências importantes: (1) os serviços em `app/services/` misturam responsabilidades — `whatsapp_service.py` e `fcm_service.py` deveriam residir em `app/infrastructure/adapters/`; (2) existe duplicidade entre `app/core/` e `app/infrastructure/config/` para configurações globais.

---

## 3. STACK TECNOLÓGICO COMPLETO

### 3.1 Backend Core
| Componente | Tecnologia | Versão |
|------------|-----------|--------|
| Framework | FastAPI | latest |
| Runtime | Python + asyncio | 3.11 |
| ORM | SQLAlchemy AsyncSession | latest |
| Migrations | Alembic | latest |
| Validação | Pydantic v2 | 2.x |
| Servidor | Uvicorn | latest |

### 3.2 IA e ML
| Componente | Tecnologia | Detalhes |
|------------|-----------|----------|
| Orquestração | LangGraph StateGraph | >=0.2.0 (pinned no requirements.txt) |
| LLM Framework | LangChain | latest |
| LLM Provider | OpenRouter | Multi-model |
| Chat Model (primary) | google/gemini-2.0-flash-001 | via OpenRouter |
| Triagem Model | qwen/qwen-2.5-72b-instruct:free | via OpenRouter |
| Embedding | google/gemini-embedding-2-preview | via OpenRouter |
| Vector DB | ChromaDB | local (dev) |
| Hybrid Search | BM25 + Vector RRF | Reciprocal Rank Fusion |
| Observabilidade IA | LangFuse + LangSmith | dual tracing |

### 3.3 Infraestrutura
| Componente | Tecnologia | Uso |
|------------|-----------|-----|
| Banco Relacional | PostgreSQL 16 | leads, briefings, mensagens, agendamentos |
| Cache | Redis 7 | sessões, rate limit, debounce notificações |
| Fila de Mensagens | Kafka (aiokafka) | processamento assíncrono de webhooks |
| Storage | S3 / LocalStack | documentos, imagens de diário |
| Push Notifications | Firebase FCM | alertas para consultores |
| Agendamento | APScheduler 3.x | jobs periódicos |
| Containerização | Docker + Compose | todos os serviços |

### 3.4 Integrações Externas
| Integração | Serviço | Autenticação |
|------------|---------|-------------|
| WhatsApp | Meta Cloud API | HMAC-SHA256 + Bearer token |
| Calendário | Google Calendar API | Service Account |
| Reuniões | Google Meet | conferenceData em eventos |
| Push | Firebase Admin SDK | Service Account JSON |
| Monitoramento | LangFuse / LangSmith | API Keys |
| Alertas | Slack Webhook | URL secreta |

---

## 4. FLUXO PONTA A PONTA

```
┌─────────────┐
│   CLIENTE   │
│  WhatsApp   │
└──────┬──────┘
       │ Mensagem
       ▼
┌─────────────────────────────────────────────┐
│  META WhatsApp Cloud API                    │
│  POST /webhook/whatsapp                     │
└──────┬──────────────────────────────────────┘
       │ Payload JSON
       ▼
┌─────────────────────────────────────────────┐
│  FASTAPI — webhook.py                        │
│  1. Valida X-Hub-Signature-256 (HMAC-SHA256)│
│  2. Retorna HTTP 200 IMEDIATAMENTE          │ ← SLA < 5s
│  3a. Se KAFKA_ENABLED=false → BackgroundTask│
│  3b. Se KAFKA_ENABLED=true → Kafka topic    │
└──────┬──────────────────────────────────────┘
       │ BackgroundTask / Kafka
       ▼
┌─────────────────────────────────────────────┐
│  process_whatsapp_message.execute()         │
│  1. Extrai phone, text, media_id            │
│  2. Upsert lead no PostgreSQL               │
│  3. Avança status NOVO → EM_ATENDIMENTO     │
│  4. Carrega histórico DB (k=20 interações)  │
│  5. Lê briefing pré-carregado (bypass tool) │
│  6. Se áudio → transcreve via Whisper       │
│  7. Invoca multi_agent_orchestrator         │
└──────┬──────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│  LANGGRAPH PIPELINE                         │
│  security_gate → triagem → rag_mandatory    │
│  → build_context → orchestrator             │
│  → validate_output → confusion_tracker      │
└──────┬──────────────────────────────────────┘
       │ Resposta AYA
       ▼
┌─────────────────────────────────────────────┐
│  PÓS-PROCESSAMENTO                          │
│  1. Verifica briefing atualizado             │
│  2. Se completude ≥ 60% → notificação FCM   │
│  3. Se recém-qualificado → oferta curadoria │
│  4. Persiste interação no DB                │
│  5. Envia resposta via WhatsApp API         │
└─────────────────────────────────────────────┘
```

---

## 5. MÓDULOS E RESPONSABILIDADES

### 5.1 Módulos Críticos

| Arquivo | Responsabilidade | Status |
|---------|-----------------|--------|
| `multi_agent_orchestrator.py` | Pipeline LangGraph completo — núcleo da IA | **Crítico** |
| `process_whatsapp_message.py` | Use case central — orquestra todo o fluxo | **Crítico** |
| `webhook.py` | Entrada WhatsApp — SLA 5s | **Crítico** |
| `rag_service.py` | Busca híbrida (vector+BM25+RRF) no ChromaDB | **Crítico** |
| `google_calendar_service.py` | Criação de eventos + Google Meet | **Importante** |
| `kafka_producer.py` | Publicação assíncrona de eventos | **Importante** |
| `ai_tools.py` | Execução das ferramentas do orquestrador | **Importante** |
| `lead_service.py` | CRUD de leads, scoring, status transitions | **Importante** |

### 5.2 Jobs Agendados (APScheduler)

| Job | Trigger | Função | Registrado em main.py? |
|-----|---------|--------|------------------------|
| `lead_expiration_job` | Diário 02h UTC | Arquivar leads inativos ≥ 30 dias | ✅ Sim |
| `proposta_expiration_job` | A cada 5 min | Verificar SLA de propostas | ✅ Sim |
| `notification_worker` | A cada 15s | Drenar fila FCM | ✅ Sim |
| `checkpoint_cron_job` | Diário 03h UTC (docstring) | Ativar checkpoints por datas de viagem | ❌ **Não registrado** |
| `conversation_summary_retry_job` | A cada 15 min (docstring) | Retry de resumos pendentes (batch 50) | ❌ **Não registrado** |
| `aya_alert_job` | — | Alertas internos da AYA | ❌ **Não registrado** |

> **BUG IDENTIFICADO:** `checkpoint_cron_job` e `conversation_summary_retry_job` possuem arquivos de job com horários documentados em suas docstrings, mas **não são adicionados ao `_scheduler` no `lifespan()` do `main.py`**. Esses jobs nunca executam automaticamente. A tabela de jobs registrados em `main.py` inclui apenas: `lead_expiration`, `proposta_expiration` e `notification_worker`.

---

## 6. DEPENDÊNCIAS CRÍTICAS E PONTOS DE FALHA

### 6.1 Dependências Externas (risco de indisponibilidade)

| Serviço | Impacto se falhar | Fallback existe? |
|---------|------------------|-----------------|
| OpenRouter API | IA indisponível — sem resposta ao cliente | Sim — chain de fallback (qwen → llama) |
| Meta WhatsApp API | Sem recepção de mensagens | Não — sistema fica cego |
| Firebase FCM | Consultores sem notificação | Sim — fila com retry |
| Google Calendar | Sem Meet link | Sim — agendamento sem Meet |
| PostgreSQL | Sistema inoperante | Não — sem fallback |
| Redis | Rate limit, cache e debounce falham | Parcial — degradação silenciosa |
| Kafka | Mensagens processadas via BackgroundTask | Sim — KAFKA_ENABLED=false |
| ChromaDB | RAG indisponível — contexto sem conhecimento | Sim — resposta sem RAG |

### 6.2 Pontos de Falha Identificados

1. **In-memory state não persistente**: `_field_repetition_tracker` (confusion tracker) e `_rag_cache` (cache de busca RAG) vivem em memória de processo — perdidos ao reiniciar. Com múltiplos workers uvicorn (`--workers N`), cada instância tem estado independente: o confusion counter zera ao mudar de worker, e o cache RAG não é compartilhado. Solução: migrar para Redis com TTL.

2. **Session expiry pós-tool-call**: O SQLAlchemy expira atributos do ORM após commit interno (gerado pela tool call `persist_lead_data`). O código já contém `await db.refresh(lead)` como mitigação, mas há risco residual de `MissingGreenlet` em pontos não cobertos pelo refresh.

3. **Background task vs Kafka**: Quando `KAFKA_ENABLED=false`, o processamento roda em `BackgroundTask` do FastAPI com a `AsyncSession` passada **por referência** — se houver rollback interno, operações subsequentes falham silenciosamente. Além disso, sem durabilidade: se a aplicação cair durante o processamento, a mensagem é perdida sem retry automático.

4. **Triagem agent falha silenciosamente**: Qualquer exceção no TriagemAgent (timeout, rate limit, JSON malformado) retorna `{"is_new_lead": True, "exists": False}` — cliente recorrente recebe saudação de primeiro contato e tem seu contexto descartado.

5. **Race condition em mensagens simultâneas**: Sem distributed lock por `wa_id`, múltiplas mensagens do mesmo cliente processadas simultaneamente geram inconsistência no briefing (upsert simultâneo pode sobrescrever campos) e histórico de conversa divergente. Não há locking explícito por `wa_id`.

6. **Jobs órfãos não registrados no scheduler**: `checkpoint_cron_job`, `conversation_summary_retry_job` e `aya_alert_job` existem como arquivos mas **não são registrados** no `_scheduler` do `main.py`. Checkpoints de viagem nunca são ativados automaticamente; resumos pendentes nunca são retentados via scheduler.

---

## 7. CONFIGURAÇÃO E VARIÁVEIS DE AMBIENTE

### 7.1 Variáveis Críticas (sem as quais o sistema não funciona)

```bash
# WhatsApp
WHATSAPP_TOKEN=        # Bearer token Meta
PHONE_NUMBER_ID=       # ID do número registrado
VERIFY_TOKEN=          # Token de verificação do webhook
META_APP_SECRET=       # Segredo para HMAC-SHA256

# IA
OPENROUTER_API_KEY=    # Chave OpenRouter (LLM + Embeddings)

# Banco
DATABASE_URL=          # postgresql+asyncpg://...

# Auth
JWT_SECRET_KEY=        # Chave de assinatura JWT

# Criptografia PII
ENCRYPTION_KEY=        # Fernet key para nome e telefone
```

### 7.2 Variáveis Opcionais (degradação graciosa)

```bash
# Google Calendar (sem isso, agendamentos são criados sem Meet link)
GOOGLE_SERVICE_ACCOUNT_PATH=

# Firebase (sem isso, sem push notifications)
FIREBASE_CREDENTIALS=

# Kafka (sem isso, usa BackgroundTasks)
KAFKA_ENABLED=false

# Redis (sem isso, cache não funciona)
REDIS_URL=

# Observabilidade
LANGFUSE_PUBLIC_KEY=
LANGCHAIN_API_KEY=
SLACK_WEBHOOK_URL=
```

---

## 8. MODELOS DE BANCO DE DADOS — RESUMO

### 8.1 Tabelas Core

| Tabela | Registros | Índices Críticos |
|--------|-----------|-----------------|
| `leads` | Principal | `telefone_hash` (busca por telefone) |
| `briefing` | 1:1 com lead | `lead_id` |
| `interacao` | N:1 com lead | `lead_id`, `timestamp` |
| `agendamento` | N:1 com lead | `lead_id`, `status` |
| `proposta` | N:1 com lead | `lead_id`, `status` |
| `conversation_summary` | 1:1 com lead | `lead_id` |

### 8.2 Observações

- **PII Criptografado**: `nome` e `telefone` são criptografados com Fernet (AES-128). Busca feita via `telefone_hash` (HMAC-SHA256).
- **Soft Delete**: Leads não são deletados fisicamente — `is_archived=True` + `deletado_em=timestamp`.
- **30 migrações Alembic**: sistema com histórico de evolução de schema bem documentado.

---

## 9. OBSERVABILIDADE E MONITORAMENTO

### 9.1 Implementado

- **Structured Logging**: `structlog` com campos contextuais (`lead_id`, `wa_id`, `latency_ms`)
- **Request ID Middleware**: `X-Request-ID` em todos os requests para correlação
- **Audit Trail Middleware**: `AuditTrailMiddleware` registra ações críticas (login, lead CRUD, etc.)
- **Timeout Middleware**: `TimeoutMiddleware` proteção contra requisições longas
- **Security Headers Middleware**: `SecurityHeadersMiddleware` (CSP, HSTS, X-Frame-Options)
- **LangFuse**: tracing de chamadas LLM (tokens, latência, erros)
- **LangSmith**: tracing alternativo (LangChain nativo)
- **Kafka DLQ**: mensagens com falha vão para `whatsapp.messages.dlq`
- **`observability.py`**: serviço centralizado de métricas internas

### 9.2 Ausente / Incompleto

- **Distributed tracing**: sem correlação de `request_id` dentro do pipeline LangGraph (cada nó do grafo não propaga o trace ID)
- **Métricas Prometheus**: sem endpoint `/metrics` — `observability.py` existe mas não expõe scraping externo
- **Alertas proativos**: Slack webhook existe mas não há SLO definido nem limiar de alerta configurado
- **Dashboard operacional**: sem Grafana ou equivalente
- **Health check detalhado**: `GET /health` não verifica subserviços (DB, Redis, Kafka) — apenas retorna status da aplicação
- **Rate limit metrics**: sem visibilidade sobre tentativas rejeitadas pelo `slowapi`

---

## 10. AVALIAÇÃO GERAL DA ARQUITETURA

| Dimensão | Nota | Observação |
|----------|------|-----------|
| Separação de camadas | 7/10 | Clean Architecture bem aplicada; duplicidade `core/` vs `infrastructure/config/` e serviços de infra em `services/` |
| Tratamento assíncrono | 9/10 | Async/await consistente, SLA webhook respeitado; risco residual de session leak no BackgroundTask |
| Resiliência | 5/10 | Fallbacks implementados, mas jobs órfãos, estado em memória frágil e sem retry para BackgroundTask |
| Observabilidade | 6/10 | Logs estruturados + audit trail bons; tracing distribuído dentro do LangGraph ausente; sem /metrics |
| Escalabilidade | 4/10 | Race condition sem distributed lock por `wa_id`; _rag_cache e confusion tracker não compartilhados entre workers |
| Segurança | 8/10 | HMAC, JWT, PII encryption, rate limiting, security headers bem implementados |
| Testabilidade | 7/10 | Suite de testes abrangente (pytest + AsyncClient), mas E2E e testes de concorrência ausentes |

**Conclusão**: Arquitetura sólida para MVP single-worker, mas com três bloqueadores antes de produção em escala: (1) jobs críticos (`checkpoint_cron_job`, `conversation_summary_retry_job`) não registrados no scheduler; (2) ausência de distributed lock por `wa_id` gerando race conditions em mensagens simultâneas; (3) estado em memória (`_rag_cache`, `_field_repetition_tracker`) incompatível com múltiplos workers.

**Refs cruzadas:** Ver [02_WHATSAPP_FLOW_ANALYSIS.md](02_WHATSAPP_FLOW_ANALYSIS.md) para análise detalhada do race condition e session leak; [03_AI_AND_LANGGRAPH_ANALYSIS.md](03_AI_AND_LANGGRAPH_ANALYSIS.md) para o bug de inferência de ocasião de viagem; [04_MEMORY_AND_CONTEXT_ANALYSIS.md](04_MEMORY_AND_CONTEXT_ANALYSIS.md) para análise de memória entre workers.
