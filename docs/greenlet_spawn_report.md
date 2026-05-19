# 🔴 Relatório: `greenlet_spawn has not been called` — Cadife Smart Travel

> **Data:** 2026-05-18 | **Autor:** Análise Técnica — Antigravity  
> **Escopo:** Backend FastAPI + SQLAlchemy Async (`/opt/cadife/app/backend`)

---

## 1. O Que É o Erro

O erro `sqlalchemy.exc.MissingGreenlet: greenlet_spawn has not been called; can't call await_only() here` é levantado pelo SQLAlchemy 2.x quando código ORM que requer um contexto `async` é executado **fora de um loop de evento** ou **depois que a sessão que originou o objeto foi fechada/comitada sem refresh**.

### Mecânica interna

```
Event Loop asyncio
    └─ await session.execute(...)        ← OK: dentro do contexto greenlet async
         └─ ORM expira atributos após commit
              └─ acesso a lead.briefing  ← BOOM: lazy-load sem greenlet ativo
```

O SQLAlchemy Async usa **greenlets** como contexto de execução para as operações de I/O. Quando você acessa um atributo **lazy-loaded** de um objeto ORM fora do contexto greenlet correto — por exemplo, depois que a sessão foi comitada e os atributos foram **expirados** — o SQLAlchemy tenta fazer um SELECT implícito, mas não tem o contexto async necessário.

### Variações do mesmo problema

| Erro | Causa raiz |
|------|-----------|
| `MissingGreenlet: greenlet_spawn has not been called` | Lazy-load de atributo ORM fora de contexto async |
| `DetachedInstanceError` | Objeto ORM acessado depois que sua sessão foi fechada |
| `PendingRollbackError` | Commit/flush em sessão com transação abortada não revertida |
| Dados **silenciosamente não persistidos** | Exception engolida antes do `commit()` final |

---

## 2. Contexto do Projeto — Arquitetura de Sessões

O projeto usa **SQLAlchemy 2.x async** com PostgreSQL e segue uma arquitetura limpa. A sessão é gerenciada de três formas:

```
┌─────────────────────────────────────────────────────────────┐
│  Modo 1: Request-scoped (HTTP routes)                       │
│  get_db() → yield AsyncSession → fechada no fim do request  │
├─────────────────────────────────────────────────────────────┤
│  Modo 2: Background Task (webhook WhatsApp)                 │
│  execute_with_own_session() → AsyncSessionLocal() própria   │
├─────────────────────────────────────────────────────────────┤
│  Modo 3: Scheduled Jobs (APScheduler)                       │
│  expire_stale_leads() / NotificationWorker.run()            │
│  → AsyncSessionLocal() própria por execução                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Causas Raiz Identificadas no Código

### 🔴 Causa #1 — `_notify_checkpoint` usa sessão já comitada (CRÍTICO)

**Arquivo:** `app/services/checkpoint_service.py` — linha 73  
**Arquivo:** `app/routes/propostas.py` — linhas 204–209

```python
# checkpoint_service.py:73 — PROBLEMA
asyncio.ensure_future(_notify_checkpoint(db, lead_id, checkpoint))
#                      ^^
# `db` é a sessão do request que PODE ser fechada antes de _notify_checkpoint rodar.
# Quando _notify_checkpoint acessa lead.consultor_id (lazy-load),
# a sessão já foi comitada/expirada → MissingGreenlet.

# propostas.py:204 — PROBLEMA IDÊNTICO
asyncio.ensure_future(
    activate_checkpoint(db, proposta.lead_id, TravelCheckpoint.proposta_enviada, SISTEMA)
)
# Sessão do request passada para uma task fire-and-forget.
# O request pode terminar antes da task executar.
```

**Por que os dados não persistem:** `_notify_checkpoint` tenta executar queries com uma sessão já encerrada. A task falha silenciosamente (sem `await`), o `flush()` dentro de `activate_checkpoint` nunca ocorre.

---

### 🔴 Causa #2 — `persist_lead_data` e sessão dupla no fluxo do orquestrador (CRÍTICO)

**Arquivo:** `app/services/ai_tools.py` — linhas 438–495

```python
async def _persist_lead_data(phone, data, db):
    # db é a sessão do _process() passada pelo orquestrador.
    # A função cria uma NOVA sessão isolada (correto), mas...
    async with AsyncSessionLocal() as isolated_db:
        lead = await upsert_lead_with_resilience(isolated_db, {"telefone": phone})
        briefing = await update_briefing_from_extraction(isolated_db, lead, briefing_in)
        # ← commit() acontece AQUI dentro de isolated_db

    # Depois desse bloco, o `lead` na sessão ORIGINAL (db de _process)
    # tem todos os atributos EXPIRADOS. Quando _process tenta:
    #   → await db.refresh(lead)      ← linha 190 de process_whatsapp_message.py
    # O `lead` ainda aponta para a OUTRA sessão (isolated_db) que já foi fechada.
```

**Fluxo problemático:**
```
_process(db)
  └─ orchestrate(db) → _dispatch_tool("persist_lead_data", db)
       └─ _persist_lead_data(phone, data, db=db)
            └─ async with AsyncSessionLocal() as isolated_db:  ← sessão nova
                 └─ upsert_lead + update_briefing  ← commit em isolated_db
            # isolated_db FECHADA
       # retorna ao _process
  └─ await db.refresh(lead)  ← lead foi obtido da sessão db original
                               mas isolated_db fez commits que expiraram
                               atributos no identity map de db → greenlet_spawn
```

---

### 🟠 Causa #3 — Múltiplos `commit()` encadeados sem `refresh` intermediário

**Arquivo:** `app/services/lead_service.py` — `update_briefing_from_extraction()`

```python
async def update_briefing_from_extraction(db, lead, extracted):
    # ...
    await db.flush()                    # ← expira atributos

    if briefing.completude_pct >= 60 and lead.status == LeadStatus.em_atendimento:
        await update_lead_status(db, lead, LeadStatus.qualificado)
        #     ↑ update_lead_status faz commit() internamente → expira lead.status

    # Aqui: lead.status pode ser stale/expirado.
    # Acesso a lead.status ou lead.score dispara lazy-load
    await _persist_score(db, lead, ...)  # acessa lead.score → potencial greenlet

    await db.commit()       # ← segundo commit
    await db.refresh(briefing)
    await db.refresh(lead)  # refresh tardio — erros já ocorreram antes
```

O problema: `update_lead_status` comita internamente. Depois disso, `lead.status` é expirado. `_persist_score` acessa `lead.score` antes do `refresh` → greenlet se o acesso for lazy.

---

### 🟡 Causa #4 — `expire_on_commit=False` não está globalmente protegendo todos os casos

**Arquivo:** `app/infrastructure/persistence/database.py` — linha 33

```python
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,   # ← correto, mas...
    autocommit=False,
    autoflush=False,
)
```

`expire_on_commit=False` evita que atributos expirem **após commit na mesma sessão**. Mas **NÃO** protege quando:

1. Uma **segunda sessão** (ex: `isolated_db`) faz commit e o objeto ainda existe na primeira sessão.
2. O objeto é passado entre sessões diferentes.
3. O objeto é acessado depois que sua sessão original foi fechada (ex: `asyncio.ensure_future`).

---

### 🟡 Causa #5 — `save_interacao` não faz `db.refresh()` e pode falhar silenciosamente

**Arquivo:** `app/services/lead_service.py` — linha 602–628

```python
async def save_interacao(db, lead_id, msg_cliente, msg_ia, tipo, ...):
    interacao = Interacao(lead_id=lead_id, ...)
    db.add(interacao)
    await db.commit()
    return interacao   # ← sem db.refresh(interacao)
                       # Se update_interacao_send_result acessar
                       # campos gerados pelo banco (timestamp, id),
                       # pode levantar MissingGreenlet
```

---

## 4. Mapa do Fluxo Crítico — WhatsApp → Banco

```
POST /webhook/whatsapp
  │
  ├─ [Request] 200 retornado imediatamente
  │
  └─ [BackgroundTask] execute_with_own_session(payload)
       └─ async with AsyncSessionLocal() as db:  ← sessão própria ✅
            └─ execute(payload, db)
                 └─ _process(msg, db)
                      ├─ upsert_lead_with_resilience(db)  → commit ✅
                      ├─ update_lead_status(db)           → commit ✅
                      ├─ orchestrate(db)
                      │    └─ persist_lead_data(db)
                      │         └─ AsyncSessionLocal() isolated_db
                      │              └─ update_briefing  → commit em isolated_db
                      │         # isolated_db fechada
                      │    # db.refresh(lead) ← FALHA SE lead veio de isolated_db
                      │
                      ├─ update_briefing_from_extraction(db)
                      │    ├─ flush()
                      │    ├─ update_lead_status() → commit interno
                      │    ├─ _persist_score()     ← acessa lead expirado 🔴
                      │    └─ commit() + refresh()
                      │
                      ├─ save_interacao(db)       → commit ✅
                      └─ update_interacao_send_result(db) → commit ✅
```

---

## 5. Impacto na Persistência de Dados

| Operação | Situação Atual | Dado Perdido |
|----------|---------------|--------------|
| Briefing via IA (`persist_lead_data`) | `isolated_db` fecha antes do `refresh` na sessão pai | Campos do briefing frequentemente não aparecem no CRM |
| Score do lead | `_persist_score` pode acessar lead expirado → rollback silencioso | Histórico de score não salvo (`lead_score_history` vazia) |
| Checkpoint `briefing_coletado` | `asyncio.ensure_future` com sessão expirada | Checkpoint não criado → progresso da viagem perdido |
| Checkpoint `proposta_enviada/aprovada` | Mesmo problema em `propostas.py` | Status de proposta não refletido no timeline |
| Notificação FCM no checkpoint | `_notify_checkpoint(db, ...)` com sessão fechada | Consultor/cliente não notificado |
| Status `qualificado` automático | Commit intermediário expira `lead.status` | Lead fica preso em `em_atendimento` |

---

## 6. Plano de Melhoria, Correção e Implementação

### Fase 1 — Correções Críticas (Prioridade ALTA — implementar imediatamente)

#### Fix 1.1 — `asyncio.ensure_future` com sessão própria

**Arquivo:** `app/services/checkpoint_service.py`

```python
# ❌ ANTES (linha 73)
asyncio.ensure_future(_notify_checkpoint(db, lead_id, checkpoint))

# ✅ DEPOIS — cria sessão independente dentro da task
async def _spawn_notify_checkpoint(lead_id: uuid.UUID, checkpoint: TravelCheckpoint) -> None:
    """Cria sessão própria para não depender da sessão do request."""
    from app.infrastructure.persistence.database import AsyncSessionLocal
    try:
        async with AsyncSessionLocal() as notify_db:
            await _notify_checkpoint(notify_db, lead_id, checkpoint)
    except Exception as exc:
        logger.error("checkpoint_notify_spawn_failed", lead_id=str(lead_id), error=str(exc))

# Em activate_checkpoint():
asyncio.ensure_future(_spawn_notify_checkpoint(lead_id, checkpoint))
```

**Arquivo:** `app/routes/propostas.py`

```python
# ❌ ANTES (linhas 204–209)
asyncio.ensure_future(
    activate_checkpoint(db, proposta.lead_id, TravelCheckpoint.proposta_enviada, SISTEMA)
)

# ✅ DEPOIS — spawn com sessão própria
async def _spawn_checkpoint(lead_id: uuid.UUID, checkpoint: TravelCheckpoint) -> None:
    from app.infrastructure.persistence.database import AsyncSessionLocal
    from app.services.checkpoint_service import activate_checkpoint, SISTEMA
    try:
        async with AsyncSessionLocal() as cp_db:
            await activate_checkpoint(cp_db, lead_id, checkpoint, SISTEMA)
    except Exception as exc:
        logger.error("proposta_checkpoint_failed", lead_id=str(lead_id), error=str(exc))

# Uso:
asyncio.ensure_future(_spawn_checkpoint(proposta.lead_id, TravelCheckpoint.proposta_enviada))
```

---

#### Fix 1.2 — `_persist_lead_data` — re-buscar o lead na sessão pai após isolated_db fechar

**Arquivo:** `app/services/ai_tools.py`

```python
# ✅ DEPOIS — após o bloco isolated_db, o _process não precisa fazer refresh
# do lead original porque persist_lead_data opera em sessão completamente isolada.
# O problema é que _process.py linha 190 faz await db.refresh(lead)
# onde `lead` ainda é o objeto da sessão `db` (não de isolated_db).
# A solução é garantir que _process re-busque o lead da DB após orchestrate().

# Em process_whatsapp_message.py, linha 186–191:
# ❌ ANTES
reply = await multi_agent_orchestrator.orchestrate(...)
await db.refresh(lead)  # ← potencialmente problemático

# ✅ DEPOIS
reply = await multi_agent_orchestrator.orchestrate(...)
# Re-buscar o lead da DB garante que temos o estado mais recente
# sem depender de refresh de objeto potencialmente de outra sessão.
from app.services.lead_service import get_lead_by_id
refreshed = await get_lead_by_id(db, lead_id)
if refreshed:
    lead = refreshed
```

---

#### Fix 1.3 — `update_briefing_from_extraction` — refresh após cada commit intermediário

**Arquivo:** `app/services/lead_service.py`

```python
async def update_briefing_from_extraction(db, lead, extracted):
    # ... atualiza campos do briefing ...

    await db.flush()

    if briefing.completude_pct >= 60 and lead.status == LeadStatus.em_atendimento:
        await update_lead_status(db, lead, LeadStatus.qualificado, triggered_by="ai_auto")
        # ✅ ADICIONAR: refresh imediato após commit interno de update_lead_status
        await db.refresh(lead)
        logger.info("lead_qualified", lead_id=str(lead.id), completude=briefing.completude_pct)

    # ✅ Passa briefing explicitamente para evitar qualquer lazy-load
    await _persist_score(db, lead, engajamento_rapido=engajamento, motivo="auto", briefing=briefing)

    await db.commit()
    await db.refresh(briefing)
    await db.refresh(lead)
    return briefing
```

---

#### Fix 1.4 — `save_interacao` — adicionar `refresh` após commit

**Arquivo:** `app/services/lead_service.py`

```python
async def save_interacao(db, lead_id, msg_cliente, msg_ia, tipo, ...):
    interacao = Interacao(lead_id=lead_id, ...)
    db.add(interacao)
    await db.commit()
    await db.refresh(interacao)  # ✅ ADICIONAR — garante id/timestamp gerados pelo DB
    return interacao
```

---

### Fase 2 — Melhorias Estruturais (Prioridade MÉDIA)

#### Melhoria 2.1 — Unit of Work explícito no fluxo de webhook

Extrair toda a lógica de `_process` para usar um único `commit()` ao final, usando `flush()` intermediário para detectar constraint violations:

```python
async def _process(msg: dict, db: AsyncSession) -> None:
    # ... toda a lógica usando apenas flush() ...

    # Único commit ao final:
    try:
        await db.commit()
    except Exception as exc:
        await db.rollback()
        logger.error("process_commit_failed", error=str(exc))
        raise
```

#### Melhoria 2.2 — Utilitário `spawn_with_own_session`

Criar um helper reutilizável para eliminar o pattern repetitivo:

```python
# app/infrastructure/persistence/session_utils.py

import asyncio
import structlog
from typing import Callable, Coroutine, Any

logger = structlog.get_logger()

def spawn_with_own_session(
    coro_factory: Callable[..., Coroutine],
    *args,
    task_name: str = "background_task",
    **kwargs,
) -> None:
    """
    Spawna uma coroutine em background com sessão DB própria.
    Substitui asyncio.ensure_future(coro(db, ...)) que reutiliza sessão do request.

    Uso:
        spawn_with_own_session(
            _notify_checkpoint, lead_id, checkpoint,
            task_name="checkpoint_notify"
        )
    """
    from app.infrastructure.persistence.database import AsyncSessionLocal

    async def _wrapper():
        try:
            async with AsyncSessionLocal() as db:
                await coro_factory(db, *args, **kwargs)
        except Exception as exc:
            logger.error(f"{task_name}_failed", error=str(exc), exc_info=True)

    asyncio.ensure_future(_wrapper())
```

#### Melhoria 2.3 — Carregar relacionamentos com `selectinload` nos pontos críticos

Garantir que todos os atributos necessários estejam **eager loaded** antes de qualquer commit:

```python
# Em lead_service.get_lead_by_id — já faz selectinload ✅
# Garantir que update_briefing_from_extraction receba o lead com briefing pré-carregado.

# Em _process, antes de chamar update_briefing_from_extraction:
lead = await get_lead_by_id(db, lead_id)  # carrega briefing via selectinload
```

---

### Fase 3 — Implementação de Guardrails e Observabilidade (Prioridade BAIXA)

#### Guardrail 3.1 — Detectar e logar MissingGreenlet em produção

```python
# Em main.py ou middleware global:
from sqlalchemy.exc import MissingGreenlet

@app.exception_handler(MissingGreenlet)
async def missing_greenlet_handler(request, exc):
    logger.error(
        "missing_greenlet_detected",
        path=request.url.path,
        error=str(exc),
        exc_info=True,
    )
    return JSONResponse(
        status_code=500,
        content={"detail": "Erro interno de persistência. Dados não salvos."}
    )
```

#### Guardrail 3.2 — Teste de integração para o fluxo de webhook

```python
# tests/integration/test_webhook_persistence.py

async def test_briefing_persists_after_orchestrator_tool_call(db_session, mock_whatsapp):
    """
    Garante que persist_lead_data salva dados mesmo quando
    o orquestrador cria sessão isolada internamente.
    """
    payload = build_whatsapp_payload(phone="5511999999999", text="Quero ir para Lisboa")
    await execute_with_own_session(payload)

    # Verifica persistência real no banco
    lead = await lead_service.get_or_create_by_phone(db_session, "5511999999999")
    briefing = await briefing_repo.get_by_lead_id(db_session, lead.id)
    assert briefing is not None, "Briefing deve ser criado mesmo via sessão isolada"
```

#### Guardrail 3.3 — Monitoramento de dados não persistidos

Adicionar métricas Prometheus/structlog para detectar quando dados deveriam ter sido salvos mas não foram:

```python
# Adicionar em update_briefing_from_extraction:
logger.info(
    "briefing_persistence_checkpoint",
    lead_id=str(lead.id),
    completude_antes=completude_antes,
    completude_depois=briefing.completude_pct,
    campos_atualizados=list(updated_fields),
)
```

---

## 7. Resumo das Correções por Arquivo

| Arquivo | Linha(s) | Tipo | Fix |
|---------|----------|------|-----|
| `checkpoint_service.py` | 73 | 🔴 Crítico | `ensure_future` com sessão própria |
| `routes/propostas.py` | 204, 208 | 🔴 Crítico | `ensure_future` com sessão própria |
| `process_whatsapp_message.py` | 190 | 🔴 Crítico | Re-buscar lead via `get_lead_by_id` |
| `lead_service.py` | `update_briefing_from_extraction` | 🟠 Importante | `refresh(lead)` após commit intermediário |
| `lead_service.py` | `save_interacao` | 🟡 Moderado | `refresh(interacao)` após commit |
| `session_utils.py` | novo arquivo | 🟢 Melhoria | Helper `spawn_with_own_session` |

---

## 8. Checklist de Implementação

### Fase 1 — Crítica (deve ser feita AGORA)

- [ ] Fix `checkpoint_service.py:73` — substituir `ensure_future(coro(db, ...))` por sessão própria
- [ ] Fix `propostas.py:204,208` — mesmo padrão
- [ ] Fix `process_whatsapp_message.py:190` — re-buscar lead após orchestrate
- [ ] Fix `lead_service.py` — `refresh(lead)` após `update_lead_status` em `update_briefing_from_extraction`
- [ ] Fix `lead_service.py` — `refresh(interacao)` em `save_interacao`

### Fase 2 — Estrutural

- [ ] Criar `app/infrastructure/persistence/session_utils.py` com `spawn_with_own_session`
- [ ] Substituir todos os `asyncio.ensure_future(coro(db, ...))` pelo helper
- [ ] Revisar fluxo `_process` para usar `get_lead_by_id` ao invés de `refresh` pontual

### Fase 3 — Observabilidade

- [ ] Adicionar exception handler global para `MissingGreenlet`
- [ ] Criar teste de integração para fluxo webhook → persistência
- [ ] Adicionar log de checkpoint após cada `commit()` crítico

---

## 9. Referências Técnicas

- [SQLAlchemy Async ORM — Session Scoping](https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html)
- [FastAPI Background Tasks — Session Lifecycle](https://fastapi.tiangolo.com/tutorial/background-tasks/)
- [greenlet — Python coroutines scheduling](https://greenlet.readthedocs.io/)
- Comentários no próprio código: `process_whatsapp_message.py:62`, `ai_tools.py:443–448`
