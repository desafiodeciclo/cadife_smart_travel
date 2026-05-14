# 15 — IMPLEMENTATION ROADMAP
## Cadife Smart Travel — Plano Completo de Implementação
**Data:** 2026-05-14 | **Versão:** 1.0.0

---

## FASE 1 — CORREÇÕES CRÍTICAS (1-3 dias)
> **Foco:** Eliminar os bugs que afetam diretamente a experiência do cliente

### 1.1 Fix do Viés "Lua de Mel" (Prioridade MÁXIMA)

**Arquivo:** `backend/app/services/multi_agent_orchestrator.py`

```python
# REMOVER esta linha do _ORCHESTRATOR_SYSTEM_TEMPLATE:
# "· "Lua de mel em Portugal — que combinação incrível! Já tem data em mente?""

# SUBSTITUIR por:
# "· "Portugal em julho — excelente escolha! Já têm as datas definidas?""
```

**Arquivo:** `backend/app/services/multi_agent_orchestrator.py`

```python
# ADICIONAR ao _ORCHESTRATOR_SYSTEM_TEMPLATE após REGRAS DE CONCISÃO:

"""
═══════════════════════════════════════════════════════════
REGRA INVIOLÁVEL — NUNCA INFERIR OCASIÃO DA VIAGEM:
═══════════════════════════════════════════════════════════
· NUNCA assuma "lua de mel", "férias", "aniversário" ou qualquer ocasião.
· A OCASIÃO é um campo obrigatório — pergunte SEMPRE após coletar perfil.
· Pergunta correta: "Essa viagem tem alguma ocasião especial?
  Como férias, lua de mel, aniversário, viagem em família, negócios ou outro?"
· Aceite SOMENTE resposta explícita — nunca infira por destino ou perfil.

REGRA INVIOLÁVEL — PERSONAS NA BASE SÃO GUIAS, NÃO FATOS:
═══════════════════════════════════════════════════════════
· O CONTEXTO DA BASE DE CONHECIMENTO contém perfis de tipos de clientes.
· São GUIAS DE ATENDIMENTO — nunca descrições do cliente atual.
· NUNCA assuma que o cliente tem características de uma persona.
"""
```

**Arquivo:** `backend/knowledge_base/perfis_e_solucoes.md`

Adicionar no início do arquivo:
```markdown
---
**AVISO PARA A IA:** Este documento descreve TIPOS de clientes como guia de atendimento.
NÃO assuma que o cliente atual pertence a algum perfil sem confirmação explícita.
NÃO infira ocasião de viagem (lua de mel, férias, etc.) a partir de destino ou perfil.
SEMPRE pergunte diretamente ao cliente.
---
```

Corrigir PERSONA 8:
```markdown
## PERSONA 8 — "O CASAL EM RECONEXÃO"
### Sinal de Reconhecimento na Conversa
⚠️ IMPORTANTE: A AYA deve PERGUNTAR a ocasião — nunca assumir por "sensibilidade".
Pergunta obrigatória: "Essa viagem tem alguma ocasião especial para vocês?"
NÃO pule essa pergunta, independentemente do perfil percebido.
```

**Prazo:** 0.5 dias  
**Risco:** Baixo — apenas mudanças em prompts e documentação

---

### 1.2 Campo `ocasiao` no Briefing

**Arquivo:** `backend/app/services/multi_agent_orchestrator.py`

```python
# Adicionar ao _FIELD_QUESTIONS:
"ocasiao": (
    'Pergunte a OCASIÃO ESPECIAL em 1 frase com opções: '
    '"Essa viagem tem alguma ocasião especial? '
    'Como férias, lua de mel, aniversário, viagem em família, negócios, intercâmbio ou outro?"'
),

# Atualizar sequência:
# destino → data_ida → qtd_pessoas → perfil → ocasiao → orcamento → tem_passaporte → completo
```

```python
# Adicionar ao _ORCHESTRATOR_TOOLS persist_lead_data:
"ocasiao": {
    "type": "string",
    "enum": ["ferias", "lua_de_mel", "aniversario", "familia", "negocios", "intercambio", "outro"],
    "description": "Ocasião da viagem — SOMENTE quando confirmado pelo cliente"
}
```

**Migration Alembic:**
```python
# migrations/versions/XX_add_ocasiao_to_briefing.py
def upgrade():
    op.add_column("briefing", sa.Column("ocasiao", sa.String(50), nullable=True))

def downgrade():
    op.drop_column("briefing", "ocasiao")
```

**Prazo:** 1 dia  
**Risco:** Baixo — additive change, sem breaking changes

---

### 1.3 Fallback da Triagem com DB Direto

**Arquivo:** `backend/app/services/multi_agent_orchestrator.py`

```python
async def _run_triagem(wa_id: str, db: Optional[AsyncSession]) -> dict[str, Any]:
    ...
    except Exception as exc:
        logger.warning("triagem_agent_failed", wa_id=wa_id, error=str(exc))
        
        # NOVO FALLBACK: busca direta ao DB sem LLM
        if db:
            try:
                from app.services.lead_service import get_lead_context_direct
                return await get_lead_context_direct(db, wa_id)
            except Exception as db_exc:
                logger.error("triagem_db_fallback_failed", wa_id=wa_id, error=str(db_exc))
        
        return DEFAULT_NEW_LEAD_TRIAGEM  # apenas se DB também falhar
```

```python
# lead_service.py — nova função
async def get_lead_context_direct(db: AsyncSession, wa_id: str) -> dict:
    """Fallback: lê contexto do lead diretamente do DB sem chamar LLM."""
    lead = await lead_repo.get_by_phone_hash(wa_id)
    if not lead:
        return DEFAULT_NEW_LEAD_TRIAGEM
    
    briefing = await briefing_repo.get_by_lead(lead.id)
    last_interacao = await interacao_repo.get_latest(lead.id)
    
    return {
        "exists": True,
        "nome": lead.nome,
        "status": lead.status.value,
        "briefing": briefing_to_dict(briefing) if briefing else {},
        "next_field_to_collect": compute_next_field(briefing),
        "is_new_lead": False,
        "last_interaction_at": last_interacao.timestamp.isoformat() if last_interacao else None,
    }
```

**Prazo:** 1 dia  
**Risco:** Médio — nova lógica de negócio crítica

---

## FASE 2 — ESTABILIZAÇÃO (3-7 dias)
> **Foco:** Eliminar race conditions e state in-memory

### 2.1 Distributed Lock por wa_id

```python
# process_whatsapp_message.py
async with redis.lock(f"wa_processing:{wa_id}", timeout=30, blocking_timeout=10):
    await _process_message_internal(payload, db)
```

**Prazo:** 0.5 dias

### 2.2 Idempotência de Webhooks

```python
# process_whatsapp_message.py — início da função
if message_id:
    already_processed = await interacao_repo.find_by_wamid(message_id)
    if already_processed:
        logger.info("duplicate_webhook_ignored", wamid=message_id)
        return
```

**Prazo:** 0.5 dias

### 2.3 RAG Cache em Redis

```python
# multi_agent_orchestrator.py
async def _get_rag_context_cached(cache_key: str) -> str | None:
    return await redis.get(f"rag:{cache_key}")

async def _set_rag_context_cached(cache_key: str, ctx: str) -> None:
    await redis.setex(f"rag:{cache_key}", 1800, ctx)  # TTL 30min
```

**Prazo:** 1 dia

### 2.4 Confusion Tracker em Redis

```python
# multi_agent_orchestrator.py
async def _get_confusion_count(wa_id: str, field: str) -> int:
    key = f"confusion:{wa_id}:{field}"
    count = await redis.get(key)
    return int(count) if count else 0

async def _increment_confusion(wa_id: str, field: str) -> int:
    key = f"confusion:{wa_id}:{field}"
    count = await redis.incr(key)
    await redis.expire(key, 86400)  # 24h TTL
    return count
```

**Prazo:** 0.5 dias

### 2.5 google_event_id no Banco

```sql
ALTER TABLE agendamento ADD COLUMN google_event_id VARCHAR;
```

```python
# google_calendar_service.py — retornar também o event_id
return created.get("hangoutLink"), created.get("id")  # (meet_link, event_id)
```

**Prazo:** 0.5 dias

### 2.6 Verificação Real de Disponibilidade

```python
# curadoria_service.py
async def check_calendar_busy(data: date, hora: time) -> bool:
    """Verifica se há conflito no Google Calendar."""
    service = _build_service()
    if not service:
        return False  # Assume disponível se sem credenciais
    
    inicio = datetime.combine(data, hora, tzinfo=ZoneInfo("America/Sao_Paulo"))
    fim = inicio + timedelta(hours=1)
    
    result = service.freebusy().query({
        "timeMin": inicio.isoformat(),
        "timeMax": fim.isoformat(),
        "items": [{"id": settings.GOOGLE_CALENDAR_ID}]
    }).execute()
    
    busy = result["calendars"][settings.GOOGLE_CALENDAR_ID]["busy"]
    return len(busy) > 0
```

**Prazo:** 1 dia

### 2.7 Notificação FCM Seletiva

```python
# process_whatsapp_message.py
async def _enqueue_qualified_notification(db, lead, briefing):
    if lead.consultor_id:
        # Notificar apenas o consultor atribuído
        consultor = await user_repo.get(lead.consultor_id)
        tokens = [consultor.fcm_token] if consultor and consultor.fcm_token else []
    else:
        # Sem consultor → notificar todos
        consultores = await user_repo.get_all_consultores_with_token()
        tokens = [c.fcm_token for c in consultores]
    ...
```

**Prazo:** 0.5 dias

---

## FASE 3 — QUALIDADE E OBSERVABILIDADE (7-14 dias)
> **Foco:** Métricas, alertas e rastreabilidade completa

### 3.1 Correlation ID no LangGraph

```python
# OrchestratorState adicionar:
"correlation_id": str  # propagado do HTTP request

# Cada nó loga com correlation_id:
logger.info("node_triagem_completed", correlation_id=state["correlation_id"], ...)
```

**Prazo:** 1 dia

### 3.2 Health Check Detalhado

```python
@router.get("/health/detailed")
async def detailed_health(db: AsyncSession = Depends(get_db)):
    # Verifica DB, Redis, ChromaDB, Kafka producer
    ...
```

**Prazo:** 0.5 dias

### 3.3 Mascaramento de PII em Logs

```python
def mask_phone(phone: str) -> str:
    return f"+55...{phone[-4:]}" if phone else ""
```

**Prazo:** 0.5 dias

### 3.4 Métricas Prometheus

```python
# Adicionar prometheus-client ao requirements.txt
# Implementar métricas: webhook_latency, ai_latency, hallucination_count
```

**Prazo:** 2 dias

### 3.5 Janela de Contexto Ampliada

```python
# multi_agent_orchestrator.py
# MUDAR:
messages.extend(state["conversation_history"][-6:])
# PARA:
messages.extend(state["conversation_history"][-10:])
```

**Prazo:** 0.5 dias

---

## FASE 4 — ESCALABILIDADE (14-30 dias)
> **Foco:** Preparação para produção real em escala

### 4.1 ChromaDB HTTP Server

```yaml
# docker-compose.yml — adicionar serviço ChromaDB HTTP
chroma:
  image: chromadb/chroma:latest
  ports:
    - "8001:8000"
  volumes:
    - chroma_data:/chroma/chroma
```

```python
# rag_service.py — migrar para HTTP client
import chromadb
_client = chromadb.HttpClient(host="chroma", port=8000)
```

**Prazo:** 2 dias

### 4.2 PgBouncer

```yaml
# docker-compose.yml
pgbouncer:
  image: pgbouncer/pgbouncer:latest
  ports:
    - "5432:5432"
  environment:
    DATABASES_HOST: db
    POOL_MODE: transaction
    MAX_CLIENT_CONN: 200
    DEFAULT_POOL_SIZE: 25
```

**Prazo:** 1 dia

### 4.3 Migrar Triagem para Modelo Pago

```python
# settings.py
OPENROUTER_TRIAGEM_MODEL = "google/gemini-2.0-flash-001"  # em vez de qwen free
```

**Prazo:** 0.5 dias (configuração), custo operacional adicional

### 4.4 Rate Limit por wa_id no Webhook

```python
# rate_limiter.py
# Mudar rate limit key de IP para wa_id
```

**Prazo:** 0.5 dias

---

## CHECKLIST DE IMPLEMENTAÇÃO

### Fase 1 (Crítico — fazer agora)
- [ ] Remover exemplo "Lua de mel em Portugal" do system prompt
- [ ] Adicionar regra "NUNCA inferir ocasião" no system prompt
- [ ] Adicionar aviso de persona na base RAG
- [ ] Corrigir PERSONA 8 em perfis_e_solucoes.md
- [ ] Adicionar campo `ocasiao` ao schema briefing
- [ ] Migration Alembic para `ocasiao`
- [ ] Adicionar `ocasiao` à tool `persist_lead_data`
- [ ] Adicionar pergunta de ocasião à sequência do briefing
- [ ] Implementar fallback da triagem com DB direto

### Fase 2 (Alta prioridade — próxima semana)
- [ ] Distributed lock Redis por wa_id
- [ ] Idempotência por wamid
- [ ] RAG cache em Redis
- [ ] Confusion tracker em Redis
- [ ] google_event_id no banco e no service
- [ ] Verificação real de disponibilidade (freebusy)
- [ ] FCM seletivo por consultor atribuído

### Fase 3 (Qualidade — próximas 2 semanas)
- [ ] Correlation ID no LangGraph
- [ ] Health check detalhado
- [ ] Mascaramento de PII em logs
- [ ] Prometheus metrics endpoint
- [ ] Ampliar janela de contexto [-6:] → [-10:]

### Fase 4 (Escala — próximo mês)
- [ ] ChromaDB HTTP server
- [ ] PgBouncer connection pooling
- [ ] Migrar triagem para modelo pago
- [ ] Rate limit por wa_id no webhook
- [ ] Sentry para error aggregation
- [ ] Grafana dashboard operacional
