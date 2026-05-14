# 08 — LEAD AND CRM FLOW
## Cadife Smart Travel — Análise do Fluxo de Leads e CRM
**Data:** 2026-05-14 | **Versão:** 1.0.0

---

## 1. CICLO DE VIDA DO LEAD

```
NOVO → EM_ATENDIMENTO → QUALIFICADO → AGENDADO → PROPOSTA → FECHADO
                                    ↘ PROPOSTA ↗
                      (qualquer estado) → PERDIDO (30 dias sem resposta)
```

### 1.1 Gatilhos de Transição

| Transição | Gatilho | Quem executa |
|-----------|---------|--------------|
| `NOVO → EM_ATENDIMENTO` | Primeira mensagem WhatsApp processada | `process_whatsapp_message.execute` |
| `EM_ATENDIMENTO → QUALIFICADO` | Briefing ≥ 60% de completude | `lead_service` pós-persist |
| `QUALIFICADO → AGENDADO` | Cliente aceita slot de curadoria | `confirm_scheduling` tool |
| `AGENDADO → PROPOSTA` | Consultor registra proposta pós-curadoria | Endpoint manual CRM |
| `PROPOSTA → FECHADO` | Cliente aprova e realiza pagamento | Endpoint manual CRM |
| `QUALQUER → PERDIDO` | 30 dias sem atividade | `lead_expiration_job` (diário 02h UTC) |

---

## 2. ANÁLISE DO ONBOARDING DE LEAD

### 2.1 Criação Automática (WhatsApp)

```python
# process_whatsapp_message.py
lead_data = {
    "telefone": phone,
    "nome": msg.get("name"),   # Nome do contato WhatsApp (se disponível)
    "status": LeadStatus.novo,
}
lead: Lead = await lead_service.upsert_lead_with_resilience(db, lead_data)
```

**Avaliação:** O upsert por `telefone_hash` é robusto. `upsert_lead_with_resilience` sugere que há tratamento de erros de banco (retry em caso de timeout/lock).

**Problema:** O `nome` vem do perfil WhatsApp do contato — pode ser um nome de display informal. Em alguns casos, o cliente pode ter um nome no WhatsApp diferente do nome real que fornece na conversa.

**Solução:** Quando o cliente fornecer o nome explicitamente durante a conversa, `persist_lead_data` deve atualizar o `nome` no lead (não apenas no briefing).

### 2.2 Identificador Único

```python
# Identificação por telefone_hash (HMAC-SHA256)
lead.telefone_hash = hmac.new(HASH_KEY, phone.encode(), sha256).hexdigest()
```

**Avaliação positiva:** O `telefone_hash` como identificador único é a abordagem correta para PII compliance. Evita armazenar telefone em claro em índices.

### 2.3 Lead Criado Manualmente (CRM)

Leads podem ser criados manualmente pelo consultor via `POST /leads`. O fluxo manual deve:
1. Criar lead com status `novo`
2. Aguardar o cliente iniciar contato via WhatsApp (ou consultor entrar em contato)

**Problema potencial:** Um lead criado manualmente com telefone, quando o cliente enviar mensagem WhatsApp, será encontrado pelo `upsert` (mesmo `telefone_hash`) e corretamente associado. Mas o status pode ser sobrescrito incorretamente.

---

## 3. ANÁLISE DO SCORING DE LEADS

### 3.1 Fórmula de Score

```
SCORE = (completude_briefing × 0.5) + (nível_interesse × 0.3) + (urgência × 0.2)
```

### 3.2 Completude do Briefing (50% do score)

Campos que compõem a completude:

| Campo | Peso | Fonte |
|-------|------|-------|
| destino | Alto | IA via persist_lead_data |
| data_ida | Alto | IA via persist_lead_data |
| qtd_pessoas | Médio | IA via persist_lead_data |
| perfil | Médio | IA via persist_lead_data |
| orcamento | Médio | IA via persist_lead_data |
| tem_passaporte | Baixo | IA via persist_lead_data |

**Completude ≥ 60% → status qualificado**

**Problema:** O campo `ocasiao` (lua de mel, férias, etc.) não compõe a completude. Quando adicionado, o threshold de 60% pode precisar de recalibração.

### 3.3 Nível de Interesse (30% do score)

```python
# lead_scoring_service.py
# Análise de sentimentos + comportamento:
# Neutro = 0 | Morno = 5 | Quente = 10
# Perguntas detalhadas = +25
```

**Problema:** A análise de sentimentos/interesse não é documentada em código visível. Precisa verificar se `lead_scoring_service.py` implementa isso explicitamente ou se é estimado pelo TriagemAgent.

### 3.4 Urgência (20% do score)

```python
# Se mencionou datas próximas: +10
# Se timeframe urgente: +5
```

**Avaliação:** Scoring simples mas funcional para MVP. Em produção, análise mais sofisticada (ex: ML de propensão) pode melhorar a qualidade dos leads qualificados.

---

## 4. ANÁLISE DO FLUXO DE QUALIFICAÇÃO

### 4.1 Transição para QUALIFICADO

```python
# process_whatsapp_message.py
if briefing.completude_pct >= 60 and lead.status == LeadStatus.qualificado:
    await _enqueue_qualified_notification(db, lead, briefing)
    await kafka_produce(topic="leads.qualified", ...)
```

**Problema potencial:** A condição `lead.status == LeadStatus.qualificado` sugere que a transição de status já ocorreu antes desta verificação. Mas onde exatamente ocorre a transição `EM_ATENDIMENTO → QUALIFICADO`? Precisa verificar o `lead_state_machine.py`.

**Risco:** Se o score/completude for calculado mas a transição de status não for executada atomicamente, o lead pode ficar em `EM_ATENDIMENTO` com completude ≥ 60%.

### 4.2 Oferta de Curadoria

```python
if curadoria_service.deve_oferecer_curadoria(status_antes, lead.status, briefing.completude_pct):
    if not await curadoria_service.lead_tem_agendamento_ativo(db, lead.id):
        # Verifica se o orchestrador JÁ mencionou agendamento na resposta
        if not _reply_has_scheduling:
            slots = await curadoria_service.get_proximos_slots_disponiveis(db, quantidade=3)
            reply = curadoria_service.gerar_mensagem_oferta_curadoria(slots, ...)
```

**Avaliação positiva:** A lógica é sofisticada:
1. Verifica se a transição de status acabou de ocorrer (`status_antes` != `lead.status`)
2. Verifica se já existe agendamento ativo (evita dupla oferta)
3. Verifica se o orchestrador já incluiu scheduling na resposta (evita sobreposição de mensagens)

**Problema:** A regex de detecção de scheduling na resposta:
```python
r"meet\.google\.com|curadoria|agend[ao]|\d{1,2}h\d{2}|\d{2}/\d{2}/\d{4}"
```
Esta regex pode ter falsos positivos (ex: `"agendado para você"` no contexto errado) e falsos negativos (ofertas de agendamento em outras formas).

---

## 5. ANÁLISE DO AGENDAMENTO DE CURADORIA

### 5.1 Fluxo Ideal

```
1. AYA: "Perfeito! Quer agendar sua curadoria?"
2. Cliente: "Sim!"
3. AYA: check_availability → 3 slots disponíveis
4. AYA: "Tenho estes horários: [slot1], [slot2], [slot3]"
5. Cliente: "Quero o [slot1]"
6. AYA: confirm_scheduling(wa_id, data, hora)
7. Sistema:
   a. Cria agendamento no PostgreSQL
   b. Cria evento Google Calendar
   c. Gera Meet link
   d. Envia link via WhatsApp
8. AYA: "Agendado! [Meet link]"
```

### 5.2 Slots Disponíveis

```python
# curadoria_service.get_proximos_slots_disponiveis
# Horário de atendimento: Segunda-Sexta, 09h-16h
# Máximo 6 curadorias/dia, intervalo mínimo de 1h
# Busca slots livres nos próximos N dias
```

**Problema potencial:** Como os slots são calculados? Se baseados em eventos existentes no Google Calendar, há dependência da credencial Google. Se o GOOGLE_SERVICE_ACCOUNT_PATH não estiver configurado, os slots disponíveis podem ser calculados incorretamente (sem considerar eventos existentes).

### 5.3 Confirmação do Agendamento

```python
# ai_tools.execute_tool("confirm_scheduling", ...)
# → Cria agendamento no PostgreSQL
# → Chama criar_evento_curadoria(Google Calendar)
# → Publica em agendamentos.confirmados
# → Retorna meet_link (ou None se Google indisponível)
```

**Avaliação:** O fluxo é bem estruturado. A degradação graciosa (agendamento sem Meet link se Google não disponível) é o comportamento correto.

**Fallback documentado:**
```
"Perfeito 😊
No momento tivemos uma pequena instabilidade para concluir o agendamento automático.
Mas fique tranquilo(a), em breve um consultor da Cadife Tour entrará em contato para finalizar sua curadoria."
```

---

## 6. ANÁLISE DO CRM PARA CONSULTORES

### 6.1 Dashboard de Leads

```
GET /leads → lista leads com paginação, filtros por status/score
GET /leads/{id} → detalhes completos com briefing e histórico
GET /leads/{id}/history → histórico de score
```

### 6.2 Atribuição de Consultor

```
POST /leads/{id}/assign → atribui lead a consultor específico
```

**Funcionalidade importante:** Leads podem ser atribuídos a consultores específicos. O consultor atribuído recebe notificações FCM prioritárias para esse lead.

### 6.3 Notificação FCM

```python
# _enqueue_qualified_notification
# Envia para TODOS os consultores com fcm_token registrado
# Não envia apenas para o consultor atribuído
```

**Problema:** Se o lead foi atribuído a um consultor específico (`consultor_id` no lead), a notificação deveria ir apenas para esse consultor — não para todos. O comportamento atual envia para todos os consultores, causando "confusão" sobre quem deve atender.

**Solução:**
```python
if lead.consultor_id:
    # Notificar apenas o consultor atribuído
    tokens = [await get_fcm_token(lead.consultor_id)]
else:
    # Lead sem consultor → notificar todos
    tokens = [c.fcm_token for c in consultores]
```

---

## 7. TABELA DE STATUS DO CRM

| Funcionalidade | Status | Qualidade |
|---------------|--------|-----------|
| Criação automática via WhatsApp | ✅ | Alta |
| Upsert por telefone_hash | ✅ | Alta |
| PII encryption | ✅ | Alta |
| Scoring automático | ✅ | Média |
| Transição de status | ✅ | Média |
| Soft delete | ✅ | Alta |
| Atribuição de consultor | ✅ | Média |
| Notificação FCM seletiva | ❌ | Ausente |
| Campo ocasiao no briefing | ❌ | Ausente |
| Expiração automática (30d) | ✅ | Alta |
| Retry de qualificação perdida | ⚠️ | Verificar state machine |
