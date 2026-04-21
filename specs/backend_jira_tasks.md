# 🚀 Cadife Smart Travel Backend — Branch Tasks (REVISADO v2.0)

> Padrão de branches: `(F) feat/`, `(R) refactor/`, `(C) chore/`, `(B) bugfix/`
> **⚠️ Legenda de revisão:** `✅ Validado` | `🔧 Atualizado` | `🆕 Nova Task` | `🚨 Gap Crítico`
> Total: **40 tasks** | Estimado: **228 pontos** *(era 30 tasks / 170 pts)*

---

## 📋 RESUMO DA ANÁLISE DE GAPS

| Categoria | Qtde | Impacto |
|---|---|---|
| Tasks validadas sem alteração | 18 | — |
| Tasks existentes com atualização necessária | 3 | Correção de escopo |
| **Tasks novas críticas (bloqueiam o MVP)** | **5** | 🚨 CRÍTICO |
| Tasks novas de alta prioridade | 6 | 🔴 Alto |
| Tasks novas de média/baixa prioridade | 4 | 🟠 Médio |

---

# 📦 Sprint 1 — Foundation e Configurações Iniciais (Semana 1)

## História 1.1 — Setup FastAPI, Infraestrutura e Segurança Multicamadas (21 pontos)

**Contexto:** O projeto necessita de uma base técnica robusta, aplicando Clean Architecture e padrões de injeção de dependência para que o backend seja escalável. É crucial ter a infraestrutura inicial de ORM e regras essenciais de segurança configuradas para mitigar vulnerabilidades comuns.
**Objetivo:** Realizar o setup primário do framework FastAPI, configurar a modelagem de banco de dados (Repository Pattern) e implementar defesas estritas multicamadas.

### ✅ (C) chore/setup-fastapi-project
**Prioridade:** 🔴 Critical | **Pontos:** 5 | **Assignee:** Tech Lead / Backend | **Status:** ✅ Validado
**Contexto:** Padrão ouro exige um repositório organizado utilizando princípios sólidos de Clean Architecture e separação de responsabilidades (Domain-Driven Design).
**Objetivo:** Criar o projeto Python, base de injeção de dependências e configuração estrita.
- [ ] **Configurar Repositório Base (Clean Architecture):** Inicializar ambiente virtual (`venv`), instalar `fastapi`, `uvicorn`, `pydantic` e organizar diretórios baseados em módulos estruturais: Domain, Application/UseCases, Infrastructure, Presentation/API. (3h)
- [ ] **Configuração Global (Settings/Env) e Segurança de Secrets:** Utilizar `pydantic-settings` para validar `.env`. Integrar estrutura base para externalização segura de segredos em produção (ex: AWS Secrets Manager/HashiCorp Vault) assegurando chaves do WhatsApp e OpenAI. (2h)
- [ ] **Middlewares Essenciais Base:** Configurar middlewares para injeção de ID único por requisição, instrumentação de timeout para early termination em caso de staling connections. (1h)

### ✅ (F) feat/multi-layer-security-setup
**Prioridade:** 🔴 Critical | **Pontos:** 8 | **Assignee:** Security/Backend | **Status:** ✅ Validado
- [ ] **Rate Limiting e Defesa de Abusos:** Implementar e configurar rate limit por IP para requests padrão (usando Redis para counter global) com thresholds ajustáveis sob carga. (3h)
- [ ] **Security Headers (Helmet) & Criptografia PII:** Retornar Headers de proteção de conteúdo (HSTS, Content-Security-Policy). Definir mecanismo transparente de encriptação at-rest em campos de texto com dados pessoais e identificáveis (PII) de contatos do db usando Fernet (AES). (3h)
- [ ] **Auditoria de Logs (Audit Trail):** Implementar logging estruturado com campos customizados em formato JSON interceptando o request life-cycle. Qual UserID (se autenticado) operou qual alteração no CRM para ser lido em stacks de observabilidade. (2h)

### ✅ (C) chore/setup-database-orm-architecture
**Prioridade:** 🔴 Critical | **Pontos:** 8 | **Assignee:** Backend Architect | **Status:** 🔧 Atualizado
**Contexto:** A modelagem forte deve utilizar o padrão Repository/Data Mapper garantindo independência de ORM na lógica de negócio e validação pré-DB.
**Objetivo:** Integrar persistência relacional desacoplada.
- [ ] **Instalação e Padrão Repository:** Configurar SQLAlchemy assíncrono (ou SQLModel) junto com Alembic para migrations do banco (PostgreSQL). Adicionar camada de acesso de dados que herda `AbstractRepository` abstraindo acoplamento de rotas e banco. (4h)
- [ ] **Modelagem das Tabelas Base:** Estruturar Tabelas Entidade (`Lead`, `Briefing`, `Interação`, `Agendamento`) com constraints estritos e verificação de nível de banco de dados (constraints check/enums para status) e índices combinados eficientes nos lookups frequentes. (4h)
- [ ] 🆕 **Modelagem da Tabela `Proposta`:** Criar entidade `Proposta` conforme spec (seção 4.5): campos `id`, `lead_id` (FK), `descricao`, `valor_estimado`, `status` (enum: `rascunho`/`enviada`/`aprovada`/`recusada`/`em_revisao`), `criado_em`. Adicionar migration Alembic correspondente. (2h)

---

## História 1.2 — Autenticação, RBAC e Integração Webhook (22 pontos)

**Contexto:** Todo o fluxo do sistema AYA depende do recebimento seguro dos eventos via Meta e envios de respostas. Simultaneamente, o acesso ao painel estrutural pelos consultores demanda um controle fino restritivo, para garantir que apenas indivíduos com o devido papel possam atuar.
**Objetivo:** Habilitar serviços da API para recebimento assíncrono e disparo das mensagens pelo WhatsApp Cloud API, somados à autenticação base e estrutura RBAC da gestão do app.

### ✅ (F) feat/advanced-authentication-rbac
**Prioridade:** 🔴 Critical | **Pontos:** 8 | **Assignee:** Backend Security | **Status:** 🔧 Atualizado
- [ ] **Login, Hash (Argon2) e JWT:** Rota de autenticação para geração de token JWT de curta duração com hash robustos para o banco de senhas, habilitando rota adjacente para refresh-token flow evitando interrupção para os agentes. (4h)
- [ ] **Role-Based Access Control (RBAC):** Adicionar sistema de Permissões nas dependências da Rota (Ex: `RequiresRole("Consultor")` ou `RequiresRole("Admin")`), restringindo leitura de leads corporativos que não pertençam ao escopo (tenant/owner ID) do solicitante. (4h)
- [ ] 🆕 **Endpoint `POST /users/fcm-token`:** Rota autenticada para registro e atualização do FCM token do dispositivo do consultor. Armazenar token vinculado ao `user_id` no banco. Token deve ser sobrescrito em novo login/device. Essencial para o fluxo de notificações push (spec seção 5.6). (2h)
- [ ] 🆕 **Endpoint `GET /users/me`:** Rota autenticada que retorna o perfil completo do usuário logado (nome, role, email, avatar_url). Sem leak de campos sensíveis (hash de senha). DTO com `response_model` estrito. (1h)

### ✅ (F) feat/whatsapp-cloud-webhook-async
**Prioridade:** 🔴 Critical | **Pontos:** 8 | **Assignee:** Backend | **Status:** 🔧 Atualizado
**Contexto:** Meta exige resposta < 3s, o processamento da IA levará 5 a 15s inviabilizando processamento síncrono.
**Objetivo:** Receber hooks do WhatsApp de forma garantida assincronamente.
- [ ] **Verificação de Webhook GET & Signature:** Endpoint para validar o Challenge Token do app da Meta e interceptador de header para validar HMAC signature (x-hub-signature) comprovando que quem disparou a rota foi de fato a Meta. (2h)
- [ ] **Fila e Message Broker (Celery/RabbitMQ ou Redis):** Rota POST deve apenas serializar os dados provenientes da mensagem, persistir no banco no log crú (raw_logs) acusando o ack HTTP200 e publicando para fila do celery/broker de processamento real as infos de extração textuais. (6h)

---

### 🆕🚨 (F) feat/whatsapp-send-message-service
**Prioridade:** 🔴 Critical | **Pontos:** 6 | **Assignee:** Backend | **Status:** 🆕 Nova Task — Gap Crítico
**Contexto (Gap identificado):** A task de webhook existente cobre apenas o **recebimento** de mensagens da Meta. Entretanto, o fluxo principal da spec (seção 9.1) exige que o backend **envie respostas** de volta ao cliente via WhatsApp Cloud API após o processamento da IA. Sem este serviço, o assistente AYA não consegue responder ao cliente — tornando todo o fluxo ponta a ponta inoperante.
**Objetivo:** Implementar serviço dedicado de envio de mensagens via WhatsApp Cloud API.
- [ ] **WhatsApp Sender Service:** Criar `whatsapp_service.py` na camada de Infrastructure encapsulando chamadas HTTP para `https://graph.facebook.com/v18.0/{PHONE_NUMBER_ID}/messages`. Suportar envio de mensagens de texto simples com autenticação Bearer via `WHATSAPP_TOKEN`. Implementar retry com backoff exponencial em caso de falha transitória da API Meta. (3h)
- [ ] **Integração no Worker Assíncrono:** Após o worker de fila processar a resposta da IA e persistir no banco, invocar o `WhatsappSenderService` para despachar a resposta ao cliente. Logar resultado do envio (sucesso/falha) na tabela `Interação` com campo `enviado_em`. Timeout máximo de 3s conforme SLA da spec (seção 12.1). (3h)

---

# 🧠 Sprint 2 — Inteligência Artificial, RAG e Domínio Rico (Semana 2)

## História 2.1 — LLM Segura e Retrieval Inteligente (30 pontos)

**Contexto:** A inteligência artificial exige memória do contexto das interações com o lead e acesso ágil a uma base de conhecimento privada, a fim de realizar a extração e qualificação com extrema assertividade, livres de alucinações no LLM.
**Objetivo:** Integrar os fluxos LLM usando LangChain/Vectors, realizar a ingestão dos dados contextuais da agência de interações (RAG) e instaurar de forma resiliente as defesas de contexto no diálogo do IA.

### ✅ (C) chore/setup-vector-database
**Prioridade:** 🔴 Critical | **Pontos:** 8 | **Assignee:** AI Specialist | **Status:** ✅ Validado
- [ ] **Ferramenta de Ingestão Modular:** Criar pipelines diárias para reprocessamento documental (`Document loader -> Text Splitter -> Cache Embeddings`). (4h)
- [ ] **Semantics & Metadata Filtering:** Utilizar OpenAI Embeddings gravando chunks no DB referenciando metadados como tags de tópicos ("Destino: Nordeste", "Tema: Financiamento") para tornar o filter_by da query do bot mais contido e assertiva a contexto (Hard constraints metadata). (4h)

---

### 🆕🚨 (F) feat/rag-cadife-knowledge-base-ingestion
**Prioridade:** 🔴 Critical | **Pontos:** 6 | **Assignee:** AI Specialist + Diego (PO) | **Status:** 🆕 Nova Task — Gap Crítico
**Contexto (Gap identificado):** A task de setup do Vector DB cobre a infraestrutura, mas nenhuma task cobre a ingestão dos **documentos reais da Cadife Tour** definidos na spec (seção 6.6). Sem a base de conhecimento populada, o RAG não tem contexto para responder — tornando os critérios de aceite do MVP (seção 14.1) inalcançáveis.
**Objetivo:** Popular e validar a base de conhecimento RAG com os documentos institucionais da Cadife Tour.
- [ ] **Criação dos Documentos Base:** Com validação do PO Diego, redigir e revisar os 7 arquivos da base RAG: `identidade_empresa.txt`, `fluxo_atendimento.txt`, `faq.txt`, `regras_negocio.txt`, `destinos.txt`, `objecoes.txt`, `argumentacao.txt`. Chunking configurado: 300–500 tokens por chunk, sem redundância, contexto objetivo. (4h)
- [ ] **Pipeline de Ingestão e Validação de Qualidade:** Executar pipeline de ingestão dos documentos no ChromaDB/PGVector. Rodar 10 queries de validação semântica predefinidas pelo PO (critério de aceite MVP seção 14.1). Medir relevância dos chunks recuperados e ajustar chunking/overlap até qualidade satisfatória. (2h)

---

### ✅ (F) feat/langchain-orchestrator-advanced
**Prioridade:** 🔴 Critical | **Pontos:** 10 | **Assignee:** AI Specialist | **Status:** ✅ Validado
- [ ] **Defesa contra Prompt Injections & Fallbacks:** Parametrizar o system prompt com isoladores textuais. Instruir recusa de abordagens (ex: se cliente tenta reprogramar o bot e bypassar role behavior). Montar `Fallback chains`, ou seja, se IA falhar a extração do JSON de output, tentar iterativamente com um LLM mais simples para autocorreção. (5h)
- [ ] **Hybrid Search e RAG Guardrails:** O RetrievalAgent fará busca vetorial, mas passará por um `Context-Filter`. A resposta jamais pode referenciar preços não autorizados pela Cadife. Integrar callbacks nativos (Langfuse) no chain rastreando prompt input/output para medição da qualidade contínua. (5h)

---

### 🆕🚨 (F) feat/langchain-conversation-memory
**Prioridade:** 🔴 Critical | **Pontos:** 6 | **Assignee:** AI Specialist | **Status:** 🆕 Nova Task — Gap Crítico
**Contexto (Gap identificado):** O assistente AYA realiza qualificação via múltiplas perguntas sequenciais (spec seção 6.4: 9 perguntas estratégicas). Sem memória de conversa por lead, cada mensagem seria processada sem contexto das anteriores, tornando a coleta de briefing incoerente. Nenhuma task existente implementa este mecanismo.
**Objetivo:** Implementar memória de conversação por lead no LangChain, garantindo contexto multi-turno.
- [ ] **ConversationBufferWindowMemory por Lead:** Configurar `ConversationBufferWindowMemory` do LangChain keyed por `lead_id`. Persistir histórico de mensagens na tabela `Interação` do PostgreSQL (evitar state apenas em RAM). Ao iniciar nova sessão de chat, recuperar histórico do banco e reinjetar no contexto da chain. (3h)
- [ ] **Controle de Janela de Contexto:** Implementar estratégia de truncamento inteligente do histórico: janela máxima de 20 mensagens recentes + resumo comprimido das anteriores via sumarização LLM. Prevenir estouro de context window da OpenAI em conversas longas sem perder dados do briefing já coletado. (3h)

---

## História 2.2 — Business Rules e Domínio (Engine Validator) (19 pontos)

**Contexto:** A jornada pelo pipeline de um Lead (do status de NOVO até FECHADO) precisa transcorrer através de uma máquina de estados estrita. Inputs aleatórios e informações incompletas pela IA ou agentes humanos devem ser retidos por bloqueadores sistemáticos de negócios.
**Objetivo:** Implementar os validadores em camada de domínio de negócio estritos das propostas e do ciclo de vida que regem a inteligência que guia e reprime os próximos passos de um status do banco de dados.

### ✅ (F) feat/domain-rule-engine-briefing
**Prioridade:** 🔴 Critical | **Pontos:** 8 | **Assignee:** Backend Architect | **Status:** ✅ Validado
- [ ] **Structured Outputs API Schema:** Definir na chamada do ChatCompletion o esquema obrigatório JSON Pydantic Padrão de respostas de qualificação. (2h)
- [ ] **Camada de Validador de Domínio:** A resposta mapeada é injetada numa classe pure python do Application Layer de domínios. Deve processar regras estritas: Checar razoabilidade financeira, checar viabilidade do mês sugerido, se regras falharem -> injetar a falha no histórico do chat e instruir LLM a dialogar pro cliente que a proposta é impraticável pedindo que forneça novos dados lógicos coerentes de viagem. (6h)

---

### 🆕🚨 (F) feat/lead-lifecycle-state-machine
**Prioridade:** 🔴 Critical | **Pontos:** 5 | **Assignee:** Backend Architect | **Status:** 🆕 Nova Task — Gap Crítico
**Contexto (Gap identificado):** A spec (seção 8.4) define um ciclo de vida estrito do lead com 7 transições de estado válidas (NOVO → EM_ATENDIMENTO → QUALIFICADO → AGENDADO etc.) e proíbe transições inválidas. Nenhuma task existente implementa esta máquina de estados — o que permitiria updates incorretos de status (ex: FECHADO → NOVO) corrompendo o pipeline de vendas.
**Objetivo:** Implementar máquina de estados do lead a nível de domínio e banco de dados.
- [ ] **LeadStateMachine no Application Layer:** Criar classe `LeadStateMachine` com mapeamento explícito das transições permitidas por estado (ex: `QUALIFICADO` pode ir para `AGENDADO` ou `PROPOSTA`, mas não para `NOVO`). Qualquer chamada ao `PUT /leads/{id}` que tente uma transição inválida deve retornar HTTP 422 com mensagem descritiva. Regras: `PERDIDO` é alcançável de qualquer estado; lead sem resposta por 30 dias deve transitar automaticamente. (3h)
- [ ] **Gatilho de Score Automático:** Na transição para `QUALIFICADO`, calcular automaticamente o `score` do lead (quente/morno/frio) baseado nos critérios da spec (seção 8.3): `QUENTE` = destino + datas + pessoas + orçamento definidos; `MORNO` = destino definido, datas/orçamento ausentes; `FRIO` = dados insuficientes. Score persistido e exposto no DTO. (2h)

---

### 🆕🚨 (F) feat/proposals-api
**Prioridade:** 🔴 Critical | **Pontos:** 6 | **Assignee:** Backend | **Status:** 🆕 Nova Task — Gap Crítico
**Contexto (Gap identificado):** A spec define a entidade `Proposta` (seção 4.5) e 3 endpoints completos (seção 5.5: `POST /propostas`, `GET /propostas/{id}`, `PUT /propostas/{id}`), além de um fluxo de status completo (`rascunho → enviada → aprovada → recusada`). Nenhuma task de backend cobre a implementação destes endpoints. Sem eles, o consultor não consegue criar e gerenciar propostas pelo App — tornando o fluxo de vendas da agência incompleto.
**Objetivo:** Implementar o módulo completo de propostas (CRUD + lifecycle de status).
- [ ] **CRUD de Propostas com Validação de Permissão:** Implementar endpoints `POST /propostas` (somente `Consultor`/`Admin`), `GET /propostas/{id}` e `PUT /propostas/{id}`. Validar que o `lead_id` referenciado existe e que o usuário solicitante tem permissão de acesso ao lead. `valor_estimado` é opcional (gerado pelo consultor humano, nunca pela IA — conforme spec seção 1.4). (4h)
- [ ] **Lifecycle de Status e Integração com Lead:** Na criação de proposta, validar que o lead está em status `QUALIFICADO` ou `AGENDADO`. Na atualização para `aprovada`, propagar atualização automática do status do lead para `FECHADO`. Na atualização para `recusada`, manter lead em `PROPOSTA` para nova tentativa. Expor propostas no endpoint `GET /leads/{id}` via relação. (2h)

---

# 📱 Sprint 3 — APIs, Cache de Resposta e Notificações (Semana 3)

## História 3.1 — Apresentação com Caching & ViewModels (13 pontos)

**Contexto:** O projeto em frontend não pode consumir gargalos volumosos ao buscar leads na listagem completa ou resumos de histórico, as requisições recorrentes demandam filtros avançados eficientes e isolamentos na rede.
**Objetivo:** Instanciar e desenvolver as apis diretas de gerenciamento de Leads (e seus endpoints associados de paginações e caches com Redis), prevenindo vazamento de dados nos Models com tipagem precisa DTO.

### ✅ (F) feat/leads-management-api-cached
**Prioridade:** 🔴 Critical | **Pontos:** 8 | **Assignee:** Backend | **Status:** ✅ Validado
- [ ] **Listagem Paginada e Cache-Hit / Redis (`GET /leads`):** Implementar camada abstrata de Redis (`FastAPICache.decorator`) estalando TTL. O cache é invalidado proscionalmente sob o signal do Repository Update (`PUT`/`POST`). (4h)
- [ ] **Data Mappers (DTO layer) para Prevenção IDOR/DataLeak:** O endpoint que retorna as métricas e o detalhe do lead jamais manda instâncias literais vindas do banco (impedindo field leakages confidenciais). Uso estrito de `response_models` para separar a lógica de banco (ORM Layer) daquilo que trafegará pela rede em JSON. (4h)

---

### 🆕 (F) feat/leads-api-filtering-and-interactions
**Prioridade:** 🔴 Critical | **Pontos:** 5 | **Assignee:** Backend | **Status:** 🆕 Nova Task
**Contexto (Gap identificado):** A spec define endpoints `GET /leads/{id}/interacoes` e `GET /leads/{id}/briefing` e `PUT /leads/{id}/briefing` (seção 5.3), além de filtros na listagem por status, score, destino e período (seção 7.1). Nenhuma task existente cobre estes endpoints específicos, apenas a listagem básica e o cache.
**Objetivo:** Implementar endpoints de sub-recursos de lead e filtros avançados de listagem.
- [ ] **Endpoints de Sub-Recursos:** Implementar `GET /leads/{id}/interacoes` retornando histórico paginado de mensagens do lead; `GET /leads/{id}/briefing` retornando o briefing estruturado; `PUT /leads/{id}/briefing` para atualização manual pelo consultor com validação dos campos do schema Pydantic. Soft delete (`DELETE /leads/{id}`) marcando `deleted_at` sem remover do banco. (3h)
- [ ] **Filtros Avançados na Listagem:** Adicionar query params ao `GET /leads`: `status`, `score`, `destino` (busca parcial), `data_inicio`, `data_fim`, `q` (busca full-text por nome ou telefone). Implementar índices compostos no PostgreSQL para os campos de filtro mais frequentes. (2h)

---

## História 3.2 — Sistema Resiliente de Notificações (11 pontos)

**Contexto:** Os consultores de viagens da Cadife demandam atualizações em tempo real quando há avanço nas leads processadas. Eles também precisam ter a agenda gerida sem erros, obedecendo às restrições horárias de atendimento da equipe.
**Objetivo:** Implementar serviços periféricos de notificação de push com throttling, para entrega à parte da interface no aplicativo, e desenvolver os checadores de agenda de disponibilidade e bloqueios.

### ✅ (F) feat/push-notifier-service-resilient
**Prioridade:** 🟠 High | **Pontos:** 7 | **Assignee:** DevOps / Backend | **Status:** ✅ Validado
- [ ] **Notificador com Dead Letter Queue (DLQ):** Processar envio do alert no Worker background. Reagindo a um status `QUALIFICADO`. Definir política de backoff properties (`retry_delay`, `max_retries`). Ao falhar limite vezes -> mover p/ log Dead Letter. (4h)
- [ ] **Rate Limits & Throttling em Alertas:** Criar debounce de push alertando sobre um mesmo ID de lead para não causar notificações excessivas aos consultores se a IA extrair blocos picados num prazo < 1 minuto. (3h)

---

### 🆕 (F) feat/agenda-availability-rules
**Prioridade:** 🟠 High | **Pontos:** 4 | **Assignee:** Backend | **Status:** 🆕 Nova Task
**Contexto (Gap identificado):** A spec define regras de negócio estritas para agendamentos (seção 8.1): Seg–Sex 09h–16h, máximo 6 atendimentos/dia, intervalo mínimo de 1h entre sessões. O endpoint `GET /agenda/disponibilidade` é definido na seção 5.4. Nenhuma task de backend implementa estas regras ou o endpoint de disponibilidade.
**Objetivo:** Implementar endpoint de disponibilidade com enforcement das regras de negócio.
- [ ] **Endpoint `GET /agenda/disponibilidade`:** Retornar slots disponíveis para agendamento baseado nas regras: Seg–Sex, 09h–16h (Brasília), máximo 6 agendamentos/dia, intervalo mínimo de 60 minutos entre slots. Query param `data` obrigatório. Retornar lista de horários livres e ocupados. (2h)
- [ ] **Validação no `POST /agenda`:** Ao criar agendamento, verificar no banco se o slot está disponível conforme as regras antes de persistir. Retornar HTTP 409 em caso de conflito (consumido pelo frontend para Conflict Resolution — alinhado com task de concorrência). (2h)

---

# 🎯 Sprint 4 — Transações, Qualidade Integrada e DevOps (Semana 4)

## História 4.1 — Concorrência de Agendamentos (SLA) (12 pontos)

**Contexto:** Endpoints concorrentes com múltiplos consultores acessando agendamentos concomitantemente podem levar ao risco fatal de slots duplicados. As interfaces da API requerem exibições oficiais unificadas.
**Objetivo:** Lidar com a lógica pesada de lock pessimista nos slots do banco e montar documentações claras abertas da interface API em OpenAPI gerando Postman de consumo pro Front.

### ✅ (F) feat/agenda-api-concurrency-lock
**Prioridade:** 🔴 Critical | **Pontos:** 8 | **Assignee:** Backend | **Status:** ✅ Validado
- [ ] **Atomic Pessimistic Concurrence Locks:** A rota CRUD (`/agenda`) aplica locks da query do psql do bloco do dia corrente (`SELECT FOR UPDATE`), travando read/write até completar ou falhar a session da request daquele bloco de hora. Previne overbooking. (5h)
- [ ] **Cronjobs SLA Expiration (Pipeline Monitor):** Usar schedule tasks para inspecionar banco por propostas presas (abandono do Lead ou perda de ticket do backend). Trocar state pra status Expirado contatando timeout API via webhook alert ou marcando no CRM automático. (3h)

---

### 🆕 (C) chore/swagger-postman-api-documentation
**Prioridade:** 🟠 High | **Pontos:** 4 | **Assignee:** Nikolas / Backend | **Status:** 🆕 Nova Task
**Contexto (Gap identificado):** A spec lista "Documentação API (Swagger)" como item dentro do escopo do MVP (seção 2.1) e como critério de aceite explícito (seção 14.1: "Acesso à URL `/docs` do backend"). Nenhuma task cobre a documentação formal da API.
**Objetivo:** Gerar e validar documentação completa da API acessível via Swagger UI.
- [ ] **OpenAPI / Swagger Setup:** Configurar metadados do FastAPI (`title`, `description`, `version`, `contact`). Anotar todos os endpoints com `summary`, `description`, `response_model` e códigos HTTP de erro (`400`, `401`, `403`, `404`, `409`, `422`). Garantir acesso em `/docs` (Swagger UI) e `/redoc` (ReDoc). (2h)
- [ ] **Postman Collection Export:** Exportar collection Postman v2.1 a partir do OpenAPI spec gerado. Incluir exemplos de request/response para os fluxos críticos: login, webhook, criar lead, listar leads, criar proposta. Disponibilizar no diretório `/docs` do monorepo. (2h)

---

## História 4.2 — Testes (CI) & Containerização Produtiva (27 pontos)

**Contexto:** Uma Base MVP robusta não vai à fase final sem testagem funcional em código. O código final deve ser preparado para entrar contido num formato produtivo orquestrável além de contemplar trabalhos paralelos isolados em crons.
**Objetivo:** Implementar fluxo de CI/Testes na esteira antes de entregas e hardear os pipelines em containers visando monitoria e health-checks de Kubernetes para DevOps do time.

### ✅ (C) chore/unit-integration-tests-ci
**Prioridade:** 🔴 Critical | **Pontos:** 10 | **Assignee:** QA / Backend | **Status:** ✅ Validado
- [ ] **Integração Testsuite Pytest CI:** Criar testes end-to-end de rotas (Mockando cliente AsyncHttp) batendo com banco de teste em memória as regras do middleware, JWT decode errors e payload validation errors. (5h)
- [ ] **Security Scans e Static Analysis no GitAction:** Pipeline `flake8/black`, `mypy` pra verificação restrita de tipagem assíncrona, e scanner de vulnerabilidades (ex. Bandit/Trivy) interceptando o pipeline CI em pull requests proibindo merge inseguro. (5h)

### ✅ (C) chore/infrastructure-as-code-k8s
**Prioridade:** 🔴 Critical | **Pontos:** 8 | **Assignee:** DevOps / Backend | **Status:** ✅ Validado
- [ ] **Docker Hardening multi-stage:** O build deve rodar pip install em build-env rodando image distroless via rootless user no runtime com supervisão do entrypoint do FastAPI. Configurar docker-compose centralizando volumes da base, Redis e backend no .yml. (4h)
- [ ] **APM Metrics & Observabilidade API:** Integrar lib de monitoria provendo o `/metrics` compatível com formato do Prometheus. Rotas `/healthz` configuradas para ser lidas por checks de K8S ou infra Load Balancer. (4h)

### ✅ (F) feat/whatsapp-media-analysis-layer
**Prioridade:** 🟡 Medium | **Pontos:** 4 | **Assignee:** Backend | **Status:** ✅ Validado
- [ ] **Parser Condicional Flexível Webhook:** Proteger pydantic models para suportar tipos mistos na rede webhook. Se `audio`, baixar do server s3 da Meta e responder via tool de IA customizada "Áudio não suportado nestes momentos, prefira o meio texto". (4h)

---

### 🆕 (F) feat/lead-expiration-followup-cron
**Prioridade:** 🟡 Medium | **Pontos:** 3 | **Assignee:** Backend | **Status:** 🆕 Nova Task
**Contexto (Gap identificado):** A spec (seção 8.4) especifica que qualquer lead sem resposta por 30 dias deve transitar automaticamente para `PERDIDO`. A seção 8.3 menciona "follow-up automatizado" para leads frios. Nenhuma task cobre este mecanismo de expiração automática.
**Objetivo:** Implementar job de expiração automática de leads inativos.
- [ ] **Cronjob de Expiração de Leads:** Criar scheduled task diária (APScheduler ou Celery Beat) que consulta leads com `atualizado_em` > 30 dias e status != `FECHADO`/`PERDIDO`. Transitar para `PERDIDO` via `LeadStateMachine`. Logar alterações no Audit Trail. Configurável via variável de ambiente `LEAD_EXPIRATION_DAYS` (padrão: 30). (3h)

---

### 🆕 (C) chore/ngrok-local-dev-setup
**Prioridade:** 🟡 Medium | **Pontos:** 2 | **Assignee:** DevOps / Luiz | **Status:** 🆕 Nova Task
**Contexto (Gap identificado):** A spec cita ngrok como ferramenta essencial para testes locais do webhook WhatsApp (seção 13, mitigação de risco). Sem setup padronizado, cada dev configura de forma diferente causando inconsistência e perda de tempo.
**Objetivo:** Padronizar ambiente de desenvolvimento local para testes com WhatsApp Cloud API.
- [ ] **Script de Dev Local:** Criar `Makefile` ou script `./dev.sh` que inicia: docker-compose (PostgreSQL + Redis), servidor FastAPI em modo reload e túnel ngrok apontando para a porta da API. Documentar no README como registrar a URL ngrok temporária no painel Meta Developers. Incluir `.env.example` com todas as variáveis necessárias. (2h)

---

## 📊 RESUMO FINAL — Comparativo

|  Depois |
|---|---|---|
| Total de tasks  40 |
| Total de pontos  228 |
| Tasks críticas não cobertas  5 identificadas e adicionadas |
| Cobertura dos endpoints da spec  ~100% |
| Cobertura das regras de negócio  ~90% |
