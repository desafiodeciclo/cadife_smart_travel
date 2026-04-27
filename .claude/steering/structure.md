# Cadife Smart Travel — Structure Steering

## Topologia do Monorepo

```text
cadife_smart_travel/                    ← raiz do repositório
│
├── backend/                            ← API FastAPI + IA + WhatsApp
│   ├── app/
│   │   ├── routes/
│   │   │   ├── webhook.py              ← GET/POST /webhook/whatsapp
│   │   │   ├── leads.py                ← CRUD /leads + /leads/{id}/briefing
│   │   │   ├── ia.py                   ← /ia/processar, /ia/extrair-briefing
│   │   │   ├── agenda.py               ← /agenda (disponibilidade + CRUD)
│   │   │   ├── propostas.py            ← /propostas CRUD
│   │   │   └── auth.py                 ← /auth/login, /auth/refresh, /users
│   │   ├── services/
│   │   │   ├── ai_service.py           ← LangChain chain principal (AYA)
│   │   │   ├── rag_service.py          ← ChromaDB / PGVector indexação e retrieval
│   │   │   ├── whatsapp_service.py     ← Envio de mensagens via Meta API
│   │   │   ├── fcm_service.py          ← Firebase Admin SDK push notifications
│   │   │   └── lead_service.py         ← Lógica de negócio leads + score
│   │   ├── models/
│   │   │   ├── lead.py                 ← Lead, LeadCreate, LeadUpdate (Pydantic + SQLModel)
│   │   │   ├── briefing.py             ← Briefing, BriefingExtracted
│   │   │   ├── interaction.py          ← Interaction (histórico de conversa)
│   │   │   ├── scheduling.py           ← Agendamento
│   │   │   ├── proposal.py             ← Proposta
│   │   │   └── user.py                 ← User, UserCreate, Token
│   │   └── core/
│   │       ├── config.py               ← Settings via pydantic-settings
│   │       ├── database.py             ← AsyncSession, engine, get_db dependency
│   │       ├── security.py             ← JWT create/verify, password hash
│   │       └── dependencies.py         ← get_current_user, rate_limiter
│   ├── tests/
│   │   ├── test_webhook.py
│   │   ├── test_leads.py
│   │   └── test_ai.py
│   ├── main.py                         ← FastAPI app + lifespan + routers
│   ├── requirements.txt
│   └── Dockerfile
│
├── frontend_flutter/                   ← App Flutter (Agency + Client profiles)
│   ├── lib/
│   │   ├── core/
│   │   │   ├── theme/
│   │   │   │   ├── app_colors.dart     ← Constantes de cor (primaryColor #dd0b0e, etc.)
│   │   │   │   ├── app_theme.dart      ← ThemeData da Cadife Tour
│   │   │   │   └── app_text_styles.dart
│   │   │   ├── router/
│   │   │   │   └── app_router.dart     ← GoRouter + auth guards
│   │   │   └── constants/
│   │   │       └── api_constants.dart  ← BASE_URL e paths dos endpoints
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── auth_notifier.dart  ← Riverpod provider
│   │   │   │   └── auth_repository.dart
│   │   │   ├── agency/
│   │   │   │   ├── dashboard/          ← KPIs, resumo do dia, notificações
│   │   │   │   ├── leads/              ← Lista leads, filtros, busca
│   │   │   │   ├── lead_detail/        ← Briefing, histórico, ações rápidas
│   │   │   │   ├── agenda/             ← Calendário e CRUD de agendamentos
│   │   │   │   └── proposals/          ← Criação e gestão de propostas
│   │   │   └── client/
│   │   │       ├── trip_status/        ← Status visual da viagem (barra de progresso)
│   │   │       ├── interactions/       ← Timeline de conversas
│   │   │       ├── documents/          ← Visualização de roteiros, vouchers
│   │   │       └── profile/            ← Dados pessoais e preferências
│   │   ├── services/
│   │   │   ├── api_service.dart        ← Dio client + interceptors JWT
│   │   │   └── notification_service.dart ← FCM listener + local notifications
│   │   └── main.dart
│   ├── test/
│   └── pubspec.yaml
│
├── docs/                               ← Documentação humana (fonte da verdade)
│   ├── brief.md                        ← Resumo executivo do produto
│   ├── requirements/                   ← EARS requirements (REQ-XXX)
│   ├── design/                         ← Arquitetura, IA/RAG, Flutter screens
│   ├── contracts/                      ← Schemas JSON da API (contratos frontend-backend)
│   ├── tasks/                          ← Detalhamento das sprints para o time
│   ├── adr/                            ← Architecture Decision Records
│   └── bugs/                           ← Relatórios de bugs com trace
│
├── specs/                              ← SDD: controle de progresso do agente
│   ├── pending/                        ← Tasks aguardando execução (JSON)
│   ├── active/                         ← Task em execução agora (máx. 1 por vez)
│   └── done/                           ← Tasks concluídas (histórico auditável)
│
├── docker/
│   └── docker-compose.yml              ← backend + postgres + chromadb
│
├── .claude/                            ← Configuração do agente Claude Code
│   ├── steering/                       ← Diretrizes macro (product, tech, structure)
│   ├── rules/                          ← Regras por camada (backend, flutter, ai)
│   ├── agents/                         ← Sub-agentes especializados por role
│   └── skills/                         ← Comandos customizados /slash
│
├── CLAUDE.md                           ← Constituição do agente (LEIA PRIMEIRO)
├── TUTORIAL_ARQUITETURA.md             ← Guia de onboarding do SDD para novos devs
├── spec.md                             ← Especificação técnica completa do projeto
└── .env.example                        ← Template das variáveis de ambiente

```

## Fronteiras de Camada (Não Cruzar)

- **Backend → Frontend:** apenas via REST API (JSON) ou FCM push — sem imports diretos.
- **Services → Routes:** services não importam de `routes/` — dependência unidirecional.
- **AI Service → DB:** `ai_service.py` não acessa o banco diretamente — usa `lead_service.py`.
- **Flutter Features → API:** features não usam `dio` diretamente — sempre via `api_service.dart`.
- **Tema → Widgets:** widgets nunca declaram `Color(0xff...)` — sempre `AppColors.*`.

## Convenções de Nomenclatura

| Contexto | Padrão | Exemplo |
|---|---|---|
| Arquivos Python | `snake_case.py` | `lead_service.py` |
| Arquivos Dart | `snake_case.dart` | `lead_detail_screen.dart` |
| Classes Python/Dart | `PascalCase` | `LeadService`, `LeadDetailScreen` |
| Funções/métodos Python | `snake_case` | `get_lead_by_phone()` |
| Métodos Dart | `camelCase` | `fetchLeadById()` |
| Providers Riverpod | `camelCase + Provider` | `leadsProvider`, `leadDetailProvider` |
| Endpoints API | `kebab-case` | `/ia/extrair-briefing` |
| Campos DB / Pydantic | `snake_case` | `completude_pct`, `data_ida` |

## Diretório Especial — SDD

O controle do agente opera nas pastas `.claude/` e `specs/`. Alterar a arquitetura macro (ex: trocar banco, adicionar serviço) requer:
1. Criar ADR em `docs/adr/` documentando a decisão
2. Atualizar este arquivo `structure.md`
3. Criar spec JSON em `specs/pending/` para implementação
