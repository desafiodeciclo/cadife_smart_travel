## 8. Regras de Negócio

### 8.1 Atendimento e Operação

| Regra | Especificação |
|---|---|
| **Horário de atendimento** | Segunda a Sexta, das 09h às 16h (Brasília) |
| **Capacidade diária** | Até 6 atendimentos de curadoria por dia |
| **Duração da curadoria** | 30 a 60 minutos por sessão (principalmente online) |
| **Intervalo entre atendimentos** | Mínimo de 1 hora entre agendamentos |
| **Atendimento da IA** | 24/7 — o assistente não tem horário de operação restrito |
| **Tempo de resposta da IA** | Máximo de 3 segundos para retornar ao cliente |
| **Notificação ao consultor** | Em até 2 segundos após criação/atualização de lead (FCM) |

### 8.2 Pagamento e Reservas

- Reservas somente após confirmação de pagamento total
- Formas aceitas: cartão de crédito, boleto, entrada + parcelas
- A IA nunca menciona valores ou condições de pagamento
- Propostas com valor estimado só são geradas pelo consultor humano

### 8.3 Qualificação e Score de Leads

| Score | Critérios | Ação Recomendada |
|---|---|---|
| **QUENTE** | Destino + datas + pessoas + orçamento definidos | Priorizar contato imediato — oferecer curadoria no mesmo dia |
| **MORNO** | Destino definido mas datas ou orçamento em aberto | Agendar curadoria e enviar conteúdo de apoio (FAQ, destinos) |
| **FRIO** | Apenas interesse genérico, sem dados concretos | Manter nutrição via WhatsApp, follow-up automatizado |

### 8.4 Fluxo de Status do Lead

Ciclo de vida obrigatório:

- `NOVO` → `EM_ATENDIMENTO`: quando a IA inicia diálogo com o cliente
- `EM_ATENDIMENTO` → `QUALIFICADO`: quando briefing atinge 60%+ de completude
- `QUALIFICADO` → `AGENDADO`: quando cliente aceita agendar curadoria
- `QUALIFICADO` → `PROPOSTA`: quando consultor envia proposta sem agendamento prévio
- `AGENDADO` → `PROPOSTA`: após realização da curadoria
- `PROPOSTA` → `FECHADO`: quando cliente aprova proposta e realiza pagamento
- Qualquer estado → `PERDIDO`: quando cliente desiste ou não responde por 30 dias

---

## 9. Fluxo Operacional Detalhado

### 9.1 Fluxo Principal — WhatsApp → Lead → App

| # | Etapa | Detalhe | Ator |
|---|---|---|---|
| **1** | **Entrada do Cliente** | "Quero viajar para Portugal" — mensagem no WhatsApp | Cliente |
| **2** | **Recepção** | Webhook recebe payload, identifica tipo (texto/audio/imagem) | Backend |
| **3** | **Recepção Humanizada** | "Olá, sou a AYA da Cadife Tour. Vou te ajudar a organizar sua viagem!" | IA (AYA) |
| **4** | **Qualificação** | IA faz perguntas estratégicas uma a uma para coletar briefing | IA (AYA) |
| **5** | **Extração de Dados** | A cada resposta, IA extrai entidades e atualiza briefing no banco | IA + Backend |
| **6** | **Avaliação de Completude** | Motor verifica: briefing >= 60%? → sim: oferta de curadoria \| não: continuar perguntas | Orquestrador |
| **7a** | **Caminho A: Curadoria Aceita** | IA oferece horários → cliente escolhe → agendamento criado no banco | IA + Cliente |
| **7b** | **Caminho B: Sem Agendamento** | "Vou encaminhar suas informações para um consultor. Em breve entraremos em contato." | IA |
| **8** | **Criação do Lead** | Lead salvo com briefing completo, score atribuído, status = qualificado | Backend |
| **9** | **Notificação Push** | Firebase FCM: 'Novo lead qualificado: Portugal, 3 pessoas, orçamento médio' | FCM → App |
| **10** | **Dashboard Agência** | Consultor vê card do lead em tempo real com todos os dados estruturados | App Agência |
| **11** | **Curadoria Humana** | Consultor pesquisa operadoras, monta proposta personalizada | Consultor |
| **12** | **Retorno ao Cliente** | Proposta enviada via WhatsApp ou atualização de status no App Cliente | Consultor |
