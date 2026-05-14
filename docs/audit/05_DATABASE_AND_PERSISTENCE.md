# 05 — DATABASE AND PERSISTENCE
## Cadife Smart Travel — Auditoria de Banco de Dados e Persistência
**Data:** 2026-05-14 | **Versão:** 1.0.0

---

## 1. VISÃO GERAL DO BANCO DE DADOS

- **Engine:** PostgreSQL 16 (asyncpg driver)
- **ORM:** SQLAlchemy AsyncSession
- **Migrations:** Alembic (30+ versões)
- **PII:** Fernet encryption (AES-128) em `nome` e `telefone`
- **Lookup:** `telefone_hash` (HMAC-SHA256) para busca segura

---

## 2. SCHEMA PRINCIPAL

### 2.1 Tabela `leads` (Central)

```sql
leads:
  id              UUID (PK)
  telefone        BYTEA (Fernet encrypted)
  telefone_hash   VARCHAR (HMAC-SHA256, indexed)
  nome            BYTEA (Fernet encrypted, nullable)
  origem          ENUM (whatsapp, manual, cms, api)
  status          ENUM (novo, em_atendimento, qualificado, agendado, proposta, fechado, perdido)
  score           ENUM (frio, morno, quente)
  aya_ativo       BOOLEAN (AYA ativada para este lead)
  consultor_id    UUID FK→users (nullable)
  is_archived     BOOLEAN (soft delete)
  deletado_em     TIMESTAMP
  criado_em       TIMESTAMP
  atualizado_em   TIMESTAMP
```

### 2.2 Tabela `briefing` (1:1 com lead)

```sql
briefing:
  id              UUID (PK)
  lead_id         UUID FK→leads (UNIQUE)
  destino         VARCHAR
  data_ida        DATE
  data_volta      DATE
  qtd_pessoas     INTEGER
  perfil          ENUM (casal, familia, solo, grupo, amigos)
  orcamento       ENUM (baixo, medio, alto, premium)
  tem_passaporte  BOOLEAN
  preferencias    TEXT (JSON livre)
  completude_pct  INTEGER (calculado, 0-100)
  atualizado_em   TIMESTAMP
```

**Observação:** O campo `ocasiao` (lua de mel, férias, etc.) **NÃO EXISTE** no schema atual — confirmando a raiz do problema de inferência indevida.

### 2.3 Tabela `interacao` (Histórico de mensagens)

```sql
interacao:
  id                  UUID (PK)
  lead_id             UUID FK→leads
  conteudo            TEXT (mensagem completa)
  tipo_mensagem       ENUM (texto, audio, image, location)
  sender              ENUM (human, aia)
  timestamp           TIMESTAMP
  whatsapp_message_id VARCHAR (wamid da Meta)
```

### 2.4 Tabela `agendamento`

```sql
agendamento:
  id              UUID (PK)
  lead_id         UUID FK→leads
  data            DATE
  hora            TIME
  duracao_minutos INTEGER (default 60)
  meet_link       VARCHAR (Google Meet URL, nullable)
  status          ENUM (pendente, confirmado, cancelado, realizado)
  criado_em       TIMESTAMP
```

---

## 3. PADRÕES DE ACESSO

### 3.1 Upsert de Lead (busca por telefone_hash)

```python
# lead_service.upsert_lead_with_resilience
SELECT * FROM leads WHERE telefone_hash = $1 AND is_archived = false
→ Se existe: retorna lead existente
→ Se não: INSERT com novo lead
```

**Avaliação:** Correto. A busca por `telefone_hash` (não por telefone criptografado) é a abordagem adequada para PII encryption + lookup.

### 3.2 Carregamento do Briefing (Pré-orchestrador)

```python
_briefing_pre = await BriefingRepository(db).get_by_lead(lead_id)
```

**Avaliação:** Eficiente — 1 query por requisição antes do LangGraph. Elimina tool call redundante quando briefing já está completo.

### 3.3 Histórico de Interações (Memória)

```python
interacoes_list = await lead_service.get_recent_interacoes(db, lead_id, limit=20)
```

**Avaliação:** Adequado para MVP. Em escala, leads com centenas de interações precisariam de paginação mais eficiente.

---

## 4. PROBLEMAS IDENTIFICADOS

### 4.1 CRÍTICO — Campo `ocasiao` ausente

**Problema:** O briefing não tem campo para registrar a ocasião da viagem (lua de mel, férias, aniversário, etc.). Isso força a IA a:
1. Inferir a ocasião (comportamento incorreto)
2. Colocar no campo `observacoes` (não estruturado, difícil de usar)

**Solução:**
```sql
ALTER TABLE briefing ADD COLUMN ocasiao VARCHAR;
-- ENUM sugerido: ferias, lua_de_mel, aniversario, familia, negocios, intercambio, outro
```

E migration Alembic correspondente.

### 4.2 MÉDIO — N+1 Queries Potencial

Em `process_whatsapp_message.execute()`, há múltiplos acessos ao DB:
1. `upsert_lead_with_resilience` → 1-2 queries
2. `update_lead_status` → 1 query
3. `get_recent_interacoes` → 1 query
4. `BriefingRepository.get_by_lead` → 1 query
5. Dentro do LangGraph: `_dispatch_tool` → N queries (persist_lead_data, check_availability)
6. Pós-orchestrador: `BriefingRepository.get_by_lead_id` → 1 query duplicada
7. `save_interacao` → 1 query
8. `update_interacao_send_result` → 1 query

**Total:** 8+ queries por mensagem, algumas com alto risco de N+1 se houver relacionamentos não carregados.

**Solução:** Usar `joinedload` ou `selectinload` para carregar relacionamentos necessários em uma única query.

### 4.3 MÉDIO — Refresh do Lead após Tool Call

```python
# process_whatsapp_message.py:210
await db.refresh(lead)
```

Após tool calls que fazem `commit` interno (persist_lead_data), o SQLAlchemy expira todos os atributos do ORM model. O `await db.refresh(lead)` recarga o estado, mas:
1. Custo extra: query adicional ao DB
2. Risco: se o commit interno falhou parcialmente, o refresh pode trazer estado inconsistente

**Solução:** Ao invés de passar o ORM model `lead` por toda a função, trabalhar com o `lead_id` (UUID) e reler quando necessário.

### 4.4 BAIXO — Indexação do Briefing

O campo `completude_pct` no briefing não tem índice. Em escala, queries como `SELECT * FROM briefing WHERE completude_pct >= 60` serão lentas.

**Solução:**
```sql
CREATE INDEX idx_briefing_completude ON briefing(completude_pct);
CREATE INDEX idx_briefing_lead_id ON briefing(lead_id);
```

### 4.5 BAIXO — Dead Letter Queue (DLQ) no DB

```sql
dead_letter_queue:
  id              UUID
  mensagem_original JSON
  erro            TEXT
  criado_em       TIMESTAMP
```

**Problema:** A DLQ no banco não tem campo `tentativas` nem `proximo_retry`. Mensagens falhas entram na DLQ mas não há mecanismo de retry baseado nesta tabela.

---

## 5. INTEGRIDADE DOS DADOS

### 5.1 Foreign Keys

O schema usa FKs explícitas (lead_id FK→leads, etc.) com comportamento `SET NULL` ou `CASCADE` dependendo do relacionamento. Isso garante integridade referencial.

### 5.2 Soft Delete

```python
# Correto — leads nunca são deletados fisicamente
lead.is_archived = True
lead.deletado_em = datetime.now(timezone.utc)
await db.commit()
```

**Avaliação:** Implementado corretamente. Importante para rastreabilidade histórica.

### 5.3 PII Encryption

```python
# lead.py — campos criptografados com Fernet
telefone = Column(LargeBinary)  # encrypted bytes
telefone_hash = Column(String)  # HMAC-SHA256 para lookup
nome = Column(LargeBinary)      # encrypted bytes
```

**Avaliação:** Abordagem correta para LGPD compliance. A separação entre `telefone` (encrypted) e `telefone_hash` (para busca) é a prática recomendada.

---

## 6. MIGRATIONS ALEMBIC — STATUS

### 6.1 Estado Atual

- **30+ migrations** com histórico limpo
- **Merge stubs** presentes (indica desenvolvimento em branches paralelas — normal)
- **Rollback**: cada migration deve ter `downgrade()` implementado

### 6.2 Migrations Necessárias (do diagnóstico)

| Migration | Prioridade | Descrição |
|-----------|-----------|-----------|
| `add_ocasiao_to_briefing` | Alta | Novo campo ENUM para ocasião da viagem |
| `add_retry_fields_to_dlq` | Média | Campos `tentativas` e `proximo_retry` na DLQ |
| `add_index_completude_pct` | Baixa | Índice em `briefing.completude_pct` |

---

## 7. PERSISTÊNCIA DO HISTÓRICO DE CONVERSA

### 7.1 Tabela interacao como Log Completo

Cada mensagem (cliente + AYA) é persistida como um registro `interacao`. Isso garante:
- Auditoria completa de todas as conversas
- Replay de histórico após restart
- Base para futuras análises de qualidade

### 7.2 Fluxo de Persistência

```python
# save_interacao — salva par de mensagens (cliente + IA)
interacao = await lead_service.save_interacao(
    db,
    lead_id,
    msg_cliente=text,       # mensagem do cliente
    msg_ia=reply,           # resposta da AYA
    tipo=tipo,              # tipo de mídia
)

# update_interacao_send_result — registra resultado do envio
await lead_service.update_interacao_send_result(db, interacao, send_result)
```

**Avaliação:** Correto. O resultado do envio (success, wamid, latency_ms) é registrado na interação, permitindo auditoria completa.

### 7.3 Problema: Interação salva mesmo quando mensagem não foi enviada

Se `whatsapp_service.send_message` falha completamente (após retries), a interação ainda é salva. Isso é correto para auditoria, mas o consultor que visualiza o histórico no CRM pode ver respostas da AYA que o cliente nunca recebeu.

**Solução:** Adicionar flag `enviado: bool` na interação, com `False` quando todos os retries falharam.

---

## 8. TABELA DE SAÚDE DO BANCO DE DADOS

| Aspecto | Status | Observação |
|---------|--------|-----------|
| Schema bem definido | ✅ | Entidades claras, relacionamentos corretos |
| PII encryption | ✅ | Fernet + HMAC hash para lookup |
| Soft delete | ✅ | is_archived + deletado_em |
| Migrations gerenciadas | ✅ | Alembic com 30+ versões |
| Campo ocasiao | ❌ | Ausente — causa raiz do viés de inferência |
| Índice completude_pct | ⚠️ | Ausente — impacto em escala |
| DLQ com retry fields | ❌ | Ausente — DLQ sem mecanismo de retry |
| N+1 queries | ⚠️ | Presente em process_whatsapp_message |
| Flag enviado em interacao | ❌ | Ausente — dificulta auditoria de falhas de envio |
