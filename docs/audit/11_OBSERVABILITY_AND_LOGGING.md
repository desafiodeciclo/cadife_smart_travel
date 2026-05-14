# 11 — OBSERVABILITY AND LOGGING
## Cadife Smart Travel — Análise de Observabilidade e Logging
**Data:** 2026-05-14 | **Versão:** 1.0.0

---

## 1. STACK DE OBSERVABILIDADE ATUAL

| Componente | Ferramenta | Status |
|------------|-----------|--------|
| Structured Logging | structlog | ✅ Implementado |
| Request Tracing | Request-ID Middleware | ✅ Implementado |
| LLM Tracing | LangFuse + LangSmith | ✅ Configurado |
| AI Alerts | Slack Webhook | ✅ Parcial |
| Audit Trail | audit_trail Middleware | ✅ Implementado |
| Metrics | Prometheus | ❌ Ausente |
| Distributed Tracing | OpenTelemetry | ❌ Ausente |
| APM Dashboard | Grafana | ❌ Ausente |
| Error Aggregation | Sentry | ❌ Ausente |
| Health Check Detalhado | — | ❌ Incompleto |

---

## 2. LOGGING ESTRUTURADO (STRUCTLOG)

### 2.1 Implementação

```python
import structlog
logger = structlog.get_logger()

# Exemplo típico de log:
logger.info(
    "orchestrate_completed",
    wa_id=wa_id,
    latency_ms=latency_ms,
    model_triagem=settings.OPENROUTER_TRIAGEM_MODEL,
    model_orchestrator=settings.OPENROUTER_CONVERSION_MODEL,
    response_len=len(response),
    next_field=next_field,
    confusion_count=confusion_count,
    rag_context_chars=len(rag_context),
)
```

**Avaliação positiva:** Os logs estruturados incluem campos contextuais ricos (`wa_id`, `latency_ms`, `next_field`). Isso é excelente para debugging e análise posterior.

### 2.2 Eventos Logados (principais)

| Evento | Nível | Campos |
|--------|-------|--------|
| `webhook_verified` | INFO | — |
| `webhook_invalid_signature` | WARN | path |
| `processing_whatsapp_message` | INFO | phone, msg_type |
| `lead_status_updated` | INFO | lead_id, new_status |
| `triagem_completed` | INFO | wa_id, exists, next_field |
| `rag_mandatory_retrieved` | INFO | wa_id, query_preview, context_chars |
| `orchestrate_completed` | INFO | wa_id, latency_ms, confusion_count |
| `hallucination_detected_orchestrator` | WARN | wa_id, types, snippet |
| `code_leak_blocked` | ERROR | wa_id, snippet |
| `ai_confusion_detected` | WARN | wa_id, stuck_field, consecutive_attempts |
| `google_meet_event_created` | INFO | event_id, meet_link |
| `whatsapp_reply_dispatched` | INFO | lead_id, success, wamid, latency_ms |

### 2.3 Problemas no Logging

**PROBLEMA 1 — Ausência de correlation_id no pipeline LangGraph:**

O `request_id` gerado pelo middleware de request tracing não é propagado para dentro do pipeline LangGraph. Quando o processamento ocorre em BackgroundTask ou Kafka consumer, o `request_id` HTTP original é perdido.

**Consequência:** Não é possível correlacionar logs de um processamento específico quando ele ocorre em background.

**Solução:**
```python
# Propagar correlation_id para o estado do grafo
initial_state["correlation_id"] = request_id  # extraído do middleware
# E logar em cada nó:
logger.info("node_executed", correlation_id=state["correlation_id"], node="triagem")
```

**PROBLEMA 2 — Logs de PII (dados sensíveis):**

Verificar que `phone` e `nome` não aparecem em logs em claro. O sistema usa `telefone_hash` nos modelos, mas em logs como `processing_whatsapp_message` o `phone` (número real) é logado.

**Risco:** Logs exportados para sistemas de observabilidade externos (LangFuse, LangSmith) podem conter PII.

**Solução:** Mascarar telefone nos logs:
```python
masked_phone = f"+55...{phone[-4:]}"
logger.info("processing_whatsapp_message", phone=masked_phone, ...)
```

---

## 3. REQUEST ID MIDDLEWARE

### 3.1 Implementação

```python
# presentation/middlewares/request_id.py
# Atribui X-Request-ID único a cada request
# Disponível no header de resposta
```

**Avaliação positiva:** Implementado corretamente. O `X-Request-ID` permite correlacionar logs de um request específico nos logs do servidor.

**Limitação:** Como mencionado, não é propagado para BackgroundTasks ou Kafka consumers.

---

## 4. TRACING DE LLM (LANGFUSE + LANGSMITH)

### 4.1 Configuração

```bash
# LangSmith
LANGCHAIN_TRACING_V2=true
LANGCHAIN_API_KEY=
LANGCHAIN_PROJECT=cadife-smart-travel

# LangFuse
LANGFUSE_PUBLIC_KEY=
LANGFUSE_SECRET_KEY=
LANGFUSE_HOST=
```

### 4.2 O que é Rastreado

- Cada chamada LLM (modelo, tokens, latência, custo)
- Tool calls (nome, argumentos, resultado)
- Erros de LLM e retries
- Fluxo do grafo LangGraph (nó a nó)

**Avaliação positiva:** O dual tracing (LangFuse + LangSmith) é redundante mas adequado para um MVP onde a escolha final de ferramenta de observabilidade ainda não foi feita.

### 4.3 Gap: Custo por Conversa

Não há cálculo automático do custo por conversa (tokens × preço). O LangFuse pode fornecer isso, mas precisa de configuração de preços dos modelos.

---

## 5. ALERTAS E NOTIFICAÇÕES

### 5.1 Alertas Implementados

```python
# alert_service.py
# Slack webhook para:
# - Alucinação detectada (prices, availability, booking promises)
# - Confusão da IA (campo repetido 2+ vezes)
# - Erros críticos do orchestrador
```

### 5.2 Gaps nos Alertas

| Condição de Alerta | Status |
|-------------------|--------|
| Alucinação detectada | ✅ |
| IA confusa (campo repetido) | ✅ |
| Erro HTTP do orchestrador | ✅ via Kafka |
| Kafka consumer lag alto | ❌ |
| Webhook taxa de erro alta | ❌ |
| DB response time alto | ❌ |
| Redis indisponível | ❌ |
| Muitas DLQ messages | ❌ |
| Latência de resposta WhatsApp alta | ❌ |

---

## 6. HEALTH CHECK

### 6.1 Implementação Atual

```python
GET /health  # Público, sem auth
# Retorna apenas: {"status": "ok"}
```

**Problema:** Health check não verifica subserviços:
- PostgreSQL (conectado?)
- Redis (conectado?)
- Kafka (producer disponível?)
- ChromaDB (vectorstore carregado?)
- OpenRouter API (acessível?)

### 6.2 Health Check Recomendado

```python
@router.get("/health")
async def health_check(db: AsyncSession = Depends(get_db)) -> dict:
    checks = {}

    # DB check
    try:
        await db.execute(text("SELECT 1"))
        checks["database"] = "ok"
    except Exception:
        checks["database"] = "error"

    # Redis check
    try:
        await redis_client.ping()
        checks["redis"] = "ok"
    except Exception:
        checks["redis"] = "degraded"

    # ChromaDB check
    try:
        count = rag_service.get_rag_document_count()
        checks["chromadb"] = f"ok ({count} chunks)"
    except Exception:
        checks["chromadb"] = "degraded"

    status = "ok" if checks["database"] == "ok" else "degraded"
    return {"status": status, "checks": checks}
```

---

## 7. MÉTRICAS AUSENTES

### 7.1 Métricas Críticas para Produção

| Métrica | Descrição | Importância |
|---------|-----------|-------------|
| `webhook_latency_p99` | Percentil 99 de latência do webhook | Crítica |
| `ai_pipeline_latency_p99` | Latência do pipeline LangGraph | Crítica |
| `llm_token_cost_total` | Custo total de tokens | Alta |
| `leads_created_per_hour` | Volume de novos leads | Alta |
| `briefing_completion_rate` | % de briefings completados | Alta |
| `kafka_consumer_lag` | Mensagens acumuladas sem processar | Alta |
| `whatsapp_send_error_rate` | Taxa de falha no envio | Alta |
| `hallucination_rate` | Taxa de alucinações detectadas | Alta |
| `rag_cache_hit_rate` | % de hits no cache RAG | Média |
| `google_calendar_error_rate` | Taxa de falha no Calendar | Média |

### 7.2 Implementação Recomendada (Prometheus)

```python
from prometheus_client import Counter, Histogram, Gauge

WEBHOOK_LATENCY = Histogram("webhook_latency_seconds", "Webhook processing time")
LEADS_CREATED = Counter("leads_created_total", "Total leads created", ["origem"])
AI_LATENCY = Histogram("ai_pipeline_latency_seconds", "AI pipeline latency")
HALLUCINATION_COUNT = Counter("hallucination_detected_total", "Hallucinations caught")
```

---

## 8. AUDIT TRAIL

### 8.1 Implementação

```python
# presentation/middlewares/audit_trail.py
# Loga todas as ações críticas:
# - Login/logout
# - Criação de lead
# - Atribuição de consultor
# - Criação de proposta
# - Agendamento
```

**Avaliação positiva:** Audit trail implementado como middleware — captura ações automaticamente sem necessidade de adicionar código em cada endpoint.

### 8.2 Tabela audit_log

```sql
audit_log:
  id              UUID
  action          VARCHAR
  user_id         UUID
  resource_type   VARCHAR
  resource_id     UUID
  timestamp       TIMESTAMP
  details         JSONB
```

**Retenção:** Deve ser mantida por mínimo 90 dias (requisito legal no `Development_rules.md`). Verificar se há política de expiração configurada.

---

## 9. RECOMENDAÇÕES PRIORITÁRIAS

### 9.1 Imediatas

1. **Mascarar telefone em logs** — compliance LGPD
2. **Health check completo** — verificar todos os subserviços

### 9.2 Curto Prazo

3. **Correlation ID no LangGraph** — propagar request_id para background processing
4. **Alertas de Kafka lag** — detectar backlog de mensagens
5. **Alertas de webhook error rate** — detectar problemas de entrega

### 9.3 Médio Prazo

6. **Prometheus + Grafana** — métricas operacionais em tempo real
7. **Sentry** — agregação de erros com stack trace
8. **SLO definido** — p99 latência < 20s end-to-end (Meta SLA + processamento)
