# 14 — TARGET ARCHITECTURE
## Cadife Smart Travel — Arquitetura Alvo Recomendada
**Data:** 2026-05-14 | **Versão:** 1.0.0

---

## 1. VISÃO DA ARQUITETURA ALVO

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        CADIFE SMART TRAVEL — TARGET ARCHITECTURE         │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────┐         ┌─────────────────────────────────────────────┐   │
│  │  Meta    │  HTTPS  │  FASTAPI GATEWAY                            │   │
│  │  WA API  ├────────►│  • HMAC validation                          │   │
│  └──────────┘         │  • Rate limiting (wa_id-based)              │   │
│                        │  • Request ID + Correlation ID              │   │
│                        │  • HTTP 200 imediato                        │   │
│                        └───────────────┬─────────────────────────────┘  │
│                                        │                                │
│                        ┌───────────────▼─────────────────────────────┐  │
│                        │  KAFKA — whatsapp.messages.incoming         │  │
│                        │  • Partitioned by wa_id                     │  │
│                        │  • At-least-once delivery                   │  │
│                        │  • DLQ: whatsapp.messages.dlq               │  │
│                        └───────────────┬─────────────────────────────┘  │
│                                        │                                │
│                        ┌───────────────▼─────────────────────────────┐  │
│                        │  AI PROCESSING WORKERS                      │  │
│                        │  (whatsapp_consumer.py)                     │  │
│                        │  • Redis distributed lock por wa_id         │  │
│                        │  • Idempotência por wamid                   │  │
│                        │  • Própria session DB                       │  │
│                        │                                             │  │
│                        │  ┌─────────────────────────────────────┐   │  │
│                        │  │  LANGGRAPH PIPELINE                 │   │  │
│                        │  │  + correlation_id propagado         │   │  │
│                        │  │  security_gate → triagem            │   │  │
│                        │  │  → rag_mandatory → build_context    │   │  │
│                        │  │  → orchestrator → validate_output  │   │  │
│                        │  │  → confusion_tracker                │   │  │
│                        │  └─────────────────────────────────────┘   │  │
│                        └───────────────┬─────────────────────────────┘  │
│                                        │                                │
│         ┌──────────────────────────────┼──────────────────────────┐    │
│         │                             │                            │    │
│  ┌──────▼──────┐   ┌────────────┐   ┌─▼──────────┐  ┌──────────┐ │    │
│  │ PostgreSQL  │   │   Redis    │   │  ChromaDB  │  │  Kafka   │ │    │
│  │  (primary)  │   │  Cluster   │   │  HTTP Svc  │  │  Topics  │ │    │
│  │ + PgBouncer │   │            │   │            │  │          │ │    │
│  │             │   │ • RAG cache│   │ • RAG search│  │leads.*   │ │    │
│  │ leads       │   │ • wa locks │   │ • Embeddings│  │agendament│ │    │
│  │ briefing    │   │ • conf.track│   │ • Metadata │  │.confirmad│ │    │
│  │ interacao   │   │ • FCM deb. │   │   filtering│  │os        │ │    │
│  │ agendamento │   │ • sessions │   │            │  │          │ │    │
│  └─────────────┘   └────────────┘   └────────────┘  └──────────┘ │    │
│                                                                    │    │
│                     ┌──────────────────────────────────────────┐  │    │
│                     │  DOWNSTREAM WORKERS                      │  │    │
│                     │  agendamento_consumer.py                 │  │    │
│                     │  • Google Calendar freebusy query        │  │    │
│                     │  • Criar evento + Meet link             │  │    │
│                     │  • Salvar google_event_id               │  │    │
│                     │  • WhatsApp: enviar Meet link           │  │    │
│                     └──────────────────────────────────────────┘  │    │
│                                                                    │    │
│                     ┌──────────────────────────────────────────┐  │    │
│                     │  OBSERVABILITY STACK                     │  │    │
│                     │  • Prometheus + Grafana                  │  │    │
│                     │  • LangFuse (LLM tracing)               │  │    │
│                     │  • Structured logs → ELK/Loki           │  │    │
│                     │  • Sentry (error aggregation)           │  │    │
│                     │  • Kafka UI (consumer lag)              │  │    │
│                     └──────────────────────────────────────────┘  │    │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 2. MUDANÇAS ARQUITETURAIS POR CAMADA

### 2.1 Gateway Layer

| Atual | Alvo | Mudança |
|-------|------|---------|
| Rate limit por IP | Rate limit por `wa_id` | Evita shared limit entre clientes |
| Request-ID apenas em HTTP | Correlation-ID propagado até consumers | Tracing completo |
| Health check básico | Health check com subserviços | Visibilidade operacional |

### 2.2 Message Processing Layer

| Atual | Alvo | Mudança |
|-------|------|---------|
| BackgroundTask (dev) / Kafka (prod) | Kafka sempre (dev com broker local) | Consistência de comportamento |
| Sem idempotência de wamid | Verificação de wamid antes de processar | Elimina duplicatas |
| Sem lock por wa_id | Redis distributed lock | Elimina race conditions |

### 2.3 AI Pipeline Layer

| Atual | Alvo | Mudança |
|-------|------|---------|
| `conversation_history[-6:]` | `conversation_history[-10:]` | Mais contexto |
| RAG cache in-memory | RAG cache Redis (TTL 30min) | Compartilhado entre workers |
| Confusion tracker in-memory | Confusion tracker Redis | Persistente e compartilhado |
| Memory store in-memory | Memory store Redis + DB reload | Stateless entre workers |
| Triagem falha → is_new_lead=True | Triagem falha → fallback DB direto | Continuidade garantida |

### 2.4 Persistence Layer

| Atual | Alvo | Mudança |
|-------|------|---------|
| ChromaDB local (SQLite) | ChromaDB HTTP server | Multi-instância |
| PostgreSQL direto | PostgreSQL + PgBouncer | Connection pooling |
| Sem campo `ocasiao` | Campo `ocasiao` no briefing | Elimina inferência |
| Sem `google_event_id` | Campo `google_event_id` no agendamento | Gestão do ciclo de vida |

### 2.5 Integration Layer

| Atual | Alvo | Mudança |
|-------|------|---------|
| Google Calendar síncrono via thread executor | google-cloud-calendar async | Native async |
| Disponibilidade estimada por regras | freebusy().query() ao Calendar real | Double-booking eliminado |
| sendUpdates="none" | sendUpdates="externalOnly" | Consultor notificado |
| Sem cancelamento de evento | Cancelamento via google_event_id | Gestão completa |

---

## 3. CORREÇÕES DO SYSTEM PROMPT (IA)

### 3.1 System Prompt Target

```
REGRAS CRÍTICAS ADICIONAIS:

═══════════════════════════════════════════════════════════
REGRA INVIOLÁVEL — NUNCA INFERIR OCASIÃO DA VIAGEM:
═══════════════════════════════════════════════════════════
· NUNCA assuma que a viagem é "lua de mel", "férias", "aniversário", etc.
· A OCASIÃO é um campo obrigatório do briefing — pergunte SEMPRE.
· Pergunta obrigatória após destino + perfil de viajantes:
  "Essa viagem tem alguma ocasião especial?
   Como férias, lua de mel, aniversário, viagem em família, negócios, intercâmbio ou outro?"
· Aceite SOMENTE respostas explícitas do cliente — nunca infira.
· Vale para QUALQUER destino, QUALQUER perfil de viajante.

═══════════════════════════════════════════════════════════
REGRA INVIOLÁVEL — NUNCA INFERIR CARACTERÍSTICAS DO CLIENTE:
═══════════════════════════════════════════════════════════
· Os perfis no CONTEXTO DA BASE DE CONHECIMENTO são GUIAS DE ATENDIMENTO.
· Eles NÃO descrevem o cliente atual — são exemplos de tipos de clientes.
· NUNCA assuma que o cliente atual tem as características de uma persona.
· SEMPRE colete informações diretamente do cliente.
```

### 3.2 Exemplo a Remover

```python
# REMOVER do _ORCHESTRATOR_SYSTEM_TEMPLATE:
# "Lua de mel em Portugal — que combinação incrível! Já tem data em mente?"

# SUBSTITUIR por:
# "Portugal em julho — excelente escolha! Já têm as datas definidas?"
```

### 3.3 Sequência de Briefing Target

```python
_FIELD_QUESTIONS_TARGET = {
    "destino": 'Pergunte o DESTINO em 1 frase',
    "data_ida": 'Pergunte as DATAS em 1 frase',
    "qtd_pessoas": 'Pergunte Nº DE PESSOAS em 1 frase',
    "perfil": 'Pergunte o PERFIL em 1 frase (família, casal, solo, grupo)',
    "ocasiao": 'Pergunte a OCASIÃO ESPECIAL em 1 frase com opções:
                férias / lua de mel / aniversário / família / negócios / outro',
    "orcamento": 'Pergunte o ORÇAMENTO em 1 frase',
    "tem_passaporte": 'Pergunte o PASSAPORTE em 1 frase',
    "completo": '...',
}
```

---

## 4. SCHEMA TARGET DO BANCO

### 4.1 Tabela briefing (com campo ocasiao)

```sql
ALTER TABLE briefing ADD COLUMN ocasiao VARCHAR;
-- Valores aceitos: ferias, lua_de_mel, aniversario, familia, negocios, intercambio, outro
-- NULL = não coletado ainda
```

### 4.2 Tabela agendamento (com google_event_id)

```sql
ALTER TABLE agendamento ADD COLUMN google_event_id VARCHAR;
-- ID retornado pelo Google Calendar events().insert()
-- Permite update e delete do evento
```

### 4.3 Tool persist_lead_data (com ocasiao)

```python
_PERSIST_LEAD_DATA_SCHEMA = {
    "phone": ...,
    "data": {
        "ocasiao": {
            "type": "string",
            "enum": ["ferias", "lua_de_mel", "aniversario", "familia", "negocios", "intercambio", "outro"],
            "description": "SOMENTE quando confirmado explicitamente pelo cliente"
        },
        # outros campos...
    }
}
```

---

## 5. ARQUITETURA DE MEMÓRIA TARGET

```
┌─────────────────────────────────────────────────────────┐
│ CAMADA 1 — SESSÃO (Redis, TTL 2h por wa_id)             │
│   • memory_store (últimas k=20 interações)              │
│   • confusion_tracker (contadores por campo)            │
│   • rag_cache (contextos RAG, TTL 30min)                │
│   • wa_lock (distributed lock, TTL 30s)                 │
└─────────────────────────────────────────────────────────┘
              ↕ Sincronia
┌─────────────────────────────────────────────────────────┐
│ CAMADA 2 — BRIEFING (PostgreSQL, permanente)            │
│   • Todos os campos do briefing incluindo ocasiao       │
│   • completude_pct calculado                            │
│   • Pré-carregado antes do LangGraph (bypass tool)      │
└─────────────────────────────────────────────────────────┘
              ↕ Compressão
┌─────────────────────────────────────────────────────────┐
│ CAMADA 3 — HISTÓRICO (PostgreSQL, permanente)           │
│   • interacao: cada mensagem persistida                 │
│   • conversation_summary: resumo comprimido             │
│   • Reload do DB garante stateless entre workers        │
└─────────────────────────────────────────────────────────┘
```

---

## 6. TRACING DISTRIBUÍDO TARGET

```
Request HTTP (webhook)
    → request_id gerado (middleware)
    → correlation_id = request_id
    → Kafka: correlation_id incluído no payload
    → Consumer: correlation_id extraído
    → LangGraph: correlation_id no OrchestratorState
    → Cada nó loga com correlation_id
    → Tool calls logam com correlation_id
    → WhatsApp reply logado com correlation_id

Resultado: 1 request_id → N logs correlacionados → trace completo
```
