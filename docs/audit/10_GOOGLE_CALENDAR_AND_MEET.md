# 10 — GOOGLE CALENDAR AND MEET
## Cadife Smart Travel — Auditoria da Integração Google Calendar e Meet
**Data:** 2026-05-14 | **Versão:** 1.0.0

---

## 1. VISÃO GERAL DA INTEGRAÇÃO

### 1.1 Objetivo Funcional

Ao final do briefing (completude ≥ 60%), a AYA deve:

1. Verificar disponibilidade no Google Calendar
2. Sugerir horários disponíveis
3. O cliente escolhe um horário
4. Criar evento no Google Calendar
5. Gerar link Google Meet automaticamente
6. Enviar link via WhatsApp
7. Finalizar o atendimento do briefing

### 1.2 Implementação Atual

```python
# google_calendar_service.py
async def criar_evento_curadoria(
    lead_nome: Optional[str],
    data: date,
    hora: time,
    duracao_minutos: int = 60,
) -> Optional[str]:  # Retorna hangoutLink ou None
```

---

## 2. AUTENTICAÇÃO — SERVICE ACCOUNT

### 2.1 Implementação Atual

```python
# google_calendar_service.py
def _build_service():
    from google.oauth2 import service_account
    from googleapiclient.discovery import build

    creds = service_account.Credentials.from_service_account_file(
        path, scopes=_CALENDAR_SCOPES
    )
    # Domain-Wide Delegation (opcional)
    if settings.GOOGLE_CALENDAR_DELEGATE_EMAIL:
        creds = creds.with_subject(settings.GOOGLE_CALENDAR_DELEGATE_EMAIL)

    return build("calendar", "v3", credentials=creds, cache_discovery=False)
```

### 2.2 Variáveis de Ambiente Necessárias

```bash
GOOGLE_SERVICE_ACCOUNT_PATH=./credentials/google-service-account.json
GOOGLE_CALENDAR_ID=primary  # ou ID específico do calendário
GOOGLE_CALENDAR_DELEGATE_EMAIL=  # opcional, para delegation
```

### 2.3 Scopes Necessários

```python
_CALENDAR_SCOPES = ["https://www.googleapis.com/auth/calendar"]
```

**Scope `calendar` (leitura e escrita)** é necessário para:
- `events().list()` — verificar disponibilidade
- `events().insert()` — criar eventos com Meet

**Avaliação do Scope:** O scope `https://www.googleapis.com/auth/calendar` dá acesso completo ao calendário. Para produção, considerar o scope mais restritivo:
```python
# Alternativa mais segura:
"https://www.googleapis.com/auth/calendar.events"  # Apenas eventos
```

---

## 3. CRIAÇÃO DE EVENTO COM GOOGLE MEET

### 3.1 Implementação

```python
event_body = {
    "summary": f"Curadoria Cadife Tour — {nome_display}",
    "description": f"Sessão de curadoria personalizada com consultor Cadife Tour.\nCliente: {nome_display}",
    "start": {"dateTime": inicio.isoformat(), "timeZone": "America/Sao_Paulo"},
    "end": {"dateTime": fim.isoformat(), "timeZone": "America/Sao_Paulo"},
    "conferenceData": {
        "createRequest": {
            "requestId": str(uuid.uuid4()),
            "conferenceSolutionKey": {"type": "hangoutsMeet"},
        }
    },
    "reminders": {
        "useDefault": False,
        "overrides": [
            {"method": "email", "minutes": 60},
            {"method": "popup", "minutes": 15},
        ],
    },
}

created = service.events().insert(
    calendarId=settings.GOOGLE_CALENDAR_ID,
    body=event_body,
    conferenceDataVersion=1,  # OBRIGATÓRIO para Meet
    sendUpdates="none",
).execute()

meet_link = created.get("hangoutLink")
```

**Avaliação:** Implementação correta. O parâmetro `conferenceDataVersion=1` é obrigatório para que o Google gere o link Meet. `sendUpdates="none"` evita emails automáticos de convite (a Cadife controla a comunicação).

### 3.2 Timezone

```python
tz_offset = timezone(timedelta(hours=-3))  # BRT (America/Sao_Paulo)
```

**Avaliação positiva:** Timezone hardcoded como BRT (-3h). Para um sistema de agência turística brasileira, isso é correto. No horário de verão (BRT = -2h), há risco de divergência.

**Melhoria:** Usar `pytz` ou `zoneinfo` para timezone dinâmico:
```python
from zoneinfo import ZoneInfo
tz = ZoneInfo("America/Sao_Paulo")
inicio = datetime.combine(data, hora, tzinfo=tz)
```

---

## 4. VERIFICAÇÃO DE DISPONIBILIDADE

### 4.1 Problema Crítico — Sem Leitura Real do Calendário

O `curadoria_service.get_proximos_slots_disponiveis()` precisa verificar eventos existentes no Google Calendar para calcular slots livres.

**Questão:** O serviço atual consulta o Google Calendar para verificar conflitos, ou apenas calcula slots com base nas regras de negócio (9h-16h, máx 6/dia)?

Se a verificação é apenas baseada em regras (sem consultar o Calendar):
- **Risco:** Dois clientes podem ser agendados no mesmo horário se o consultor tem outros compromissos no Calendar
- **Risco:** Feriados e férias do consultor não são respeitados

**Verificação necessária:** Auditar `curadoria_service.get_proximos_slots_disponiveis()` para confirmar se usa `service.freebusy().query()` ou `service.events().list()`.

### 4.2 API Google para Free/Busy Query

```python
# Consultar disponibilidade real
body = {
    "timeMin": inicio.isoformat(),
    "timeMax": fim.isoformat(),
    "items": [{"id": settings.GOOGLE_CALENDAR_ID}]
}
result = service.freebusy().query(body=body).execute()
busy_slots = result["calendars"][settings.GOOGLE_CALENDAR_ID]["busy"]
```

Se isso não estiver implementado, é um gap crítico que pode causar double-booking.

---

## 5. DEGRADAÇÃO GRACIOSA

### 5.1 Implementação Atual

```python
def _build_service():
    if not Path(path).exists():
        logger.warning("google_service_account_not_found", ...)
        return None  # Retorna None graciosamente
    ...

async def criar_evento_curadoria(...) -> Optional[str]:
    # Se _build_service() retorna None, retorna None sem exceção
```

**Avaliação positiva:** O sistema funciona sem o Google Calendar configurado. O agendamento é criado no banco sem `meet_link` (NULL). O consultor pode compartilhar o Meet link manualmente.

### 5.2 Fallback para o Cliente

Quando o Google Calendar não gera o Meet link:

```
Caso 1 — Credenciais não configuradas:
AYA: [agendamento criado sem Meet link]
AYA: "[...] Em breve um consultor entrará em contato com o link da reunião."

Caso 2 — Erro durante criação:
AYA: "Perfeito 😊
No momento tivemos uma pequena instabilidade para concluir o agendamento automático.
Mas fique tranquilo(a), em breve um consultor da Cadife Tour entrará em contato 
para finalizar sua curadoria."
```

**Avaliação:** Fallback adequado, mas o Caso 1 (credenciais não configuradas) não tem uma mensagem específica — usa o mesmo fluxo normal sem Meet link. O cliente não é informado de que receberá o link depois.

---

## 6. PROBLEMAS IDENTIFICADOS

### 6.1 CRÍTICO — Verificação Real de Disponibilidade

Se `get_proximos_slots_disponiveis` não consulta o Google Calendar real:
- Double-booking é possível
- Consultor pode ter compromissos que a AYA ignora

**Ação:** Implementar `freebusy().query()` na verificação de slots.

### 6.2 MÉDIO — Falta de Atualização de Evento

Se o cliente precisar reagendar (status do agendamento muda de `confirmado` para `cancelado` e novo agendamento é criado), o evento antigo no Google Calendar **NÃO é excluído/atualizado**.

**Problema:** O consultor terá eventos Ghost no Calendar.

**Solução:** Armazenar o `event_id` do Google Calendar no banco e excluir/cancelar o evento quando necessário:
```sql
ALTER TABLE agendamento ADD COLUMN google_event_id VARCHAR;
```

### 6.3 MÉDIO — Fuso Horário em Horário de Verão

O timezone BRT (-3h) está hardcoded. Em horário de verão (novembro-fevereiro, BRT = -2h), os eventos serão criados com 1 hora de diferença.

### 6.4 MÉDIO — Participantes não são adicionados ao evento

O evento criado não adiciona o cliente como participante (`attendees`). Sem isso:
- O cliente não recebe invite do Google Calendar
- Apenas o link Meet é enviado via WhatsApp

**Trade-off:** Adicionar cliente como attendee exige o email do cliente (não coletado no briefing). Por ora, o fluxo via WhatsApp é adequado.

### 6.5 BAIXO — `sendUpdates="none"` pode causar confusão

Com `sendUpdates="none"`, consultores com o calendário na conta Google **não são notificados por email**. Eles dependem da notificação FCM do app. Se o app falhar, o consultor pode não saber do agendamento.

**Solução:** `sendUpdates="externalOnly"` para notificar o calendário do consultor mas não o cliente externo.

---

## 7. CHECKLIST DE CONFIGURAÇÃO

### 7.1 GCP Console

```
□ Google Calendar API habilitada no projeto
□ Google Meet API habilitada (ou usando conferenceData do Calendar)
□ Service Account criada com papel: Calendar Admin ou Editor
□ Domain-Wide Delegation habilitada (se usando organizationAccount)
□ Chave JSON da Service Account baixada e segura
```

### 7.2 Variáveis de Ambiente

```bash
GOOGLE_SERVICE_ACCOUNT_PATH=/path/to/service-account.json
GOOGLE_CALENDAR_ID=primary  # ou ID do calendário específico

# Para Domain-Wide Delegation:
GOOGLE_CALENDAR_DELEGATE_EMAIL=consultor@cadifetour.com.br
```

### 7.3 Validação

```python
# Script de teste
from app.services.google_calendar_service import criar_evento_curadoria
from datetime import date, time

result = await criar_evento_curadoria(
    lead_nome="Teste",
    data=date(2026, 6, 15),
    hora=time(10, 0),
    duracao_minutos=60
)
print(f"Meet link: {result}")  # Deve retornar URL válida
```

---

## 8. TABELA DE STATUS

| Funcionalidade | Status | Qualidade |
|---------------|--------|-----------|
| Service Account auth | ✅ Implementado | Alta |
| Criação de evento com Meet | ✅ Implementado | Alta |
| conferenceDataVersion=1 | ✅ Correto | Alta |
| Degradação graciosa | ✅ Implementado | Alta |
| Reminders configurados | ✅ | Boa |
| Timezone BRT | ⚠️ Hardcoded | Média |
| Verificação real de disponibilidade | ❓ A verificar | Crítico se ausente |
| google_event_id persistido | ❌ Ausente | Importante |
| Cancelamento de eventos | ❌ Ausente | Importante |
| sendUpdates para consultor | ⚠️ "none" | Revisar |
