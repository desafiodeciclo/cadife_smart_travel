# Cadife Smart Travel — Tech Steering

## Stack Tecnológico Completo

| Camada | Tecnologia | Versão Alvo | Justificativa |
|---|---|---|---|
| Backend / API | FastAPI + Python | Python 3.11+ | Performance assíncrona, Pydantic v2, ecossistema IA |
| IA / Orquestração | LangChain + OpenAI GPT | langchain 0.2+ | RAG, extração de entidades, memória de conversação |
| Vector DB (dev) | ChromaDB | chromadb 0.5+ | Persistência local simples para desenvolvimento |
| Vector DB (prod) | PGVector | pgvector 0.7+ | Integrado ao PostgreSQL, sem infra extra |
| Banco de Dados | PostgreSQL | 15+ | ACID, suporte PGVector, SQLModel/SQLAlchemy |
| App Mobile | Flutter + Dart | Flutter 3.19+ | Multiplataforma, single codebase, performance nativa |
| Notificações Push | Firebase FCM | firebase-admin 6+ | Entrega confiável Android/iOS, integração FCM |
| Autenticação API | JWT | python-jose + passlib | Stateless, access 1h / refresh 7d |
| Autenticação App | Firebase Auth | firebase_auth 4+ | E-mail, Google, OTP — gerenciado pelo Firebase |
| Infra / Deploy | Docker + Docker Compose | Docker 24+ | Portabilidade, LXC-compatível |
| CI/CD | GitHub Actions | — | Monorepo, pull requests, deploy automatizado |
| Dev local webhook | ngrok | — | Expõe localhost para Meta Cloud API |

## Padrões de Código — Backend Python

### Estrutura de Arquivos
```
backend/
├── app/
│   ├── routes/          # Um arquivo por domínio: webhook.py, leads.py, auth.py, agenda.py
│   ├── services/        # ai_service.py, rag_service.py, whatsapp_service.py, fcm_service.py
│   ├── models/          # lead.py, briefing.py, user.py, interaction.py (Pydantic + SQLModel)
│   └── core/            # config.py, security.py, database.py, dependencies.py
├── tests/               # test_webhook.py, test_leads.py, test_ai.py
├── main.py              # FastAPI app, routers registrados, lifespan
├── requirements.txt
└── Dockerfile
```

### Convenções Obrigatórias
- `async def` em todos os route handlers e chamadas I/O (DB, HTTP externo, IA)
- `BackgroundTasks` para processamento IA — webhook SEMPRE retorna 200 antes da IA processar
- Pydantic v2 `BaseModel` para todos os schemas (entrada, saída e DB)
- `Optional[X] = None` para campos não obrigatórios nos schemas
- Logger estruturado: campos `timestamp`, `endpoint`, `action`, `lead_id` (quando disponível)
- Variáveis de ambiente via `pydantic-settings` — classe `Settings` em `app/core/config.py`
- `HTTPException` para todos os erros HTTP públicos; nunca expor stacktrace ao cliente

### Dependências Obrigatórias (requirements.txt base)
```
fastapi>=0.111.0
uvicorn[standard]>=0.29.0
pydantic>=2.7.0
pydantic-settings>=2.2.0
sqlmodel>=0.0.18
asyncpg>=0.29.0
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
langchain>=0.2.0
langchain-openai>=0.1.0
langchain-chroma>=0.1.0
chromadb>=0.5.0
firebase-admin>=6.5.0
httpx>=0.27.0
python-multipart>=0.0.9
```

## Padrões de Código — Flutter/Dart

### Estrutura de Arquivos
```
frontend_flutter/
├── lib/
│   ├── core/
│   │   ├── theme/          # app_colors.dart, app_theme.dart, app_text_styles.dart
│   │   ├── router/         # app_router.dart (GoRouter + guards)
│   │   └── constants/      # api_constants.dart, app_constants.dart
│   ├── features/
│   │   ├── auth/           # login_screen.dart, auth_notifier.dart, auth_repo.dart
│   │   ├── agency/         # dashboard/, leads/, lead_detail/, agenda/, proposals/
│   │   └── client/         # trip_status/, interactions/, documents/, profile/
│   ├── services/
│   │   ├── api_service.dart          # Dio client, interceptors JWT
│   │   └── notification_service.dart # FCM listener e setup
│   └── main.dart
├── test/
└── pubspec.yaml
```

### Convenções Obrigatórias
- `AsyncNotifierProvider` para dados remotos (leads, briefings, agendamentos)
- `StateProvider` para estados de UI locais (filtros, toggles)
- Repositório pattern: `*_repo.dart` abstrai chamadas HTTP — providers nunca chamam Dio diretamente
- Todas as cores via `AppColors.primary`, `AppColors.background` — **nunca** hex hardcoded nos widgets
- `GoRouter` para navegação, guards de auth no `redirect` do router
- `try/catch` em todos os métodos de repositório; erros propagados como `AsyncError` no provider

### Dependências Obrigatórias (pubspec.yaml base)
```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^13.0.0
  dio: ^5.4.0
  firebase_core: ^2.27.0
  firebase_auth: ^4.17.0
  firebase_messaging: ^14.8.0
  flutter_local_notifications: ^17.1.0
  shared_preferences: ^2.2.0
  intl: ^0.19.0
```

## SLAs Obrigatórios (Requisitos Não Funcionais)

| Métrica | SLA | Onde garantir |
|---|---|---|
| Resposta webhook Meta | ≤ 5 segundos (HTTP 200) | `BackgroundTasks` no handler do webhook |
| Resposta IA ao cliente WhatsApp | ≤ 3 segundos | Processamento assíncrono + timeout no LLM |
| Notificação push ao consultor | ≤ 2 segundos após evento | FCM trigger imediato pós-criação do lead |
| Carregamento dashboard Flutter | ≤ 1,5 segundos | Paginação + cache local |
| Atualização app após WhatsApp msg | ≤ 2 segundos | FCM → Flutter listener |

## Variáveis de Ambiente (.env)

```bash
# Meta / WhatsApp Cloud API
WHATSAPP_TOKEN=          # Token de acesso permanente Meta
PHONE_NUMBER_ID=         # ID do número registrado na Meta
VERIFY_TOKEN=            # Token para challenge do webhook

# IA
OPENAI_API_KEY=          # Chave OpenAI (GPT-4o ou GPT-4o-mini)
LANGCHAIN_API_KEY=       # LangSmith (opcional, para observabilidade)

# Banco de Dados
DATABASE_URL=            # postgresql+asyncpg://user:pass@host:5432/cadife

# Autenticação
JWT_SECRET_KEY=          # Chave aleatória ≥ 32 chars para JWT

# Firebase
FIREBASE_CREDENTIALS=   # Caminho para firebase-service-account.json

# ChromaDB (dev local)
CHROMA_PERSIST_DIR=./chroma_db

# Ambiente
DEBUG=false              # true apenas em desenvolvimento local
```

## Segurança

- Validar `X-Hub-Signature-256` no webhook antes de processar qualquer payload
- Rate limiting: 100 req/min no webhook, 30 req/min nos endpoints de IA
- CORS configurado explicitamente — sem wildcard em produção
- Tokens JWT: access token 1h, refresh token 7d, rotação obrigatória
- Arquivo `firebase-service-account.json` no `.gitignore` — nunca commitado
