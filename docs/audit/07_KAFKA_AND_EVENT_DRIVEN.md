# 07 — KAFKA AND EVENT DRIVEN
## Cadife Smart Travel — Análise da Arquitetura Event-Driven e Kafka
**Data:** 2026-05-14 | **Versão:** 1.0.0

---

## 1. STATUS DE IMPLEMENTAÇÃO DO KAFKA

**Kafka ESTÁ IMPLEMENTADO** no projeto. Diferente do que poderia se supor em um MVP, a arquitetura event-driven com Kafka está integrada, com producer, consumers, topics e DLQ definidos.

```bash
# docker-compose.yml
kafka:    # Kafka broker (port 9092)
zookeeper: # Kafka coordinator

# settings.py
KAFKA_ENABLED=false  # dev/staging
KAFKA_ENABLED=true   # prod
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
```

---

## 2. TOPICS KAFKA DEFINIDOS

| Topic | Producer | Consumer | Uso |
|-------|---------|---------|-----|
| `whatsapp.messages.incoming` | webhook.py | whatsapp_consumer.py | Mensagens recebidas |
| `whatsapp.messages.dlq` | kafka_producer.py | (manual review) | Mensagens com falha |
| `leads.qualified` | process_whatsapp_message.py | (CRM notifications) | Lead ≥ 60% completude |
| `leads.orchestrator.errors` | _node_orchestrator | (alerting) | Erros do pipeline IA |
| `agendamentos.confirmados` | (agendamento flow) | agendamento_consumer.py | Agendamentos criados |

---

## 3. ANÁLISE DO KAFKA PRODUCER

### 3.1 Implementação

```python
# services/kafka_producer.py
# aiokafka AsyncProducer
# Serialização JSON
# No-op quando KAFKA_ENABLED=false
# key=wa_id/lead_id (garante ordering por entidade)
```

### 3.2 Modo Dual (Kafka vs BackgroundTasks)

```python
# webhook.py
if settings.KAFKA_ENABLED:
    await kafka_produce(
        topic="whatsapp.messages.incoming",
        key=phone,
        value={"payload": payload, "received_at": ...},
    )
else:
    background_tasks.add_task(process_whatsapp_message.execute, payload, db)
```

**Avaliação positiva:** O design dual (Kafka em prod, BackgroundTasks em dev) é pragmático e bem implementado. O flag `KAFKA_ENABLED` permite desenvolvimento sem dependência de Kafka.

---

## 4. ANÁLISE DOS CONSUMERS

### 4.1 whatsapp_consumer.py

```python
# application/workers/whatsapp_consumer.py
# Consumer do topic: whatsapp.messages.incoming
# At-least-once delivery
# Cria sua própria AsyncSession (não reutiliza a do webhook)
```

**Problema potencial:** O consumer precisa criar uma `AsyncSession` do PostgreSQL para cada mensagem processada. Se o consumer processar mensagens em alto volume, o pool de conexões pode ser esgotado.

**Solução:** Usar `sessionmaker` com pool de conexões compartilhado e processar mensagens em batch quando possível.

### 4.2 agendamento_consumer.py

```python
# application/workers/agendamento_consumer.py
# Consumer do topic: agendamentos.confirmados
# Cria evento Google Calendar + Meet
# Envia confirmação via WhatsApp
```

**Avaliação:** Separação de responsabilidades correta — o agendamento confirmado é processado de forma assíncrona, desacoplando o fluxo principal da integração Google.

---

## 5. DEAD LETTER QUEUE (DLQ)

### 5.1 DLQ no Kafka

```python
# Após 3 retries falhos:
await kafka_produce(
    topic="whatsapp.messages.dlq",
    key=wa_id,
    value={"original_payload": ..., "error": ..., "retry_count": 3}
)
```

### 5.2 DLQ no PostgreSQL

```sql
dead_letter_queue:
  id              UUID
  mensagem_original JSON
  erro            TEXT
  criado_em       TIMESTAMP
```

**Problema:** A DLQ no banco não tem:
- Campo `tentativas` (quantas vezes foi retentado)
- Campo `proximo_retry` (quando deve ser retentado)
- Campo `resolvido` (se foi resolvido manualmente)
- Campo `resolvido_por` (quem resolveu)

**Solução:**
```sql
ALTER TABLE dead_letter_queue ADD COLUMN tentativas INTEGER DEFAULT 0;
ALTER TABLE dead_letter_queue ADD COLUMN proximo_retry TIMESTAMP;
ALTER TABLE dead_letter_queue ADD COLUMN resolvido BOOLEAN DEFAULT false;
ALTER TABLE dead_letter_queue ADD COLUMN resolvido_por UUID;
ALTER TABLE dead_letter_queue ADD COLUMN resolvido_em TIMESTAMP;
```

---

## 6. PADRÕES DE IDEMPOTÊNCIA

### 6.1 Estado Atual

O `whatsapp_message_id` (wamid) é armazenado na tabela `interacao`. Isso permite detectar mensagens duplicadas:

```python
# Verificar se wamid já foi processado
SELECT 1 FROM interacao WHERE whatsapp_message_id = $1
```

**Problema:** Esta verificação NÃO está sendo feita explicitamente antes do processamento. A Meta pode re-enviar webhooks (retry automático após timeout), causando processamento duplicado.

**Solução:**
```python
# Verificação de idempotência no início do use case
existing = await interacao_repo.find_by_wamid(message_id)
if existing:
    logger.info("duplicate_webhook_ignored", wamid=message_id)
    return
```

### 6.2 Kafka Consumer Idempotência

Kafka com at-least-once delivery pode entregar a mesma mensagem múltiplas vezes em caso de falha de commit do offset. O consumer precisa verificar idempotência antes de processar.

---

## 7. ORDERING E PARALELISMO

### 7.1 Garantia de Ordenação

O producer usa `key=phone` para o topic `whatsapp.messages.incoming`. No Kafka, mensagens com a mesma key são garantidamente enviadas para a mesma partição — e dentro de uma partição, a ordem é preservada.

**Implicação:** Mensagens do mesmo cliente (`phone`) são processadas em ordem, mas apenas se houver **um consumer por partição**. Com consumer group de múltiplos workers, cada worker processa uma partição diferente — clientes diferentes podem ser processados em paralelo, mas o mesmo cliente é sempre no mesmo worker (graças ao partitioning por key).

**Avaliação positiva:** O uso de `key=phone` é a escolha correta para garantir ordering por cliente sem blocking global.

### 7.2 Throughput Esperado

```
Partições: 3 (padrão Kafka)
Consumers: até 3 (1 por partição)
Throughput: ~30 msg/s por partição = ~90 msg/s total
```

Para escala futura, aumentar o número de partições (e consumers correspondentes) é a estratégia correta.

---

## 8. MONITORAMENTO DO KAFKA

### 8.1 Métricas Ausentes

O sistema não tem monitoramento explícito do Kafka:
- Consumer lag (mensagens acumuladas sem processar)
- Erro rate por topic
- Throughput por partição
- DLQ growth rate

**Ferramentas recomendadas:**
- Kafka UI (open source — Provectus)
- Confluent Control Center
- Prometheus + Kafka Exporter + Grafana

### 8.2 Alerta de Consumer Lag

Se o consumer lag crescer acima de um threshold (ex: 1000 mensagens acumuladas), há um problema no consumer que precisa de atenção. Sem monitoramento, esse problema pode passar despercebido por horas.

---

## 9. ARQUITETURA EVENT-DRIVEN COMPLETA (RECOMENDADA)

```
WhatsApp Webhook
      │
      ▼
FastAPI (HTTP 200 imediato)
      │
      ▼
Kafka: whatsapp.messages.incoming
      │
      ▼ (partitioned by phone)
AI Processing Workers (whatsapp_consumer)
      │
      ├─ success → salva interação
      │               │
      │               ├─ lead qualificado → leads.qualified
      │               └─ agendamento      → agendamentos.confirmados
      │
      └─ failure → whatsapp.messages.dlq
                              │
                              ▼
                    DLQ Monitor + Retry Job

leads.qualified ─────────────────────────────────────────────┐
                                                              ▼
agendamentos.confirmados → agendamento_consumer.py → Google Calendar + Meet
                                                           │
                                                           ▼
                                                  WhatsApp: "Agendamento confirmado!
                                                             [Meet link]"
```

---

## 10. TABELA DE STATUS DO KAFKA

| Funcionalidade | Status | Qualidade |
|---------------|--------|-----------|
| Producer implementado | ✅ | Alta |
| Topics definidos | ✅ | Boa |
| Consumer WhatsApp | ✅ | Média |
| Consumer Agendamento | ✅ | Média |
| DLQ básica | ✅ | Baixa (sem retry fields) |
| Idempotência de mensagens | ❌ | Ausente — duplicatas possíveis |
| Consumer lag monitoring | ❌ | Ausente |
| Retry automático da DLQ | ❌ | Ausente |
| Ordenação por wa_id | ✅ | Correta (key=phone) |
| Mode dual (Kafka/BackgroundTask) | ✅ | Excelente |
