# Workflows and Business Rules

Regras de ciclo de vida e fluxos operacionais detalhados.

## 1. Regras de Atendimento e Operação

| Regra | Especificação |
|---|---|
| **Horário de atendimento** | Segunda a Sexta, das 09h às 16h (Brasília) |
| **Capacidade diária** | Até 6 atendimentos de curadoria por dia |
| **Duração da curadoria** | 30 a 60 minutos por sessão |
| **Tempo de resposta da IA** | Máximo de 3 segundos |
| **Notificação ao consultor** | Em até 2 segundos (FCM) |

## 2. Fluxo de Status do Lead (Ciclo de Vida)

- `NOVO` → `EM_ATENDIMENTO`: quando a IA inicia diálogo.
- `EM_ATENDIMENTO` → `QUALIFICADO`: briefing atinge 60%+ de completude.
- `QUALIFICADO` → `AGENDADO`: cliente aceita agendar curadoria.
- `QUALIFICADO` → `PROPOSTA`: consultor envia proposta direto.
- `AGENDADO` → `PROPOSTA`: após realização da curadoria.
- `PROPOSTA` → `FECHADO`: pagamento realizado.
- Qualquer estado → `PERDIDO`: desistência ou 30 dias sem resposta.

## 3. Qualificação e Score de Leads

| Score | Critérios | Ação Recomendada |
|---|---|---|
| **QUENTE** | Destino + datas + pessoas + orçamento definidos | Priorizar contato imediato |
| **MORNO** | Destino definido mas datas/orçamento em aberto | Agendar curadoria e enviar conteúdo |
| **FRIO** | Interesse genérico, sem dados concretos | Nutrição via WhatsApp |

## 4. Fluxo Operacional Detalhado (WhatsApp → App)

1. **Entrada:** Cliente envia mensagem no WhatsApp.
2. **Recepção:** Webhook recebe payload e IA (AYA) responde.
3. **Qualificação:** IA coleta briefing via perguntas estratégicas.
4. **Extração:** Backend extrai entidades e atualiza banco.
5. **Avaliação:** Motor verifica completude (>= 60%?).
6. **Agendamento:** Se qualificado, IA oferece horários de curadoria.
7. **Notificação:** Firebase FCM notifica o consultor no App.
8. **Dashboard:** Consultor visualiza o lead com dados estruturados.
9. **Finalização:** Consultor realiza curadoria e envia proposta.

## 5. Regras de Pagamento e Reservas

- **Confirmação:** Reservas somente após confirmação de pagamento total.
- **Formas Aceitas:** Cartão de crédito, boleto, entrada + parcelas.
- **Restrição IA:** A IA NUNCA deve mencionar valores ou condições de pagamento.
- **Propostas:** Valores estimados são gerados exclusivamente por consultores humanos.
