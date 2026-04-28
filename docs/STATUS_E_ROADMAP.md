# Status do Projeto & Roadmap de Correções — Cadife Smart Travel

> Gerado em: 2026-04-27 | Branch: developer

Este documento mapeia tudo que está faltando ou quebrado no projeto e define a ordem de execução para chegar ao estado "rodando por completo". Leia do início ao fim antes de tocar qualquer arquivo.

---

## Índice

1. [Visão Geral do Estado Atual](#1-visão-geral-do-estado-atual)
2. [Bloqueadores Críticos — Impedem o projeto de sequer iniciar](#2-bloqueadores-críticos)
3. [Fase 1 — Fundação (Backend roda localmente)](#3-fase-1--fundação-backend-roda-localmente)
4. [Fase 2 — Banco de Dados e Migrações](#4-fase-2--banco-de-dados-e-migrações)
5. [Fase 3 — Camada de Negócio e IA](#5-fase-3--camada-de-negócio-e-ia)
6. [Fase 4 — Flutter: Consolidação Arquitetural](#6-fase-4--flutter-consolidação-arquitetural)
7. [Fase 5 — Flutter: Telas Faltando](#7-fase-5--flutter-telas-faltando)
8. [Fase 6 — Integração End-to-End](#8-fase-6--integração-end-to-end)
9. [Fase 7 — Testes](#9-fase-7--testes)
10. [Fase 8 — Infra e Segurança](#10-fase-8--infra-e-segurança)
11. [Resumo Executivo por Camada](#11-resumo-executivo-por-camada)

---

## 1. Visão Geral do Estado Atual

| Camada | Estado | Detalhes |
|---|---|---|
| Backend (FastAPI) | 🔴 NÃO RODA | `main.py` tem sintaxe inválida; requirements incompleto; models duplicados; settings duplicadas |
| Banco de Dados (PostgreSQL) | 🟡 PARCIAL | Migration existe mas não cria tabela `users`; FKs órfãs |
| IA / RAG (AYA) | 🟡 PARCIAL | Código existe; `OPENAI_API_KEY` é placeholder; ChromaDB desconectado do docker |
| WhatsApp Webhook | 🟡 PARCIAL | Lógica existe; token real vazado no repo; falta tratamento de áudio/status |
| Flutter App | 🟠 INCOMPLETO | Dois sistemas de auth coexistindo; `main.dart` com imports duplicados; 6 telas são placeholders |
| Docker / Infra | 🔴 FALTA Redis | Rate limiter não funciona sem Redis no compose |
| Testes | 🔴 CRÍTICO | Quase nenhum teste de funcionalidade; `test_services/` e `test_use_cases/` vazios |
| Segurança | 🔴 INCIDENTE | `.env` com tokens reais está versionado no repositório |

---

## 2. Bloqueadores Críticos

> **Execute estes itens primeiro.** Sem eles, nenhuma outra parte do projeto funciona.

### 🔴 B1 — `backend/main.py` tem sintaxe Python inválida

**O problema:**
O bloco de registro do `CORSMiddleware` (linhas ~85-101) não fecha o parêntese antes de abrir outro `app.add_middleware`. O Python não consegue fazer o parse do arquivo — a aplicação não inicia de forma alguma.

```python
# CÓDIGO QUEBRADO (como está hoje):
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: restringir em produção
# ── Middleware Registration ────
app.add_middleware(RequestIdMiddleware)  # <- parêntese do anterior nunca fechou!
```

**O que fazer:**
- Abrir `backend/main.py`
- Localizar a chamada do `CORSMiddleware`
- Garantir que ela está completa com todos os parâmetros fechados antes do próximo `app.add_middleware`
- Remover a declaração duplicada do CORS (aparece duas vezes no arquivo)

---

### 🔴 B2 — Credenciais reais versionadas no repositório

**O problema:**
O arquivo `backend/.env` está no git com tokens reais:
- `WHATSAPP_TOKEN=EAALL5eEU...` — token de produção do Meta WhatsApp
- `GEMINI_API_KEY=AIzaSyBOzUypP09_...` — chave real da Google

**O que fazer:**
1. Revogar imediatamente os tokens vazados nos painéis do Meta for Developers e Google Cloud Console
2. Adicionar `backend/.env` ao `.gitignore` (verificar se já está; se não, adicionar)
3. Remover o arquivo do histórico git com `git rm --cached backend/.env`
4. Criar novo `.env` local a partir do `backend/.env.example` com os novos tokens
5. Nunca comitar `.env` novamente — apenas `.env.example` com placeholders

---

### 🔴 B3 — Modelos SQLAlchemy duplicados (conflito de `__tablename__`)

**O problema:**
Existem dois conjuntos de modelos SQLAlchemy declarando os mesmos `__tablename__`:

- `backend/app/models/lead.py` → `__tablename__ = "leads"` (versão legada, usa `EncryptedString`)
- `backend/app/infrastructure/persistence/models/lead_model.py` → `__tablename__ = "leads"` (versão Clean Architecture)

Idem para `briefings`, `interacoes`, `agendamentos`, `propostas`. Quando ambos são importados (direta ou indiretamente), o SQLAlchemy lança `InvalidRequestError` ou o segundo sobrescreve silenciosamente o primeiro.

**O que fazer:**
Decidir qual conjunto manter. A recomendação é **manter apenas** `app/infrastructure/persistence/models/` (versão Clean Architecture) e:
1. Remover ou renomear os arquivos em `backend/app/models/` para não serem importados (ex: mover para `_legacy/`)
2. Atualizar todos os imports nos serviços (`lead_service.py` importa de `app.models.lead`)
3. Atualizar o `migrations/env.py` para importar apenas dos models de infrastructure

---

### 🔴 B4 — Settings duplicadas com campos disjuntos

**O problema:**
Existem duas classes `Settings` independentes:
- `app/core/config.py` — tem `REDIS_URL`, `RATE_LIMIT_*`, `ENCRYPTION_KEY`
- `app/infrastructure/config/settings.py` — tem `APP_ENV`, `WEBHOOK_TIMEOUT_SECONDS`, `REQUEST_TIMEOUT_SECONDS`

O `main.py` importa `get_settings` dos dois arquivos no mesmo namespace — o segundo sobrescreve o primeiro. Módulos que precisam de `REDIS_URL` (`rate_limiter.py`) e `ENCRYPTION_KEY` (`pii_encryption.py`) ficam sem esses campos dependendo da ordem de importação.

**O que fazer:**
1. Criar uma única classe `Settings` em `app/infrastructure/config/settings.py` com **todos** os campos dos dois arquivos
2. Deletar `app/core/config.py` ou transformá-lo em um alias que importa de `settings.py`
3. Atualizar todos os imports no projeto para apontarem para um único lugar
4. Garantir que o `.env.example` contenha todas as variáveis

---

### 🔴 B5 — `requirements.txt` incompleto (backend não instala)

**O problema:**
Os seguintes pacotes são usados no código mas não estão declarados em `backend/requirements.txt`:

| Pacote | Usado em |
|---|---|
| `structlog` | Todos os módulos (logging estruturado) |
| `slowapi` | `infrastructure/security/rate_limiter.py` |
| `cryptography` | `infrastructure/security/pii_encryption.py` (Fernet) |
| `alembic` | Migrations |
| `langchain-openai` | `services/ai_service.py`, `services/rag_service.py` |
| `langchain-community` | `services/rag_service.py` (ChromaDocumentLoader) |
| `redis` | Exigido pelo slowapi com Redis backend |
| `argon2-cffi` | `infrastructure/security/jwt.py` (Argon2 para hash de senha) |

**O que fazer:**
1. Adicionar todos os pacotes listados acima ao `requirements.txt` com versões fixas
2. Rodar `pip install -r requirements.txt` em ambiente limpo para validar
3. Commitar o arquivo atualizado

---

### 🔴 B6 — `docker-compose.yml` sem serviço Redis

**O problema:**
O `rate_limiter.py` tenta conectar em `REDIS_URL=redis://localhost:6379/0`. O `docker-compose.yml` em `docker/` sobe apenas `backend`, `postgres` e `chromadb` — sem Redis. O backend falha ao iniciar quando `swallow_errors=False` no slowapi.

**O que fazer:**
Adicionar ao `docker/docker-compose.yml`:
```yaml
redis:
  image: redis:7-alpine
  ports:
    - "6379:6379"
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
```
E adicionar dependência `depends_on: [redis]` no serviço `backend`.

---

### 🔴 B7 — `main.dart` (Flutter) com imports duplicados

**O problema:**
O arquivo `frontend_flutter/lib/main.dart` tem blocos de imports repetidos (linhas 8-17 e 18-22 importam os mesmos providers duas vezes, alguns com alias conflitante). Flutter/Dart não compila com imports duplicados do mesmo path.

**O que fazer:**
1. Abrir `frontend_flutter/lib/main.dart`
2. Consolidar os imports, removendo duplicações
3. Rodar `flutter analyze` para confirmar que não há mais erros de compilação

---

### 🔴 B8 — Tabela `users` sem migration

**O problema:**
A migration `dd4f06e3dc70` cria `leads`, `briefings`, `interacoes`, `agendamentos` e `propostas` — todas com FK para a coluna `users.id`. Mas a tabela `users` **não é criada em nenhuma migration**. Rodar `alembic upgrade head` falha com `ForeignKeyViolation`.

**O que fazer:**
1. Criar modelo `app/infrastructure/persistence/models/user_model.py` seguindo o padrão dos outros modelos
2. Criar nova migration: `alembic revision --autogenerate -m "create_users_table"`
3. Garantir que a migration de `users` seja executada **antes** da `dd4f06e3dc70` (ajustar `down_revision`)
4. Criar também `app/infrastructure/persistence/repositories/users_repository.py`

---

## 3. Fase 1 — Fundação (Backend roda localmente)

> **Pré-requisito:** Todos os Bloqueadores Críticos (seção 2) resolvidos.
> **Meta:** `uvicorn main:app --reload` iniciar sem erros.

### Passo 1.1 — Corrigir `main.py`

Após corrigir a sintaxe (B1), verificar também:
- [ ] Remover a importação duplicada de `get_settings` (dois paths diferentes)
- [ ] Remover a importação duplicada de `create_tables`
- [ ] O `lifespan` usa `create_tables()` — confirmar que chama a função que usa os models de infrastructure (não os legados)
- [ ] CORS: configurar `allow_origins` a partir das settings (não hardcoded `["*"]`)

### Passo 1.2 — Unificar Settings

Após resolver B4:
- [ ] `app/infrastructure/config/settings.py` deve ter todos os campos:
  - `DATABASE_URL`, `ASYNC_DATABASE_URL`
  - `JWT_SECRET_KEY`, `JWT_ALGORITHM`, `ACCESS_TOKEN_EXPIRE_MINUTES`, `REFRESH_TOKEN_EXPIRE_DAYS`
  - `OPENAI_API_KEY`
  - `WHATSAPP_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_VERIFY_TOKEN`
  - `FIREBASE_CREDENTIALS_PATH`
  - `REDIS_URL`, `RATE_LIMIT_PER_MINUTE`, `RATE_LIMIT_PER_HOUR`
  - `ENCRYPTION_KEY`
  - `APP_ENV`, `DEBUG`, `REQUEST_TIMEOUT_SECONDS`, `WEBHOOK_TIMEOUT_SECONDS`
- [ ] Todos os módulos (`rate_limiter.py`, `pii_encryption.py`, `firebase.py`, `jwt.py`) importam de `app.infrastructure.config.settings`

### Passo 1.3 — Corrigir `requirements.txt`

Adicionar os pacotes faltantes (B5) e também verificar versões compatíveis entre si para:
- `langchain`, `langchain-openai`, `langchain-community`, `langchain-chroma`
- `openai`
- `pydantic`, `pydantic-settings`
- `python-jose[cryptography]` (JWT) ou `pyjwt`
- `passlib[argon2]` (hash de senha)

Rodar em ambiente limpo:
```bash
python -m venv venv_test && source venv_test/bin/activate
pip install -r requirements.txt
python -c "from app.main import app; print('OK')"
```

### Passo 1.4 — `.env` local funcional

Criar `backend/.env` com valores reais ou de desenvolvimento:
- [ ] `OPENAI_API_KEY` com chave válida (ou usar conta de teste com créditos)
- [ ] `JWT_SECRET_KEY` com string forte (mínimo 32 chars)
- [ ] `ENCRYPTION_KEY` gerado via `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`
- [ ] `DATABASE_URL` apontando para Postgres local ou Docker
- [ ] `REDIS_URL=redis://localhost:6379/0`
- [ ] Tokens WhatsApp como placeholder (bot não vai funcionar sem conta Meta real)

### Passo 1.5 — Validar startup

```bash
cd backend
source venv/bin/activate
uvicorn main:app --reload
# Esperado: "Application startup complete."
# Acessar: http://localhost:8000/health → {"status": "healthy"}
# Acessar: http://localhost:8000/docs → Swagger UI com todos os routers
```

---

## 4. Fase 2 — Banco de Dados e Migrações

> **Pré-requisito:** Fase 1 concluída.
> **Meta:** `alembic upgrade head` funcionar sem erros; todas as tabelas criadas.

### Passo 2.1 — Criar modelo `UserModel`

Criar `backend/app/infrastructure/persistence/models/user_model.py`:
```python
# Campos mínimos: id (UUID), email, hashed_password, role (ENUM: admin/consultor/agencia), 
# nome, fcm_token, is_active, created_at, updated_at
```
Seguir o padrão dos outros modelos (type hints, índices, timestamps automáticos).

### Passo 2.2 — Ajustar `migrations/env.py`

Garantir que `target_metadata` importa **apenas** os modelos de `app/infrastructure/persistence/models/`:
```python
from app.infrastructure.persistence.models.user_model import UserModel
from app.infrastructure.persistence.models.lead_model import LeadModel
# ... etc (NÃO importar de app.models.*)
```

### Passo 2.3 — Criar migration para `users`

```bash
alembic revision --autogenerate -m "create_users_table"
```
Verificar o arquivo gerado:
- [ ] A migration de `users` deve vir **antes** (menor timestamp) que a migration de `leads`
- [ ] Deve incluir `alembic downgrade` funcional

### Passo 2.4 — Criar `UsersRepository`

Criar `backend/app/infrastructure/persistence/repositories/users_repository.py`:
- `get_by_id(user_id: UUID) -> UserModel | None`
- `get_by_email(email: str) -> UserModel | None`
- `create(email, hashed_password, role, nome) -> UserModel`
- `update_fcm_token(user_id, token) -> None`

### Passo 2.5 — Criar endpoint de seed/criação de usuário admin

Como não existe rota para criar usuários, e o login exige usuário pré-existente, criar pelo menos:
- Script `backend/scripts/create_admin.py` que insere o primeiro usuário admin via linha de comando
- **OU** endpoint `POST /users` protegido por `role=admin` (bootstrap: primeiro usuário criado se banco vazio)

### Passo 2.6 — Validar banco

```bash
alembic upgrade head
# Conferir no psql:
# \dt → deve listar: users, leads, briefings, interacoes, agendamentos, propostas
```

---

## 5. Fase 3 — Camada de Negócio e IA

> **Pré-requisito:** Fases 1 e 2 concluídas.
> **Meta:** Webhook WhatsApp processa mensagem → IA responde → dado persiste no banco.

### Passo 3.1 — Resolver conflito de serviços duplicados

O `lead_service.py` importa do modelo legado (`app.models.lead`). Após eliminar os modelos legados (B3):
- [ ] Atualizar `lead_service.py` para importar de `app.infrastructure.persistence.models.lead_model`
- [ ] Atualizar `user_service.py` para usar `UsersRepository` (Fase 2.4)
- [ ] Verificar `ai_service.py`, `whatsapp_service.py`, `fcm_service.py` — se importam dos modelos legados, atualizar

### Passo 3.2 — Verificar e completar repositórios

Inspecionar cada arquivo em `app/infrastructure/persistence/repositories/`:
- [ ] `briefing_repository.py` — implementado? Se não, implementar os métodos da interface
- [ ] `interacao_repository.py` — idem
- [ ] `agendamento_repository.py` — idem
- [ ] `proposta_repository.py` — idem

Cada repositório deve implementar os métodos declarados em `app/domain/interfaces/repositories.py`.

### Passo 3.3 — Conectar repositórios aos routes (Injeção de Dependência)

Atualmente, as rotas usam diretamente os services com SQLAlchemy. Para seguir a arquitetura limpa definida:
- [ ] Em `app/infrastructure/security/dependencies.py` (ou novo `app/core/dependencies.py`): criar funções `get_lead_repository()`, `get_briefing_repository()` etc. usando `Depends`
- [ ] Atualizar os handlers das rotas para receber repositórios via `Depends` em vez de sessions diretas

> **Nota:** Esta é uma refatoração de médio porte. Se o prazo for curto, pode ser feita incrementalmente — priorizar `leads` primeiro, depois os demais.

### Passo 3.4 — Configurar IA (OpenAI + RAG)

- [ ] Garantir `OPENAI_API_KEY` válida no `.env`
- [ ] Testar `rag_service.py`: `python -c "from app.services.rag_service import RAGService; r = RAGService(); print(r.query('o que a Cadife oferece?'))"`
- [ ] Se ChromaDB for usar o container Docker (`docker-compose`), atualizar `rag_service.py` para usar o host do container (`http://chromadb:8000`) em vez de `./chroma_db` local

### Passo 3.5 — Implementar job de leads inativos

Leads sem resposta por 30 dias devem ir para status `PERDIDO`. Não há nenhum scheduler no projeto. Opções:
- **Simples (recomendado para MVP):** cron no sistema ou script Python rodado pelo Docker com `command: python scripts/mark_inactive_leads.py`
- **Robusto:** APScheduler integrado ao FastAPI `lifespan`

Criar `backend/scripts/mark_inactive_leads.py`:
```python
# Busca leads em EM_ATENDIMENTO/QUALIFICADO/AGENDADO com updated_at < agora-30dias
# Atualiza status para PERDIDO
# Registra interação automática com motivo "inatividade"
```

### Passo 3.6 — Testar webhook WhatsApp end-to-end

Usar ngrok para expor o backend localmente:
```bash
ngrok http 8000
# Configurar URL do webhook no Meta for Developers com o HTTPS do ngrok
# Enviar mensagem de teste no WhatsApp
# Verificar: mensagem chegou → AYA respondeu → lead criado no banco
```

---

## 6. Fase 4 — Flutter: Consolidação Arquitetural

> **Pré-requisito:** Fases 1-3 concluídas (backend funcionando).
> **Meta:** App Flutter compila, faz login real e carrega dashboard.

### Passo 4.1 — Corrigir `main.dart`

Resolver B7:
- [ ] Remover imports duplicados
- [ ] Garantir que todos os providers `UnimplementedError` recebem implementações reais via `overrideWith` no `ProviderScope`
- [ ] A linha `client_docs.documentsProvider.overrideWithValue(null)` precisa de implementação real ou ser removida

### Passo 4.2 — Unificar sistema de autenticação

Existem dois sistemas paralelos de auth. Escolher **um** (recomenda-se o novo: `auth/providers/auth_provider.dart` com `AsyncNotifier`):
- [ ] Remover `lib/features/auth/auth_notifier.dart` (versão legada)
- [ ] Remover `lib/features/auth/login_screen.dart` (versão legada)
- [ ] Atualizar `app_router.dart` para usar apenas `authNotifierProvider`
- [ ] Atualizar `dashboard_screen.dart`, `status_screen.dart` e todas as demais telas que referenciavam `authProvider`

### Passo 4.3 — Implementar todos os Ports faltantes

Os seguintes providers lançam `UnimplementedError` — precisam de implementação concreta:

| Provider | Arquivo | Implementação necessária |
|---|---|---|
| `authPortProvider` | `auth/providers/auth_provider.dart:6` | `AuthRepositoryImpl` (usa DioClient) |
| `agendaPortProvider` | `agency/agenda/agenda_provider.dart:6` | `AgendaRepositoryImpl` |
| `leadPortProvider` | `agency/leads/leads_provider.dart:6` | `LeadRepositoryImpl` |
| `proposalPortProvider` | `agency/proposals/proposals_provider.dart:6` | `ProposalRepositoryImpl` |
| `interactions_provider` | `client/interactions/interactions_provider.dart:6` | `InteractionsRepositoryImpl` |
| `trip_status_provider` | `client/trip_status/trip_status_provider.dart:6` | `TripStatusRepositoryImpl` |
| `dashboardPortProvider` | `agency/dashboard/dashboard_provider.dart:24` | `DashboardRepositoryImpl` |
| `leadDetailPortProvider` | `agency/lead_detail/lead_detail_provider.dart:33` | `LeadDetailRepositoryImpl` |
| `profilePortProvider` | `client/profile/profile_provider.dart:6` | `ProfileRepositoryImpl` |

Para cada um:
1. Criar `*_repository_impl.dart` em `lib/features/.../data/`
2. Implementar as chamadas ao backend via `DioClient`
3. Registrar no `service_locator.dart`
4. Passar via `overrideWith` no `ProviderScope` do `main.dart`

### Passo 4.4 — Configurar Firebase no Flutter

- [ ] Criar projeto no Firebase Console (se não existe)
- [ ] Instalar `flutterfire_cli`: `dart pub global activate flutterfire_cli`
- [ ] Rodar: `flutterfire configure` no diretório `frontend_flutter/`
- [ ] Isso gera `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`
- [ ] Adicionar `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` no `main.dart`
- [ ] Integrar `NotificationService` ao `setupServiceLocator`

### Passo 4.5 — Consolidar nomenclatura de pastas

Existem dois nomes para as mesmas features (legado em PT-BR vs novo em EN):
- `features/client/documentos/` (placeholder) e `features/client/documents/` (provider real)
- `features/client/historico/` (placeholder) e `features/client/interactions/` (provider real)
- `features/client/status/` (placeholder) e `features/client/trip_status/` (provider real)

**O que fazer:**
1. Mover telas placeholder para as pastas com sufixo EN (ou deletar as placeholders)
2. Atualizar `app_router.dart` com os novos caminhos
3. Atualizar imports

### Passo 4.6 — Validar compilação e tela de login

```bash
cd frontend_flutter
flutter analyze   # deve retornar 0 erros
flutter pub get
flutter run       # login deve funcionar com usuário criado na Fase 2.5
```

---

## 7. Fase 5 — Flutter: Telas Faltando

> **Pré-requisito:** Fase 4 concluída (app compila e login funciona).
> **Meta:** Todas as telas do produto implementadas com dados reais.

### Passo 5.1 — Telas do Agente (Agency)

Prioridade: Pipeline CRM é o core do produto.

| Tela | Arquivo alvo | Dependências |
|---|---|---|
| Lista de propostas | `features/agency/proposals/proposals_screen.dart` | `proposalPortProvider` (Fase 4.3) |
| Detalhe de proposta | `features/agency/proposals/proposal_detail_screen.dart` | idem |
| Criar proposta | `features/agency/proposals/proposal_create_screen.dart` | idem |
| Editar lead | `features/agency/leads/lead_edit_screen.dart` | `leadPortProvider` |

Para cada tela:
- [ ] Criar arquivo `.dart` seguindo padrão de `leads_screen.dart`
- [ ] Usar `AsyncNotifierProvider` para dados remotos
- [ ] Implementar estados: loading (CircularProgressIndicator), error (retry button), success
- [ ] Usar cores/fontes exclusivamente via `AppColors`/`AppTheme`
- [ ] Navegar via `GoRouter`

### Passo 5.2 — Telas do Cliente

| Tela | Arquivo alvo | Dependências |
|---|---|---|
| Status da viagem (dinâmico) | `features/client/trip_status/trip_status_screen.dart` | `trip_status_provider` |
| Histórico de interações | `features/client/interactions/interactions_screen.dart` | `interactions_provider` |
| Documentos | `features/client/documents/documents_screen.dart` | `documents_provider` |
| Perfil do cliente | `features/client/profile/profile_screen.dart` | `profilePortProvider` |

**Atenção no `status_screen.dart` existente:**
- `currentStep = 0` está hardcoded → substituir por valor vindo do provider
- A timeline deve refletir o `LeadStatus` atual retornado pelo backend

### Passo 5.3 — Remover `api_service.dart` legado

O arquivo `lib/services/api_service.dart` tem `_baseUrl = 'http://localhost:8000'` hardcoded e coexiste com a nova camada `core/network/dio_client.dart`. Após confirmar que nenhuma tela ativa o usa mais:
- [ ] Deletar `lib/services/api_service.dart`
- [ ] Deletar qualquer referência a ele

---

## 8. Fase 6 — Integração End-to-End

> **Pré-requisito:** Fases 1-5 concluídas.
> **Meta:** Fluxo completo funciona: WhatsApp → AYA → banco → notificação FCM → app mostra lead.

### Passo 6.1 — Testar fluxo completo do lead

Roteiro de teste manual:
1. Enviar mensagem via WhatsApp para o número configurado
2. AYA responde e coleta briefing
3. Score ≥ 60%: lead muda para `QUALIFICADO` automaticamente
4. Consultor recebe notificação push no app Flutter
5. Consultor abre app, vê lead na lista, acessa detalhes
6. Consultor agenda curadoria → status muda para `AGENDADO`
7. Consultor cria proposta → status muda para `PROPOSTA`
8. Cliente abre app, vê status da viagem atualizado

### Passo 6.2 — Testar webhooks de status do WhatsApp

O backend não processa `status updates` (delivered/read receipts). Se a Meta enviar esses eventos, o webhook deve retornar 200 sem erros. Verificar em `webhook.py` se há tratamento para `entry[].changes[].value.statuses[]`.

### Passo 6.3 — Validar rate limiting

Com Redis rodando:
```bash
for i in {1..20}; do curl -s http://localhost:8000/health; done
# Deve retornar 429 Too Many Requests após atingir o limite
```

---

## 9. Fase 7 — Testes

> **Pré-requisito:** Fase 1 concluída (backend roda).
> **Meta:** Suite de testes cobre fluxos críticos; CI não passa com testes quebrando.

### Passo 7.1 — Configurar pytest corretamente

Criar `backend/pytest.ini` ou `backend/pyproject.toml`:
```ini
[pytest]
asyncio_mode = auto
testpaths = tests
```

Adicionar `__init__.py` nas pastas de teste que estão faltando:
- `tests/test_services/__init__.py`
- `tests/test_use_cases/__init__.py`

### Passo 7.2 — Testes de backend por prioridade

Implementar na seguinte ordem (maior risco/impacto primeiro):

**Alta prioridade:**
- [ ] `tests/test_routes/test_webhook.py` — POST webhook com payload válido → 200 + task agendada
- [ ] `tests/test_routes/test_auth.py` — login com credenciais válidas e inválidas
- [ ] `tests/test_routes/test_leads.py` — CRUD completo com RBAC (consultor só vê os seus)
- [ ] `tests/test_services/test_lead_service.py` — score, transições de status, soft delete

**Média prioridade:**
- [ ] `tests/test_services/test_ai_service.py` — mock do OpenAI, testar extração de briefing
- [ ] `tests/test_use_cases/test_process_whatsapp_message.py` — mock de todos os serviços externos
- [ ] `tests/test_infrastructure/test_repositories.py` — CRUD com banco de teste (SQLite async ou Postgres em memória)

**Baixa prioridade:**
- [ ] `tests/test_routes/test_agenda.py`
- [ ] `tests/test_routes/test_propostas.py`

### Passo 7.3 — Testes Flutter

**Alta prioridade:**
- [ ] `test/features/auth/login_screen_test.dart` — formulário válido → navega para dashboard; inválido → mostra erro
- [ ] `test/features/agency/leads/leads_screen_test.dart` — lista carrega; filtro funciona; empty state aparece

**Média prioridade:**
- [ ] Testes de provider para cada `AsyncNotifier` implementado na Fase 4.3
- [ ] Widget test para cada tela nova criada na Fase 5

---

## 10. Fase 8 — Infra e Segurança

> **Pré-requisito:** Fases 1-7 concluídas.
> **Meta:** Projeto seguro e pronto para ambiente de staging.

### Passo 8.1 — Corrigir docker-compose para produção

- [ ] Remover bind mount `volumes: - ../backend:/app` do serviço backend (usar apenas a imagem construída)
- [ ] Separar `docker-compose.yml` (produção) de `docker-compose.dev.yml` (desenvolvimento com bind mount)
- [ ] Adicionar Redis (B6 já lista isso)
- [ ] Atribuir `healthcheck` a todos os serviços
- [ ] Usar `env_file: .env` em vez de variáveis hardcoded

### Passo 8.2 — Corrigir CORS em produção

Em `main.py`, substituir `allow_origins=["*"]` por:
```python
allow_origins=settings.ALLOWED_ORIGINS  # lista de domínios configurada via .env
```

### Passo 8.3 — Endpoint de criação de usuário (seguro)

O endpoint `POST /users` deve:
- [ ] Ser protegido com `RequiresRole("admin")`
- [ ] Validar força da senha (mínimo 12 chars, mix de tipos)
- [ ] Não retornar `hashed_password` na resposta

### Passo 8.4 — `ENCRYPTION_KEY` não vazia

- [ ] Gerar chave Fernet e colocar no `.env`
- [ ] Garantir que campos PII (nome, telefone) são de fato criptografados no banco
- [ ] Testar: criar lead → consultar no banco → dados devem aparecer criptografados na coluna bruta

### Passo 8.5 — Remover variável morta `GEMINI_API_KEY`

`GEMINI_API_KEY` aparece no `.env.example` mas nenhum código usa Gemini — apenas OpenAI. Remover do `.env.example` para evitar confusão.

### Passo 8.6 — Corrigir `.env.example` com variáveis duplicadas

`backend/.env.example` tem `LANGCHAIN_API_KEY` declarado duas vezes e `DEBUG` declarado duas vezes. Limpar duplicações.

### Passo 8.7 — Substituir `dart_code_metrics` deprecado

O `pubspec.yaml` do Flutter referencia `dart_code_metrics: ^5.7.6`, pacote removido do pub.dev. Remover ou substituir por `flutter_lints` + regras customizadas em `analysis_options.yaml`.

---

## 11. Resumo Executivo por Camada

### Backend FastAPI

| Item | Status | Fase |
|---|---|---|
| `main.py` (sintaxe válida) | 🔴 Quebrado | B1 |
| Settings unificado | 🔴 Duplicado | B4 / 1.2 |
| `requirements.txt` completo | 🔴 Incompleto | B5 / 1.3 |
| Modelos sem duplicação | 🔴 Conflito | B3 |
| Tabela `users` + migration | 🔴 Faltando | B8 / 2.1-2.4 |
| Endpoint de criação de usuário | 🔴 Faltando | 2.5 |
| Repositórios implementados | 🟡 Parcial | 3.2 |
| Rotas conectadas a repositórios | 🟡 Desconectado | 3.3 |
| IA / RAG funcional | 🟡 Precisa de key válida | 3.4 |
| Job de leads inativos (30 dias) | 🔴 Faltando | 3.5 |
| Testes de rotas | 🔴 Faltando | 7.2 |
| Testes de serviços | 🔴 Faltando | 7.2 |

### Flutter

| Item | Status | Fase |
|---|---|---|
| `main.dart` (sem imports duplicados) | 🔴 Quebrado | B7 / 4.1 |
| Sistema de auth unificado | 🔴 Duplicado | 4.2 |
| Ports implementados | 🔴 UnimplementedError | 4.3 |
| Firebase configurado | 🔴 Faltando | 4.4 |
| Nomenclatura de pastas consolidada | 🟡 Inconsistente | 4.5 |
| Telas de Proposta | 🔴 Faltando | 5.1 |
| Telas do Cliente (dinâmicas) | 🟡 Placeholder | 5.2 |
| `api_service.dart` legado removido | 🟡 Coexistindo | 5.3 |
| Testes de telas | 🔴 Faltando | 7.3 |

### Infra / DevOps

| Item | Status | Fase |
|---|---|---|
| Redis no docker-compose | 🔴 Faltando | B6 |
| `.env` fora do git | 🔴 INCIDENTE | B2 |
| CORS configurável | 🟡 Hardcoded `["*"]` | 8.2 |
| docker-compose sem bind mount | 🟡 Dev only | 8.1 |
| ENCRYPTION_KEY não vazia | 🔴 Vazio | 8.4 |

---

## Ordem Recomendada de Execução (Sprint View)

```
Sprint 0 (urgente — 1 dia):
  B2 → Revogar tokens vazados imediatamente

Sprint 1 (3-5 dias — Backend roda):
  B1 → B3 → B4 → B5 → B6 → B8
  1.1 → 1.2 → 1.3 → 1.4 → 1.5

Sprint 2 (3-4 dias — Banco e dados):
  2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 2.6

Sprint 3 (3-5 dias — Negócio e IA):
  3.1 → 3.2 → 3.3 → 3.4 → 3.5 → 3.6

Sprint 4 (4-6 dias — Flutter compila e funciona):
  B7 → 4.1 → 4.2 → 4.3 → 4.4 → 4.5 → 4.6

Sprint 5 (5-7 dias — Telas completas):
  5.1 → 5.2 → 5.3

Sprint 6 (3-4 dias — Integração e testes):
  6.1 → 6.2 → 6.3
  7.1 → 7.2 (alta prioridade) → 7.3 (alta prioridade)

Sprint 7 (2-3 dias — Hardening):
  8.1 → 8.2 → 8.3 → 8.4 → 8.5 → 8.6 → 8.7
  7.2 (média/baixa prioridade) → 7.3 (média prioridade)
```

---

*Documento gerado por análise estática do repositório. Atualizar à medida que os itens forem concluídos.*
