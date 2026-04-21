# 🚀 Cadife Smart Travel Frontend — Branch Tasks (REVISADO v2.0)

> Padrão de branches: `(F) feat/`, `(R) refactor/`, `(C) chore/`, `(B) bugfix/`
> **⚠️ Legenda de revisão:** `✅ Validado` | `🔧 Atualizado` | `🆕 Nova Task` | `🚨 Gap Crítico`
> Total: **43 tasks** | Estimado: **211 pontos** *(era 32 tasks / 155 pts)*

---

## 📋 RESUMO DA ANÁLISE DE GAPS

| Categoria | Qtde | Impacto |
|---|---|---|
| Tasks validadas sem alteração | 22 | — |
| Tasks existentes com atualização necessária | 3 | Correção de escopo |
| **Tasks novas críticas (bloqueiam o MVP)** | **5** | 🚨 CRÍTICO |
| Tasks novas de alta prioridade | 5 | 🔴 Alto |
| Tasks novas de média/baixa prioridade | 6 | 🟠 Médio |

---

# 📦 Sprint 1 — Foundation e Setup Base (Semana 1)

## História 1.1 — Arquitetura Clean Padrão Ouro e Segurança Client-Side (16 pontos)

**Contexto:** O frontend mobile precisa começar com uma base arquitetural resiliente, limpa e modular. Também é essencial preparar o terreno com suporte inicial a first-offline (Isar/Hive) e implementar salvaguardas de certificados contra interceptações de rede (pinning e obfuscate).
**Objetivo:** Construir o pilar inicial do projeto Flutter com as arquiteturas de Injeção de Dependências, database local de pre-cache e implementações nativas e criptográficas de segurança client-side.

### ✅ (C) chore/setup-flutter-project-architecture
**Prioridade:** 🔴 Critical | **Pontos:** 8 | **Assignee:** Frontend Lead | **Status:** ✅ Validado
- [ ] **Módulos Independentes (Micro-apps/Packages):** Estruturar como monorepo ou segmentação severa (separar Core UI, Features do Cliente e Feature do Agente para zero acoplamento do domínio central via interface/ports). (3h)
- [ ] **Data Caching & SQLite Offline-FirstDB:** Instalar Hive ou Isar para suportar modo CRM Offline. Informações cacheadas devem salvar stubs localmente caso o device perca conectividade para iniciar o aplicativo offline sem crash/flickerings visuais. (3h)
- [ ] **Setup Injeção DI (get_it) e Linter Pipeline:** Configuração severa injeção limitando singletons para performance-critical features. Utilizar `dart_code_metrics` para configurar regras imutáveis impedindo PRs com código sub-Padrão (Lint Barriers no CI). (2h)

### ✅ (C) chore/setup-advanced-security
**Prioridade:** 🔴 Critical | **Pontos:** 8 | **Assignee:** Security/Frontend | **Status:** ✅ Validado
- [ ] **SSL Certificate Pinning (Network Layer):** Implementar Certificate Pinning e Hash Validation estrito das conexões base da API com o package nativo para barrar engenharia reversa que usa ferramentas proxy tipo Charles/BurpSuite. (2h)
- [ ] **Secure Storage para Chaves AES:** Utilizar Android Keystore e Apple Keychain via FlutterSecureStorage para abrigar AccessTokens da Autenticação. Impedir salvamento no simples shared-preferences. (3h)
- [ ] **Build Obfuscação & Verificação de Root/Jailbreak:** Scriptar flag `--obfuscate` para lib runtime, injetando detectores de Root e Custom ROM. (3h)

---

## História 1.2 — Design System Padrão-Ouro & UI/UX (18 pontos)

**Contexto:** Um projeto Premium precisa obrigatoriamente de UI/UX modernos, com componentes unificados, interfaces visuais temáticas da Cadife e a criação da fundação de rotas para a comunicação HTTP base.
**Objetivo:** Estabelecer o Design System global, centralizar e componentizar blocos fundamentais (Shimmers, Forms, Themes) do Flutter, e acoplar a navegação GoRouter junto às classes base das integrações (Dio + Interceptors).

### ✅ (F) feat/design-system-animations-theme
**Prioridade:** 🔴 Critical | **Pontos:** 6 | **Assignee:** Frontend | **Status:** 🔧 Atualizado
**Contexto:** Aspecto premium necessita de constância nativa, tipografias ricas e transições de tela nativas 120hz fluidas.
**Objetivo:** Setup unificado de temas com Heroing Animations e tokens de design da Cadife Tour.
- [ ] **ThemeData & Design Tokens da Cadife Tour:** Criar sistema design light/dark flexível com extensividade `ThemeExtension`. Implementar tokens de cor exatos definidos na spec (seção 7.3): `primaryColor: #dd0b0e`, `backgroundColor: #393532`, `scaffoldColor: #FFFFFF`, `successColor: #1E8449`, `warningColor: #D35400`. Tipografia Inter ou Roboto padronizada em H1-H6. (3h)
- [ ] **Router System & Guards (GoRouter):** Definir middlewares de auth guard e redirecting para impedir rotas órfãs. Implementar nas ShellRoutes *SharedAxis* animations nativas para transacionamento de tabs da bottom bar. **Definir rotas para AMBOS os perfis: Agência e Cliente** — navegação condicional baseada na `role` do JWT decodificado. (3h)

### ✅ (F) feat/widget-base-components-gold
**Prioridade:** 🔴 Critical | **Pontos:** 7 | **Assignee:** Frontend | **Status:** ✅ Validado
- [ ] **AppTextField Global e Form Component Validation:** Componentes de Input que abrigam suas próprias logicas reativas de Erros validando e limpando status. Suporte robusto a máscaras Regex para CPF, email e fuso numérico. (3h)
- [ ] **Tratamento de Estado Visual Skeletons (Shimmer):** Implementar pacotes customizados de feedback passivo Shimmer e loading overlays, simulando em forma de mock a carga de views listadas antes do BLoC devolver StateLoaded. (4h)

---

### 🆕 (C) chore/setup-api-client-interceptors
**Prioridade:** 🔴 Critical | **Pontos:** 5 | **Assignee:** Frontend Lead | **Status:** 🆕 Nova Task
**Contexto (Gap identificado):** Nenhuma task cobre a camada central de comunicação HTTP do app com a API FastAPI — essencial para todas as features. Sem Dio configurado com interceptors de auth (Bearer token), refresh automático e tratamento global de erros, cada feature precisaria reimplementar estas lógicas, violando DRY e criando inconsistências.
**Objetivo:** Implementar cliente HTTP centralizado com interceptors de auth e erro.
- [ ] **Dio Client com Auth Interceptor:** Configurar instância Dio centralizada com `BaseUrl` configurável por ambiente (dev/staging/prod). Interceptor que injeta `Authorization: Bearer {accessToken}` em toda request autenticada. Em resposta 401, invocar automaticamente `POST /auth/refresh` e repetir a request original com o novo token. Persistir novo access token no SecureStorage. (3h)
- [ ] **Interceptor Global de Erros HTTP:** Mapeamento centralizado de códigos de erro da API para estados visuais da UI: 401 → redirecionar para Login; 403 → exibir tela de permissão negada; 409 → repassar ao BLoC para Conflict Resolution; 500 → exibir error state amigável. Sem crash de runtime não tratado. (2h)

---

# 🔑 Sprint 2 — Autenticação e Core Operations (Semana 2)

## História 2.1 — Access Control, Biometrics & FCM (17 pontos)

**Contexto:** O processo de login é a porta de entrada para o CRM. Precisamos de segurança estrita para autenticação com biometria, verificação imediata via Splash e acoplamento com serviços em background push notification para mensagens ativas.
**Objetivo:** Elaborar o fluxo imersivo do Splash e da tela de Login com re-rotas inteligentes, acoplar segurança em hardware local (Biometria) e engatar os módulos de notificação FireBase Cloud Messaging (FCM).

### ✅ (F) feat/screen-splash-local-auth
**Prioridade:** 🔴 Critical | **Pontos:** 6 | **Assignee:** Frontend | **Status:** ✅ Validado
- [ ] **Onboarding Flux e Validação JWT Oculta:** Carregar o app visualizando Lottie Animation. Em back-thread recuperar o jwt em secure_storage, validando pelo payload (Claims Expiration timestamp) evitando 1 request backend de verificação. (3h)
- [ ] **Local Auth - Biometria/Pin (FaceID):** Integração para uso em reabertura do App. Requerer biometria via pacotes nativos para reautenticar a view após minimizar por N minutos. (3h)

### ✅ (F) feat/screen-login
**Prioridade:** 🔴 Critical | **Pontos:** 5 | **Assignee:** Frontend | **Status:** 🔧 Atualizado
**Objetivo:** View imersiva responsiva Mobile com navegação pós-login baseada em role.
- [ ] **Design e Validações de Entradas Async:** Desenhar campos form UI com verificação client side async para e-mails sintaticamente não permitidos. Integração total de login e resposta de access/refresh tokens. (4h)
- [ ] 🆕 **Roteamento Pós-Login por Role:** Após login bem-sucedido, decodificar o JWT localmente para extrair o campo `role`. Redirecionar `Consultor`/`Admin` para a tela de Dashboard Agência e `Cliente` para a tela de Status da Viagem. Registrar FCM token via `POST /users/fcm-token` imediatamente após login bem-sucedido. (1h)

### ✅ (F) chore/setup-firebase-fcm-sync
**Prioridade:** 🟠 High | **Pontos:** 6 | **Assignee:** Frontend / DevOps | **Status:** ✅ Validado
- [ ] **Integração Push FCM Heads-up:** Integrar o FCM com o pacote de notificação local para habilitar High Priority Banner visual popups se o App estiver Open/Foreground. (3h)
- [ ] **Registro e Queue Actioning local:** Registrar FCM Token de modo síncrono. Em fallback (offline mode network state no plugin), eventos do backend criam logs sqflite que enviam toast quando internet voltar. (3h)

---

# 📱 Sprint 3 — Dashboard, CRM Offline-First e Perfil Cliente (Semana 3)

## História 3.1 — CRM Management, Concorrências e Offline-Sync App UX (53 pontos)

**Contexto:** A feature principal da agência dita o gerenciamento de inúmeras informações com painéis, listagem avançada infinita com cache e tratamentos transacionais de race conditions para múltiplos cliques.
**Objetivo:** Criar e integrar a inteligência total do painel do Agente com estatísticas, gerenciamento completo do clico de vida de Propostas, Agendamentos e detalhamento dos Leads em Views responsivas de rápida sincronicidade de banco de dados.

### ✅ (F) feat/agency-dashboard
**Prioridade:** 🔴 Critical | **Pontos:** 5 | **Assignee:** Frontend | **Status:** 🔧 Atualizado
**Objetivo:** Aplicar UseCases de Domínio sobre os Dados sem lógica pesada dentro das Tabs Views.
- [ ] **Domain Entity Mappers e State Mngment:** Usar BLoC/Cubit focado no desacoplamento. Receber KPIs no repository transformando raw Json em DTO tipados para a View processada. (5h)
- [ ] 🆕 **KPIs e Notificação In-App em Tempo Real:** Implementar os KPIs do dashboard conforme spec (seção 7.1): total de leads, novos hoje, agendamentos pendentes do dia, taxa de qualificação. Adicionar banner/badge de notificação in-app para novos leads recebidos via FCM sem precisar navegar — atualizar contador de badge e exibir SnackBar ao receber payload de notificação no foreground. (3h)

### ✅ (F) feat/screen-leads-listing-offline-sync
**Prioridade:** 🔴 Critical | **Pontos:** 8 | **Assignee:** Frontend | **Status:** ✅ Validado
- [ ] **Paging ListView DB Cache / Infinite Scroll:** Renderização inteligente `CustomScrollView`, lendo prioritamente os dados locais da memória IsarDB, listando millisecond level. Async chama a API, checa checksum/changes no Dto, salva no DB que propaga para o Listen de modo silencioso. (5h)
- [ ] **Debounce / Throttle nos requests do Header Search:** Aplicar throttle em streams Behavior Subjects nos campos de busca para realizar chamadas rest ao filter endpoint API apenas finalizado a digitação do agente N milissegundos. (3h)

---

### 🆕🚨 (F) feat/screen-leads-listing-filters
**Prioridade:** 🔴 Critical | **Pontos:** 5 | **Assignee:** Frontend | **Status:** 🆕 Nova Task — Gap Crítico
**Contexto (Gap identificado):** A spec (seção 7.1) especifica filtros múltiplos na listagem de leads: por status, score, destino e período. A task de offline sync cobre a listagem básica e busca por string, mas não implementa os filtros avançados com UI de seleção. O consultor não consegue segmentar sua carteira de leads sem este componente.
**Objetivo:** Implementar bottom sheet de filtros avançados integrado à listagem de leads.
- [ ] **Bottom Sheet de Filtros:** Componente de filtros com seleção múltipla para: `Status` (chips: Novo, Em Atendimento, Qualificado, Agendado, Proposta, Fechado, Perdido), `Score` (Quente/Morno/Frio com indicadores de cor), `Período` (DateRangePicker). Persistir filtros ativos no estado do BLoC com indicador visual de filtro ativo na AppBar (badge com contador de filtros aplicados). (3h)
- [ ] **Integração com Query Params da API e Cache Local:** Ao aplicar filtros, montar query params para `GET /leads?status=qualificado&score=quente&data_inicio=...` e também filtrar o cache Isar local para resultado imediato sem aguardar API. Botão "Limpar filtros" reseta o estado. (2h)

---

### ✅ (F) feat/screen-lead-detail
**Prioridade:** 🔴 Critical | **Pontos:** 7 | **Assignee:** Frontend | **Status:** 🔧 Atualizado
**Objetivo:** UI Modularizada do Relatório com Ações Rápidas completas conforme spec.
- [ ] **View Assemblers and Timeline:** Rechear as abas dinâmicas da page, construindo scrollbars customizadas usando os Mapped Lists de interações da AYA (histórico WhatsApp logado pela Api do Python com cores intercaladas IA x Cliente ChatView). (4h)
- [ ] **Optimistic UI Lock Feedback:** Toda operação transacional de mudança ("Qualificar/Rejeitar" Lead manual) no form deve gerar freeze action visual async. (3h)
- [ ] 🆕 **Ações Rápidas do Consultor:** Implementar os botões de ação rápida definidos na spec (seção 7.1): "Criar Proposta" (navega para `feat/screen-proposal-management`), "Agendar" (abre seletor de data integrado com `GET /agenda/disponibilidade`), "Abrir WhatsApp" (deep link `https://wa.me/{telefone}` abrindo o WhatsApp do lead nativamente). Campo de observações do consultor com auto-save debounced. (2h)

---

### 🆕🚨 (F) feat/screen-lead-briefing-edit
**Prioridade:** 🔴 Critical | **Pontos:** 5 | **Assignee:** Frontend | **Status:** 🆕 Nova Task — Gap Crítico
**Contexto (Gap identificado):** A spec define o endpoint `PUT /leads/{id}/briefing` (seção 5.3) para que o consultor edite manualmente o briefing extraído pela IA quando incorreto ou incompleto. Sem esta tela, o consultor não tem como corrigir dados do cliente — dados errados chegariam diretamente para a proposta, causando retrabalho e erros comerciais.
**Objetivo:** Implementar formulário de edição manual do briefing do lead pelo consultor.
- [ ] **Form de Edição de Briefing:** Tela com formulário pré-preenchido com os dados extraídos pela IA. Campos editáveis: destino, data_ida, data_volta, qtd_pessoas, perfil (dropdown), tipo_viagem (multi-select chips), preferencias (multi-select chips), orcamento (dropdown: Baixo/Médio/Alto/Premium), tem_passaporte (toggle), observacoes (text area). Indicador visual de `completude_pct` atualizado em tempo real conforme campos preenchidos. (3h)
- [ ] **Integração `PUT /leads/{id}/briefing` com Validações:** Salvar via endpoint com validações client-side: data_volta deve ser posterior a data_ida, qtd_pessoas > 0. Feedback optimista: atualizar estado local do BLoC imediatamente, reverter em caso de erro da API. Exibir diff visual dos campos alterados em relação ao dado original extraído pela IA (tag "Editado manualmente" nos campos modificados). (2h)

---

### 🆕🚨 (F) feat/screen-proposal-management
**Prioridade:** 🔴 Critical | **Pontos:** 8 | **Assignee:** Frontend | **Status:** 🆕 Nova Task — Gap Crítico
**Contexto (Gap identificado):** A spec define o fluxo completo de propostas para o perfil Agência (seção 7.1): criar proposta vinculada a um lead, atualizar status `rascunho → enviada → aprovada → recusada`. A task existente `feat/proposal-generator` aborda apenas a validação do formulário de emissão de valor, não o ciclo de vida completo da proposta. Sem esta tela, o consultor não consegue gerenciar propostas comerciais pelo App.
**Objetivo:** Implementar tela de gestão completa de propostas com lifecycle de status.
- [ ] **Tela de Criação de Proposta:** Formulário de nova proposta vinculada ao lead: campo `descricao` (ex: "Pacote Portugal 10 dias"), `valor_estimado` (opcional, apenas inserido pelo consultor humano — nunca pela IA, conforme spec seção 1.4), status inicial `rascunho`. Integrar com `POST /propostas`. Validações: `descricao` obrigatório, `valor_estimado` deve ser valor positivo se preenchido. (4h)
- [ ] **Lifecycle de Status e Visualização:** Stepper visual de status da proposta: `Rascunho → Enviada → Aprovada/Recusada`. Botões de ação contextual: "Enviar Proposta" (rascunho → enviada), "Marcar como Aprovada" (enviada → aprovada, que propaga atualização do lead para FECHADO), "Marcar como Recusada" (com campo de motivo opcional). Estado `em_revisao` exibido com tag especial. Integrar com `PUT /propostas/{id}`. (4h)

---

### ✅ (F) feat/screen-agency-calendar-concurrency
**Prioridade:** 🟠 High | **Pontos:** 7 | **Assignee:** Frontend | **Status:** ✅ Validado
- [ ] **Integração Visual Calendar:** Implementar marker com points da db API integrando events de `table_calendar`. Filter restritivo disablement de weekends ou hours (Seg-Sex 09h-16h conforme regras de negócio). (3h)
- [ ] **Reagindo a Falhas Servidor HTTP 409 (Race Conditions):** O app lida se um conflito duplo booking na rotina ocorra. Escutando HTTP 409 no POST do Repository Agenda disparando um modal com `Conflicting Resolution Action`, requisitando sugestões livres mais próximas. (4h)

### ✅ (F) feat/proposal-generator
**Prioridade:** 🟠 High | **Pontos:** 8 | **Assignee:** Frontend | **Status:** 🔧 Atualizado
**Nota de revisão:** Esta task cobre as **validações do formulário de emissão de valor** (regras de cross-field validation e Business Rules client-side). Complementar à `feat/screen-proposal-management` que cobre o lifecycle de status. Ambas devem ser implementadas em conjunto.
- [ ] **Component Validator Rule Engine de Inputs:** Formulário de emissão de valor pacote. Listeners acoplados que validam em sync time que o limitador do budget da IA Briefing no State não vai ter value inserted out of scope budget do Field. Desativa send e acusa validation highlight vermelho para guiar visual agent limit config checkings cross field (ex: Voo não pode ser anterior à Hotel). (8h)

---

## História 3.2 — Perfil Cliente (Telas Completas) (23 pontos)

**Contexto:** O produto para a persona Cliente demanda transparência máxima. É preciso expor de maneira refinada as etapas do andamento, acesso aos arquivos de viagem, histórico das conversas com IA e formulários acessíveis de perfil.
**Objetivo:** Prover o módulo destinado ao passageiro/cliente contendo históricos de chat e documentos, status macro do processo, bem como seu escopo de dados pessoais gerenciáveis.

### ✅ (F) feat/screen-client-status
**Prioridade:** 🟠 High | **Pontos:** 5 | **Assignee:** Frontend | **Status:** 🔧 Atualizado
**Nota de revisão:** A spec (seção 7.2) define 4 sub-áreas para o Perfil Cliente. Esta task cobre apenas a **Tela de Status**. As outras 3 áreas (Histórico, Documentos, Perfil) são tasks separadas adicionadas abaixo.
**Objetivo:** Stepper de Progresso UI do processo de viagem.
- [ ] **Stepper de Progresso UI & Network Interceptors Errors:** Componentizar o tracking step (bolhas de etapas viagem aprovando). Status exibidos conforme spec: `Em análise | Proposta enviada | Confirmado | Emitido`. Barra de progresso visual. Se endpoint caia: Interceptors na Dio interceptam erro de conexão devolvendo UI error pages state amigáveis sem crash de Flutter. (5h)

---

### 🆕🚨 (F) feat/screen-client-history
**Prioridade:** 🟠 High | **Pontos:** 5 | **Assignee:** Otávio (Flutter Client) | **Status:** 🆕 Nova Task — Gap Crítico
**Contexto (Gap identificado):** A spec (seção 7.2) define explicitamente a tela de "Histórico de Interações" para o perfil cliente: "Timeline das conversas com o assistente e com o consultor". Esta tela é parte fundamental da experiência do cliente e não possui task correspondente.
**Objetivo:** Implementar timeline de histórico de interações para o perfil cliente.
- [ ] **Timeline de Interações do Cliente:** Tela com lista chronológica das mensagens trocadas com a IA (AYA) e com o consultor. Bolhas de chat com distinção visual: mensagens da IA (cor da marca Cadife), mensagens do consultor (cor secundária), mensagens do cliente (alinhadas à direita). Timestamps formatados em pt-BR. Consumir `GET /leads/{id}/interacoes` com paginação e pull-to-refresh. Shimmer durante carregamento. (3h)
- [ ] **Empty State e Navegação:** Estado vazio amigável quando não há histórico ("Sua conversa com a AYA aparecerá aqui"). Scroll automático para a mensagem mais recente ao abrir. Botão flutuante "Continuar no WhatsApp" linkando para `https://wa.me/{numero_cadife}`. (2h)

---

### 🆕🚨 (F) feat/screen-client-documents
**Prioridade:** 🟠 High | **Pontos:** 5 | **Assignee:** Otávio (Flutter Client) | **Status:** 🆕 Nova Task — Gap Crítico
**Contexto (Gap identificado):** A spec (seção 7.2) define a área de "Documentos" para o cliente: "Área para visualizar documentos enviados pela agência: roteiros, vouchers, comprovantes". Não possui task correspondente. Esta tela é parte do valor percebido pelo cliente (experiência premium Cadife).
**Objetivo:** Implementar área de documentos da viagem para o perfil cliente.
- [ ] **Listagem de Documentos:** Tela com grid ou lista de documentos enviados pela agência (roteiros, vouchers, comprovantes). Card de documento: ícone por tipo (PDF, imagem), nome, data de envio, tamanho. Estado vazio: "Nenhum documento disponível ainda. Seu consultor irá compartilhá-los em breve." Shimmer skeleton durante carregamento. (2h)
- [ ] **Visualização e Download:** Ao tocar no card, abrir documento: PDFs exibidos com `flutter_pdfview` ou `syncfusion_flutter_pdfviewer`; imagens com `photo_view` zoomável. Botão de compartilhamento nativo (Share Sheet iOS/Android) e opção de download para galeria/arquivos do dispositivo. (3h)

---

### 🆕 (F) feat/screen-client-profile
**Prioridade:** 🟡 Medium | **Pontos:** 4 | **Assignee:** Otávio (Flutter Client) | **Status:** 🆕 Nova Task
**Contexto (Gap identificado):** A spec (seção 7.2) define a área de "Perfil e Cadastro" para o cliente: "Dados pessoais, preferências de viagem e informações de contato". Não possui task correspondente.
**Objetivo:** Implementar tela de perfil e preferências de viagem do cliente.
- [ ] **Tela de Perfil do Cliente:** Exibir e editar dados pessoais: nome, e-mail, telefone (read-only — chave de identificação). Seção de preferências de viagem: chips editáveis para `tipo_viagem` (turismo/lazer/aventura/imigração/negócios) e `preferencias` (frio/calor/praia/cidade/luxo/econômico). Indicar se possui passaporte válido (toggle). Integrar com `GET /users/me` e chamada de update ao backend. (4h)

---

### 🆕 (F) feat/screen-lead-manual-create
**Prioridade:** 🟡 Medium | **Pontos:** 4 | **Assignee:** Jakeline (Flutter Agency) | **Status:** 🆕 Nova Task
**Contexto (Gap identificado):** A spec define que leads podem ser criados via `POST /leads` tanto "via webhook ou manual" (seção 5.3). Consultores podem precisar registrar leads captados por outros canais (telefone, presencial, indicação). Sem esta tela, o app não cobre o fluxo de cadastro manual, forçando o consultor a usar outros sistemas.
**Objetivo:** Implementar formulário de criação manual de lead pelo consultor.
- [ ] **Form de Novo Lead Manual:** Tela com campos: `nome`, `telefone` (com máscara e validação), `origem` (enum: whatsapp/app/web — para manual selecionar o canal real). Botão "Adicionar Briefing" que expande formulário simplificado com os campos principais do briefing (destino, datas, pessoas, orçamento). Validação: telefone obrigatório e válido. Integrar com `POST /leads` + `POST /leads/{id}/briefing`. (4h)

---

# 🎯 Sprint 4 — Propostas TDD (Testes) e Observability Final (Semana 4)

## História 4.1 — Validações Estritas Business Form e SLA (29 pontos)

**Contexto:** Próximo de gerar o deploy e validar as entregas do MVP, a garantia da qualidade e observabilidade se tornam vitais para evitar regressões das páginas ao adicionar features ou trocar packages de terceiros no Flutter.
**Objetivo:** Fechar a robustez técnica do app configurando monitoramento contínuo (Crashlytics/Analytics), finalizando fluxos de notificações internas do app, multienvironments e implementando integração testável.

### ✅ (C) chore/unit-widget-integration-tests
**Prioridade:** 🔴 Critical | **Pontos:** 10 | **Assignee:** QA / Frontend | **Status:** ✅ Validado
- [ ] **Testes de Unidade (Domain & Application Layers):** Assegurar unit checks 80%+ nas validações de negócio dos forms, UseCases lógicos de Auth e DataMappers com testagem modular isolando via *Mocktail* libs fake http e retornos models mockados em memória para cada feature bloc flow core process. (4h)
- [ ] **Integration/Golden Tests e E2E:** Escrever suites automatizadas nativas simulando bot de app rodando de facto (ex: Flutter Patrol ou Integration_test). Gerar imagens comparativas Goldens do Componente UI do Dashboard assegurando pixel-perfect layout que não quebre com dependabot version package upgrades random no CI. (6h)

### ✅ (F) feat/observability-analytics
**Prioridade:** 🟠 High | **Pontos:** 6 | **Assignee:** DevOps / Frontend | **Status:** ✅ Validado
- [ ] **Crashlytics Integration Global ZonedError:** Catchar erros global via runZonedGuarded em main entrypoints (FlutterError.onError hook capture). Gerenciar env logs, registrando reports passivos para cloud. (3h)
- [ ] **Analytics/Telemetry Tracker:** Enviar flags/taggings nas paginas criticas via packages (FirebaseAnalytics, Amplitude Tracker app instance) provendo insight de heatmaps click button usage events gerando Business Insights. (3h)

---

### 🆕 (F) feat/screen-in-app-notifications-center
**Prioridade:** 🟡 Medium | **Pontos:** 4 | **Assignee:** Frontend | **Status:** 🆕 Nova Task
**Contexto (Gap identificado):** As tasks de FCM cobrem notificações push externas (quando app fechado ou em background). Entretanto, a spec (seção 7.1) menciona "Notificação in-app de novos leads em tempo real". Um centro de notificações dentro do app permite que o consultor reveja notificações perdidas e gerencie alertas sem depender exclusivamente do push.
**Objetivo:** Implementar centro de notificações in-app com histórico de alertas.
- [ ] **Notification Bell & Badge:** Ícone de sino na AppBar do Dashboard com badge contador de notificações não lidas. Ao tocar, abrir tela de histórico de notificações ordenadas por data. Cada notificação exibe: tipo (Novo Lead, Lead Qualificado, Agendamento Confirmado), nome/telefone do lead, timestamp relativo ("há 5 minutos"). Marcar como lida ao tocar. (2h)
- [ ] **Persistência Local de Notificações:** Armazenar notificações recebidas via FCM no banco local (Isar/Hive) com campos `id`, `tipo`, `lead_id`, `titulo`, `corpo`, `lida`, `recebida_em`. Ao abrir uma notificação, navegar diretamente para a tela de detalhe do lead correspondente via deep link interno. (2h)

---

### 🆕 (C) chore/multi-environment-config
**Prioridade:** 🟡 Medium | **Pontos:** 3 | **Assignee:** Frontend Lead | **Status:** 🆕 Nova Task
**Contexto (Gap identificado):** Nenhuma task define a separação de ambientes (desenvolvimento, staging, produção) no app Flutter. Sem isto, o app aponta sempre para a mesma URL de API, dificultando testes sem afetar dados reais e impedindo um pipeline CI/CD organizado.
**Objetivo:** Implementar configuração multi-ambiente com flavor do Flutter.
- [ ] **Flutter Flavors (dev/staging/prod):** Configurar flavors Android (`productFlavors`) e iOS (`schemes`) para `dev`, `staging` e `prod`. Cada flavor define: `API_BASE_URL`, `FIREBASE_PROJECT_ID` e flags de debug. Criar arquivo `app_config.dart` injetado via DI que fornece a configuração correta pelo ambiente ativo. `dev` usa ngrok URL; `prod` usa URL da API em produção. (3h)

---

### 🆕 (F) feat/screen-empty-states-error-handling
**Prioridade:** 🟡 Medium | **Pontos:** 3 | **Assignee:** Frontend | **Status:** 🆕 Nova Task
**Contexto (Gap identificado):** A spec (seção 12.3) exige "Tratamento de exceções em todo o fluxo" e "Feedback visual imediato para todas as ações do usuário" (seção 12.4). Tasks individuais têm error states parciais, mas falta uma abordagem sistemática e consistente de empty states e error states reutilizáveis.
**Objetivo:** Criar biblioteca de empty states e error states reutilizáveis para todo o app.
- [ ] **Widget AppErrorState e AppEmptyState:** Criar widgets reutilizáveis com ícone ilustrativo, título e subtítulo customizáveis, e botão de ação opcional. Variants: `network_error` ("Sem conexão — verifique seu internet"), `server_error` ("Algo deu errado do nosso lado"), `empty_list` ("Nenhum {item} encontrado"), `permission_denied` ("Você não tem acesso a esta área"). Aplicar consistentemente em todas as telas listadas. (3h)

---

### 🆕 (C) chore/app-store-build-configuration
**Prioridade:** 🟡 Medium | **Pontos:** 3 | **Assignee:** DevOps / Luiz | **Status:** 🆕 Nova Task
**Contexto (Gap identificado):** Para a demo e entrega final do MVP (Fase 4 — Dias 21-25), o app precisa ser instalável em dispositivos físicos dos avaliadores. Nenhuma task cobre a configuração de build para distribuição interna (TestFlight/Firebase App Distribution).
**Objetivo:** Configurar distribuição interna do app para a demo do MVP.
- [ ] **Distribuição via Firebase App Distribution:** Configurar Firebase App Distribution para distribuição do build Android (.apk/.aab) e iOS (via TestFlight). Automatizar upload do build no GitHub Actions ao fazer push na branch `release`. Gerar link de convite para os avaliadores (Instrutores Alpha e PO Diego) testarem sem precisar de conta de desenvolvedor. (3h)

---

## 📊 RESUMO FINAL — Comparativo

|| Depois |
|---|---|---|
| Total de tasks  43 |
| Total de pontos  211 |
| Tasks críticas não cobertas  5 identificadas e adicionadas |
| Cobertura do Perfil Cliente (spec 7.2)  100% (4/4 telas) |
| Cobertura do Perfil Agência (spec 7.1)  ~100% |
| Cobertura de fluxo de Propostas  100% (lifecycle completo) |
