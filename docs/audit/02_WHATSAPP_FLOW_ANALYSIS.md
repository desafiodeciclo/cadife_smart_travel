# 02 — WHATSAPP FLOW ANALYSIS
## Cadife Smart Travel — Análise Completa do Fluxo WhatsApp
**Data:** 2026-05-14 | **Versão:** 1.0.0

---

## 1. VISÃO GERAL DO FLUXO

```
Meta Cloud API
      │
      ▼
POST /webhook/whatsapp
      │
      ├─ [1] Validação HMAC-SHA256 (X-Hub-Signature-256)
      ├─ [2] Retorno HTTP 200 (< 5s SLA Meta)
      └─ [3] Enfileiramento assíncrono
              │
              ├─ KAFKA_ENABLED=true  → Kafka topic: whatsapp.messages.incoming
              └─ KAFKA_ENABLED=false → FastAPI BackgroundTask
                      │
                      ▼
              process_whatsapp_message.execute()
```

---

## 2. AUTENTICAÇÃO E SEGURANÇA DO WEBHOOK

### 2.1 Verificação do Challenge Token (GET)

```python
# webhook.py — GET /webhook/whatsapp
if mode == "subscribe" and token == settings.VERIFY_TOKEN:
    return int(challenge)  # Echo do hub.challenge para a Meta
```

**Status:** Implementado corretamente.

### 2.2 Validação HMAC (POST)

```python
# webhook.py — Depends(require_meta_signature)
# Usa META_APP_SECRET (segredo do App Meta), NÃO o WHATSAPP_TOKEN
signature = request.headers.get("X-Hub-Signature-256", "")
if not whatsapp_service.verify_signature(body, signature):
    raise HTTPException(status_code=403, detail="Invalid signature")
```

**Status:** Implementado corretamente. A distinção entre `META_APP_SECRET` e `WHATSAPP_TOKEN` está documentada.

**Risco identificado:** Se `META_APP_SECRET` não estiver configurado, o webhook retorna HTTP 500 (não 403). Isso expõe internamente que há uma configuração faltando.

### 2.3 Rate Limiting

```bash
RATE_LIMIT_WEBHOOK=100/minute  # slowapi
```

**Status:** Configurado. Rate limit adequado para volume esperado de mensagens.

---

## 3. PARSING DO PAYLOAD

### 3.1 Estrutura esperada (Meta Cloud API)

```json
{
  "entry": [{
    "changes": [{
      "value": {
        "contacts": [{"wa_id": "5511999999999"}],
        "messages": [{
          "id": "wamid.xxx",
          "from": "5511999999999",
          "type": "text",
          "text": {"body": "Olá, quero viajar para Lisboa"}
        }]
      }
    }]
  }]
}
```

### 3.2 Extração no use case

```python
# process_whatsapp_message.py
msg = whatsapp_service.extract_message_from_payload(payload)
phone = msg["phone"]        # wa_id do contato
text = msg.get("text")      # corpo da mensagem
msg_type = msg.get("type")  # text | audio | image | location
media_id = msg.get("media_id")  # para áudio e imagens
```

### 3.3 Tipos de mensagem suportados

| Tipo | Tratamento | Fallback |
|------|-----------|---------|
| `text` | Processado pela IA normalmente | — |
| `audio` / `voice` | Transcrito via Whisper → tratado como texto | Fallback "áudio não suportado" se transcrição falhar |
| `image` | **NÃO processado pela IA** | Fallback de mídia não suportada |
| `location` | **NÃO processado pela IA** | Fallback de mídia não suportada |
| `document` | **NÃO processado pela IA** | Fallback de mídia não suportada |

**Problema identificado:** A mensagem de fallback para áudio sem transcrição é `"Áudio não suportado nestes momentos, prefira o meio texto."` — mensagem pouco amigável e tecnicamente imprecisa. O sistema tenta transcrever mas usa essa mensagem genérica quando falha.

---

## 4. SLA E TEMPO DE RESPOSTA

### 4.1 SLA Meta (crítico)

- **Exigência:** HTTP 200 em ≤ 5 segundos
- **Implementação:** Retorno 200 antes de qualquer processamento IA
- **Configuração:** `WEBHOOK_TIMEOUT_SECONDS=4.5` (margem de segurança)

```python
# webhook.py — retorna antes de processar
background_tasks.add_task(process_whatsapp_message.execute, payload, db)
return {"status": "received"}  # ← retorno imediato
```

**Status:** SLA respeitado. BackgroundTasks garante retorno antes do processamento.

### 4.2 Tempo de processamento end-to-end

Fluxo completo estimado (ambiente de produção):

| Etapa | Tempo estimado |
|-------|---------------|
| Triagem (qwen free) | 2-8s |
| RAG search (ChromaDB) | 100-500ms |
| Orchestrator (gemini-2.0-flash) | 3-10s |
| Persist DB | 50-200ms |
| WhatsApp send | 200-800ms |
| **Total** | **5-20s do recebimento ao cliente** |

---

## 5. PROCESSAMENTO ASSÍNCRONO: BACKGROUNDTASK vs KAFKA

### 5.1 BackgroundTask (KAFKA_ENABLED=false)

```python
background_tasks.add_task(process_whatsapp_message.execute, payload, db)
```

**Vantagens:**
- Simples de operar
- Sem dependência externa

**Problemas:**
- **Session compartilhada**: a `db` (AsyncSession) passada para BackgroundTask pode expirar ou ser reutilizada — risco de race condition em ambientes com múltiplas requisições simultâneas
- **Sem durabilidade**: se a aplicação cair durante o processamento, a mensagem é perdida
- **Sem retry automático**: falhas de processamento não são reagendadas automaticamente
- **Loop de eventos compartilhado**: BackgroundTasks competem com requests HTTP

### 5.2 Kafka (KAFKA_ENABLED=true)

```python
# topic: whatsapp.messages.incoming
await kafka_produce(
    topic="whatsapp.messages.incoming",
    key=phone,
    value={"payload": payload, "received_at": ...}
)
```

**Vantagens:**
- Durabilidade de mensagens
- Consumer groups para paralelismo controlado
- At-least-once delivery
- DLQ para mensagens com falha (`whatsapp.messages.dlq`)

**Problema identificado:** Quando `KAFKA_ENABLED=true`, a **db session** NÃO é passada para o Kafka consumer. O consumer precisa criar sua própria sessão — mas essa lógica está no `whatsapp_consumer.py` e precisa ser verificada para evitar session leaks.

---

## 6. ENVIO DE MENSAGENS AO CLIENTE

### 6.1 WhatsApp Send com Retry

```python
# whatsapp_service.py — retry com exponential backoff
send_result = await whatsapp_service.send_message(phone, reply)
# Retries: 3x
# Backoff: exponencial
# Timeout por tentativa: ~10s
```

**Status:** Implementado com retry. Resultado (success, wamid, latency_ms, retries_used) é persistido na interação.

### 6.2 Mark as Read

```python
# Marca como lido ANTES de processar — blue ticks aparecem imediatamente
if message_id:
    await whatsapp_service.mark_as_read(phone, message_id)
```

**Status:** Boa UX — o cliente vê que a mensagem foi recebida enquanto a IA processa.

---

## 7. PROBLEMAS IDENTIFICADOS NO FLUXO WHATSAPP

### 7.1 CRÍTICO — Perda de sessão de banco em BackgroundTask

**Problema:** A `AsyncSession` é passada ao BackgroundTask por referência. Se houver rollback interno ou expiração, operações subsequentes falham silenciosamente.

**Evidência no código:**
```python
# process_whatsapp_message.py:209
await db.refresh(lead)  # necessário pois tool calls fazem commits intermediários
```

**Solução recomendada:** BackgroundTask deve criar sua própria sessão via `async_sessionmaker`.

### 7.2 MÉDIO — Mensagem de fallback para mídia não processada

**Problema:** `"Áudio não suportado nestes momentos, prefira o meio texto."` — mensagem que contradiz a experiência real (o sistema tenta transcrever).

**Solução:** Mensagem mais amigável: `"Recebi seu áudio! Vou analisar agora, um momento... 😊"` — e só usar fallback se a transcrição realmente falhar.

### 7.3 MÉDIO — Webhook não trata eventos de status

**Problema:** A Meta envia outros tipos de eventos além de mensagens (ex: delivery receipts, read receipts, reaction events). O código atual descarta silenciosamente eventos que não têm mensagem extraível.

**Evidência:**
```python
msg = whatsapp_service.extract_message_from_payload(payload)
if not msg:
    logger.debug("webhook_payload_ignored", reason="no_message_extracted")
    return  # sem distinção de tipo de evento
```

**Solução:** Verificar `entry[0].changes[0].value.statuses` para processar delivery receipts e atualizar o wamid no banco.

### 7.4 BAIXO — Phone extraction duplicada

**Problema:** O `phone` é extraído duas vezes: uma dentro do webhook (para Kafka key) e outra dentro do use case (via `extract_message_from_payload`). Risco de inconsistência se as lógicas diferirem.

**Evidência no webhook.py:**
```python
phone = payload.get("entry", [{}])[0].get("changes", [{}])[0]...  # extração manual
```

**Solução:** Centralizar a extração em `whatsapp_service.extract_message_from_payload`.

---

## 8. FLUXO DE CONCORRÊNCIA (MESMO CLIENTE, MÚLTIPLAS MENSAGENS)

### 8.1 Cenário problemático

Cliente envia 3 mensagens rapidamente (ex: "Quero ir", "Para Lisboa", "Em julho"):

```
Mensagem 1 → BackgroundTask-1 → busca lead → processa → salva
Mensagem 2 → BackgroundTask-2 → busca lead → processa → salva  (simultâneo!)
Mensagem 3 → BackgroundTask-3 → busca lead → processa → salva  (simultâneo!)
```

**Resultado:** Três processamentos concorrentes no mesmo lead, com risco de:
- Race condition no briefing (campo sobrescrito com valor de mensagem anterior)
- Respostas fora de ordem
- Histórico de conversa inconsistente (cada BackgroundTask carrega os últimos 20, mas ainda sem as mensagens dos outros)

### 8.2 Proteção atual

Não há locking explícito por `wa_id`. O `upsert_lead_with_resilience` usa SQL upsert mas não serializa o processamento de mensagens do mesmo lead.

### 8.3 Solução recomendada

Usar Redis distributed lock com TTL por `wa_id`:
```python
async with redis_lock(f"processing:{wa_id}", ttl=30):
    await process_whatsapp_message.execute(payload, db)
```

Ou usar Kafka com partitioning por `wa_id` (key=phone garante ordering dentro de uma partição, mas não entre workers do mesmo consumer group).

---

## 9. TABELA DE STATUS DE IMPLEMENTAÇÃO

| Funcionalidade | Status | Qualidade |
|---------------|--------|-----------|
| HMAC validation | ✅ Implementado | Alta |
| Challenge verification | ✅ Implementado | Alta |
| HTTP 200 imediato | ✅ Implementado | Alta |
| Parsing texto | ✅ Implementado | Alta |
| Parsing áudio (Whisper) | ✅ Implementado | Média |
| Parsing imagem | ⚠️ Fallback apenas | Baixa |
| Retry de envio | ✅ Implementado | Alta |
| Mark as read | ✅ Implementado | Alta |
| Kafka integration | ✅ Implementado | Alta |
| BackgroundTask durability | ❌ Sem durabilidade | Baixa |
| Concurrent message locking | ❌ Não implementado | Crítico |
| Delivery receipt handling | ❌ Não implementado | Baixa |
