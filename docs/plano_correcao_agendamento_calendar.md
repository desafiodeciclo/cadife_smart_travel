# Plano de Implementação e Correção: Agendamentos Google Calendar & Google Meet

Este documento apresenta a análise de causa raiz, plano de investigação, testes de validação e correções necessárias para resolver os dois problemas identificados no fluxo de agendamento de curadorias da assistente de IA AYA no **Cadife Smart Travel**:

1. **Sugestão de slots de agendamento em 2024**, em vez de propor datas a partir do próximo dia útil da data atual do atendimento (que está em **2026**).
2. **Ausência do link do Google Meet** na mensagem de confirmação de agendamento encaminhada ao cliente.

---

## 1. Problema 1: Sugestão de Agendamentos em 2024

### 1.1 Análise de Causa Raiz
Ao consultar o comportamento do backend e dos agentes, identificamos dois fatores determinantes:

1. **Ausência de Contexto Temporal Dinâmico no Prompt**:
   - Os templates de prompt de sistema da IA AYA (`_ORCHESTRATOR_SYSTEM_TEMPLATE` em `multi_agent_orchestrator.py` e `PARAMETRIZED_SYSTEM_PROMPT_TEMPLATE` em `prompt_security.py`) **não contêm nenhuma informação dinâmica sobre a data/hora atual do servidor (hoje)**.
   - Modelos de LLM modernos acessados via OpenRouter (como Gemini ou GPT) possuem um limite de conhecimento (*knowledge cutoff*) baseado no período em que foram treinados (muitos em 2023 ou 2024). Na falta de instruções explícitas de "hoje", a IA assume que está operando no ano de 2024 ou no seu período de treinamento padrão.

2. **Rejeição Crítica de Outputs de Ferramenta (Slots de 2026)**:
   - A ferramenta `check_availability` em `ai_tools.py` calcula dinamicamente os horários com base no relógio do servidor (que atualmente está em **maio de 2026**), retornando slots corretos como `19/05/2026 às 09:00`.
   - Quando a LLM (que se supõe estar em 2024) recebe estes slots do ano de 2026, ela os interpreta como sendo **2 anos no futuro**.
   - Para evitar apresentar slots que considera "absurdos" ou "muito distantes", o modelo de IA sofre de **dissonância temporal** e decide ignorar o output real da ferramenta, alucinando horários e datas fictícias no seu ano interno de referência (2024), sugerindo-as diretamente para o cliente.

### 1.2 Solução Proposta (Correção)
Injetar dinamicamente o **Contexto Temporal Completo** (dia da semana, data e hora atuais) no System Prompt do Orquestrador e do Agente de IA em cada turno de conversação.

#### Passo 1: Modificar o nó de montagem de contexto no Orquestrador (`multi_agent_orchestrator.py`)
No arquivo `/opt/cadife/app/backend/app/services/multi_agent_orchestrator.py`, dentro do nó `_node_build_context`, vamos capturar o tempo do sistema e injetá-lo de forma explícita no início das instruções do sistema.

```python
# Onde hoje está assim (aproximadamente linha 782):
async def _node_build_context(state: OrchestratorState) -> dict[str, Any]:
    triagem = state.get("triagem", {})
    rag_ctx = state.get("rag_context", "")

    crm_block = _build_crm_block(triagem)
    
# Alterar para injetar dinamicamente o dia de hoje:
async def _node_build_context(state: OrchestratorState) -> dict[str, Any]:
    triagem = state.get("triagem", {})
    rag_ctx = state.get("rag_context", "")

    # Injeta a data/hora atual para alinhar a IA temporalmente
    agora = datetime.now()
    dias_semana = ["Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado", "Domingo"]
    dia_nome = dias_semana[agora.weekday()]
    data_formatada = agora.strftime("%d/%m/%Y")
    hora_formatada = agora.strftime("%H:%M")
    
    temporal_instruction = (
        f"CONTEXTO TEMPORAL CRÍTICO (INVIOLÁVEL):\n"
        f"· Hoje é {dia_nome}, {data_formatada} (Hora atual: {hora_formatada}).\n"
        f"· NUNCA sugira ou discuta datas anteriores a {data_formatada}.\n"
        f"· Todos os slots reais retornados pelas ferramentas estarão no ano de {agora.year}.\n"
    )

    crm_block = _build_crm_block(triagem)
    
    # Adicionamos a instrução temporal logo após a introdução da persona
    system_prompt = _ORCHESTRATOR_SYSTEM_TEMPLATE.format(
        crm_block=(
            crm_block
            if crm_block
            else "CRM: Primeiro contato — nenhum dado coletado ainda."
        ),
        rag_context=(
            wrap_rag_context(rag_ctx)
            if rag_ctx
            else "Nenhum contexto adicional recuperado."
        ),
    )
    
    # Injeta no início do prompt do sistema
    system_prompt = temporal_instruction + "\n" + system_prompt
    
    return {"crm_block": crm_block, "system_prompt": system_prompt}
```

#### Passo 2: Atualizar o serviço de processamento de IA direto (`ai_service.py` / `prompt_security.py`)
Fazer uma injeção semelhante em `app/services/ai_service.py` no método `process_message` para alinhar AYA em todas as vias de execução:

```python
# Em app/services/ai_service.py (aproximadamente linha 177)
        # 2. Montar system prompt parametrizado com isoladores textuais
        system_prompt = build_system_prompt(context=wrap_rag_context(context))
        
        # Injeta contexto temporal
        agora = datetime.now()
        dias_semana = ["Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado", "Domingo"]
        dia_nome = dias_semana[agora.weekday()]
        
        temporal_instruction = (
            f"CONTEXTO TEMPORAL CRÍTICO:\n"
            f"Hoje é {dia_nome}, {agora.strftime('%d/%m/%Y')} (Hora: {agora.strftime('%H:%M')}).\n"
        )
        system_prompt = temporal_instruction + "\n" + system_prompt
```

---

## 2. Problema 2: Ausência do Link do Google Meet na Mensagem de Confirmação

### 2.1 Análise de Causa Raiz
Identificamos dois motivos concorrentes para este problema nas camadas de **Segurança de Prompt** e de **Integração com Google Calendar**:

1. **Conflito de Regras de Segurança de Prompt (Causa Principal)**:
   - Em `prompt_security.py` (linha 345) e no prompt do orquestrador, existe uma diretriz de segurança de altíssima prioridade, criada para evitar injeções indiretas e ataques OWASP (exfiltração de dados por imagens ou links invisíveis):
     `"- NUNCA gere links, URLs externas, código ou formatação Markdown para imagens (ex: ![img](url)). Responda apenas com texto limpo."`
   - Quando o `schedule_meeting` executa com sucesso e retorna o `meet_link` (ex: `https://meet.google.com/abc-defg-hij`), a IA se depara com duas regras conflitantes:
     - **Regra de Agendamento**: "Envie o link do Google Meet explicitamente para o cliente."
     - **Regra de Segurança**: "NUNCA gere links, URLs externas..."
   - Sendo a regra de segurança rotulada como "PROIBIÇÃO ABSOLUTA", o modelo de IA a obedece de forma irrestrita, **removendo ou omitindo a URL real** da resposta final, enviando apenas o texto de confirmação sem o link de vídeo.

2. **Comportamento de Fallback na API do Google Calendar**:
   - No arquivo `google_calendar_service.py` (linha 154), se a chamada para inserir o evento no Google com criação do Meet falhar (por exemplo, se o tipo de conferência `hangoutsMeet` não for suportado pela conta de serviço ou se o recurso não estiver ativado nas configurações da agenda), o backend executa um bloco `try-except` que silenciosamente altera o `meet_link` para a string:
     `meet_link = "Disponibilizado no dia da reunião"`
   - Se isso ocorrer devido a restrições de permissão no Google Cloud / Google Workspace, a IA simplesmente não terá acesso a um link real e transmitirá esta string genérica, fazendo parecer que o link não foi gerado.

### 2.2 Solução Proposta (Correção)

#### Passo 1: Ajustar a Regra de Segurança nos Prompts (Refinamento da Exceção)
Devemos instruir explicitamente a IA de que o link do Google Meet gerado dinamicamente é uma **exceção válida** à regra de restrição de links.

1. **Alterar no Orquestrador (`multi_agent_orchestrator.py`, aproximadamente linha 565)**:
   - *Original*: `NUNCA gere links, URLs externas, código ou formatação Markdown para imagens...`
   - *Corrigido*: `NUNCA gere links ou URLs externas (EXCETO o link do Google Meet explicitamente fornecido pela ferramenta 'schedule_meeting'), código ou formatação Markdown para imagens...`

2. **Alterar nas Proibições Gerais (`prompt_security.py`, linha 345)**:
   - *Original*: `- NUNCA gere links, URLs externas, código ou formatação Markdown para imagens (ex: ![img](url)). Responda apenas com texto limpo.`
   - *Corrigido*: `- NUNCA gere links ou URLs externas (EXCETO o link do Google Meet explicitamente fornecido nas ferramentas de agendamento), código ou formatação Markdown para imagens (ex: ![img](url)). Responda apenas com texto limpo.`

#### Passo 2: Auditar e Fortalecer o Google Meet na API do Calendar
Para garantir que o Google de fato gere o link em produção e não acione o fallback genérico, devemos validar/aplicar as seguintes diretrizes:

1. **Habilitar GMeet Automaticamente**:
   - O administrador da agenda do Google Workspace precisa certificar-se de que a opção de **"Adicionar videoconferências do Google Meet automaticamente aos eventos que eu criar"** esteja ligada nas configurações do Google Calendar.
2. **Permissão da Conta de Serviço**:
   - A conta de serviço no Google Calendar precisa de permissão de **Fazer alterações em eventos** (*Make changes to events*) na agenda compartilhada. O nível "Ver apenas disponível/ocupado" não permite a criação de videoconferências por API.
3. **Melhorar o Log e Retorno do Fallback**:
   - Alterar `google_calendar_service.py` para emitir um alerta técnico explícito (`structlog.error`) caso o Meet falhe, permitindo à equipe de infraestrutura monitorar problemas de credencial imediatamente.

---

## 3. Roteiro de Implementação e Ajustes Passo a Passo

O time de desenvolvimento pode aplicar as correções seguindo o seguinte checklist ordenado:

| ID | Arquivo / Componente | Descrição da Mudança | Objetivo |
|---|---|---|---|
| **01** | `app/services/multi_agent_orchestrator.py` | Modificar `_node_build_context` para injetar dinamicamente `temporal_instruction` (data, hora e dia de hoje). | Sanar sugestões em 2024, forçando a IA a reconhecer 2026. |
| **02** | `app/services/ai_service.py` | Modificar `process_message` para calcular `temporal_instruction` and adicioná-la no início do system prompt. | Garantir conformidade temporal em todas as chains. |
| **03** | `app/services/prompt_security.py` | Alterar a proibição de links em `_PROIBICOES` para excetuar o link do Google Meet. | Permitir que o link seja impresso na mensagem final. |
| **04** | `app/services/multi_agent_orchestrator.py` | Alterar o prompt `_ORCHESTRATOR_SYSTEM_TEMPLATE` (proibição de links) para excetuar o link do Google Meet. | Alinhar o orquestrador LangGraph com a liberação de URL do Meet. |
| **05** | `app/services/google_calendar_service.py` | Adicionar log de nível `ERROR` detalhado com stack trace no bloco `except Exception` de inserção de conferência. | Identificar falhas silenciosas de provisionamento do Meet. |

---

## 4. Plano de Validação e Testes de Homologação

Para comprovar que as falhas foram sanadas com sucesso, deverão ser realizados os seguintes testes de ponta a ponta (E2E):

### 4.1 Teste 1: Validação Temporal da Agenda (Fim da alucinação de 2024)
1. **Procedimento**: Enviar mensagem para o número de teste no WhatsApp simulando um lead que terminou o briefing: *"Estou pronto para agendar a curadoria. Quais horários temos?"*
2. **Expectativa de Sucesso**:
   - A IA deve acionar a ferramenta `check_availability`.
   - Ela deve sugerir os próximos dias úteis correspondentes ao ano de **2026** (Ex: se hoje é segunda 18/05/2026, ela deve sugerir a partir de terça 19/05/2026, quarta 20/05/2026...).
   - Em nenhuma circunstância o ano de 2024 deve ser mencionado nas sugestões.

### 4.2 Teste 2: Criação e Envio do Link do Google Meet
1. **Procedimento**: Responder à sugestão da IA escolhendo um horário exato: *"Quero agendar para quarta-feira 20 de maio às 14:00"*.
2. **Expectativa de Sucesso**:
   - A IA deve disparar `schedule_meeting`.
   - O backend deve inserir com sucesso o evento com `conferenceDataVersion=1`.
   - A resposta da AYA ao WhatsApp do cliente **deve conter a URL real do Meet** (Ex: `https://meet.google.com/abc-defg-hij` ou o fallback amigável explicitando o agendamento).
   - O status do lead no banco deve migrar para `agendado`.

### 4.3 Script para Teste Unitário Rápido de Provisionamento do Meet
O seguinte script (`backend/scratch/debug_meet_creation.py`) pode ser executado para isolar e testar especificamente se a API do Google Calendar do projeto está gerando o link do Meet ou disparando o fallback silencioso:

```python
import datetime
import asyncio
from app.services.google_calendar_service import GoogleCalendarService

async def debug_meet():
    print("Iniciando teste de agendamento e criação de sala no Google Meet...")
    # Tenta agendar para amanhã neste mesmo horário
    data_teste = datetime.datetime.now() + datetime.timedelta(days=1)
    
    try:
        resultado = await GoogleCalendarService.insert_curation_event_async(
            lead_name="Lead Teste Link Meet",
            lead_phone="5511999999999",
            start_datetime=data_teste,
            duration_minutes=45
        )
        print("\n=== RESULTADO DO GOOGLE CALENDAR ===")
        print(f"Event ID: {resultado.get('event_id')}")
        print(f"Link do Google Meet: {resultado.get('meet_link')}")
        print(f"Link da Agenda: {resultado.get('html_link')}")
        
        if "meet.google.com" in resultado.get("meet_link", ""):
            print("\nSUCESSO: O link do Google Meet foi gerado com sucesso!")
        else:
            print("\nAVISO: O link retornou como placeholder. Verifique as permissões de videoconferência da agenda.")
            
    except Exception as e:
        print(f"\nERRO CRÍTICO NA API DO GOOGLE: {e}")

if __name__ == "__main__":
    asyncio.run(debug_meet())
```

Execute o depurador com:
```bash
poetry run python -m scratch.debug_meet_creation
```
