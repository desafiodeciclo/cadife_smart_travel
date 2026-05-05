# Cadife Smart Travel

<p align="center">
  <img src="docs/assets/banner.png" alt="Cadife Smart Travel Banner" width="100%">
</p>

<p align="center">
  <strong>Plataforma de pré-atendimento turístico inteligente via WhatsApp + App Flutter (CRM da agência + portal do cliente).</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI">
  <img src="https://img.shields.io/badge/Gemini-4285F4?style=for-the-badge&logo=google&logoColor=white" alt="Gemini">
  <img src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Redis-DC382D?style=for-the-badge&logo=redis&logoColor=white" alt="Redis">
  <img src="https://img.shields.io/badge/ChromaDB-FF6B35?style=for-the-badge&logo=chroma&logoColor=white" alt="ChromaDB">
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
</p>

---

## Sobre o Projeto

O **Cadife Smart Travel** automatiza o primeiro atendimento da Cadife Tour mantendo o consultor humano no fechamento. O sistema opera em três camadas simultâneas:

- **Bot AYA (WhatsApp)** — recebe mensagens 24/7, extrai briefing estruturado (destino, datas, grupo, orçamento) e qualifica leads via IA com RAG sobre a base de conhecimento da agência. Nunca gera preços nem confirma disponibilidade.
- **Backend FastAPI** — valida assinatura do webhook Meta (≤ 5s), persiste tudo em PostgreSQL, executa a máquina de estados do lead e envia notificação FCM ao consultor em < 2 segundos via `BackgroundTasks`.
- **App Flutter (dual-mode)** — perfil **Agência** (CRM: dashboard, pipeline de leads, agenda, propostas) e perfil **Cliente** (status da viagem, documentos, histórico de interações, chat com IA).

**Restrição de negócio inegociável:** a IA nunca gera preços, confirma voos/hospedagem nem fecha vendas. O consultor humano sempre encerra o negócio.

---

## Stack Tecnológica

### Backend
| Camada | Tecnologia |
| :--- | :--- |
| Framework | FastAPI 0.136 (Python 3.11+, async) |
| ORM + Migrations | SQLAlchemy 2.0 + Alembic |
| Banco relacional | PostgreSQL 16 |
| Cache / filas | Redis 7 |
| Vector DB (RAG) | ChromaDB |
| LLM + Orquestração | Google Gemini + LangChain |
| Notificações push | Firebase Admin SDK (FCM) |
| Scheduler | APScheduler (expiração de leads às 02:00 UTC) |
| Logging estruturado | structlog |
| Rate limiting | slowapi |

### Frontend (Flutter)
| Camada | Tecnologia |
| :--- | :--- |
| Framework | Flutter 3.x (Android + iOS + Web) |
| State management | Riverpod 2.6 (AsyncNotifierProvider) |
| Navegação | GoRouter 17 com shells por perfil |
| HTTP client | Dio 5.7 (interceptors de auth + erro) |
| Cache local | Isar 3.1 (entidades criptografadas) + Hive (preferências) |
| Firebase | Auth, FCM, Crashlytics, Analytics |
| Segurança | flutter_secure_storage, local_auth (biometria), certificate pinning |
| UI components | Design system próprio inspirado em Shadcn |

---

## Módulos do Sistema

| Módulo | Descrição | Funcionalidades Principais |
| :--- | :--- | :--- |
| **Agência** | Painel do Consultor | Dashboard com métricas, pipeline Kanban de leads, agenda de curadorias, gestão de propostas |
| **Cliente** | Companion de Viagem | Status em tempo real da viagem, documentos, timeline de interações, chat com AYA |
| **AYA (IA)** | Motor de Atendimento | Coleta de briefing via WhatsApp, RAG sobre destinos, scoring automático de leads |

---

## Visual do Projeto

<table align="center">
  <tr>
    <td align="center"><strong>Dashboard da Agência</strong></td>
    <td align="center"><strong>App do Cliente</strong></td>
  </tr>
  <tr>
    <td><img src="docs/assets/dashboard.png" width="100%"></td>
    <td><img src="docs/assets/mobile.png" width="300px"></td>
  </tr>
</table>

---

## Arquitetura

Ambas as camadas seguem **Clean Architecture** (Ports & Adapters), garantindo que regras de negócio não dependam de frameworks.

```
┌─────────────────────────────────────────────────────────────────────┐
│  WhatsApp Cloud API (Meta)                                          │
│    POST /webhook/whatsapp → HTTP 200 imediato → BackgroundTasks     │
└───────────────────────────────┬─────────────────────────────────────┘
                                │ assíncrono
┌───────────────────────────────▼─────────────────────────────────────┐
│  Backend FastAPI (Clean Architecture)                               │
│                                                                     │
│  presentation/  ──►  application/  ──►  domain/                    │
│  (routers,           (use cases,        (entidades puras,           │
│   middlewares)        state machine)     interfaces)                │
│       │                   │                                         │
│  infrastructure/ ─────────┘                                        │
│  (SQLAlchemy · ChromaDB · Firebase · WhatsApp adapter)             │
└───────────────┬────────────────────────────┬───────────────────────┘
                │ REST + JWT                 │ FCM push
┌───────────────▼────────────────────────────▼───────────────────────┐
│  Flutter App (Clean Architecture por feature)                      │
│                                                                     │
│  features/agency/   features/client/   features/auth/              │
│    data/              data/              data/                      │
│    domain/            domain/            domain/                   │
│    presentation/      presentation/      presentation/             │
│                                                                     │
│  core/ → DI (GetIt) · Dio · Isar cache · FCM · Offline manager    │
└─────────────────────────────────────────────────────────────────────┘
```

### Ciclo de Vida do Lead

```
NOVO → EM_ATENDIMENTO → QUALIFICADO → AGENDADO → PROPOSTA → FECHADO
                    ↑ score ≥ 60%          ↑ cliente aceita horário
              (qualquer estado) → PERDIDO  (30 dias sem resposta)
```

---

## Multi-Environment (Flutter Flavors)

| Ambiente | API URL | App ID | Nome |
| :--- | :--- | :--- | :--- |
| **dev** | `http://localhost:4000` | `com.cadife.tour.dev` | Cadife Dev |
| **staging** | `https://staging-api.cadife.com` | `com.cadife.tour.staging` | Cadife Staging |
| **prod** | `https://api.cadife.com` | `com.cadife.tour` | Cadife |

```bash
# Dentro de frontend_flutter/
make run-dev       # Android/iOS em desenvolvimento
make run-staging   # Homologação
make run-prod      # Produção
make build-staging # Gera APK de staging
```

---

## Como Executar

### Pré-requisitos

| Ferramenta | Versão mínima |
| :--- | :--- |
| Docker Engine + Compose v2 | qualquer estável |
| Python | 3.11+ |
| Flutter SDK | estável |
| ngrok | qualquer (conta gratuita recomendada) |

### Backend — um único comando

```bash
# 1. Copie e preencha as variáveis obrigatórias
cp backend/.env.example backend/.env
# Preencha: GEMINI_API_KEY, WHATSAPP_TOKEN, PHONE_NUMBER_ID, VERIFY_TOKEN, JWT_SECRET_KEY

# 2. Crie e ative o virtualenv Python
python3 -m venv .venv && source .venv/bin/activate  # macOS/Linux
# .venv\Scripts\activate                             # Windows

# 3. Instale dependências
pip install -r backend/requirements.txt

# 4. Suba tudo
./dev.sh
```

O `./dev.sh` executa em sequência:
1. **Docker Compose** — sobe PostgreSQL 16, Redis 7 e ChromaDB (infraestrutura)
2. **Alembic** — aplica migrações pendentes
3. **Uvicorn** — inicia FastAPI com hot-reload na porta `8000`
4. **ngrok** — abre túnel HTTPS público para `localhost:8000`

Ao final você verá:

```
╔══════════════════════════════════════════════════════════════════╗
║      CADIFE SMART TRAVEL  —  Ambiente Dev Ativo  ✓               ║
╚══════════════════════════════════════════════════════════════════╝

  Endpoints locais:
  ├─ API FastAPI    →  http://localhost:8000
  ├─ Swagger Docs   →  http://localhost:8000/docs
  ├─ PostgreSQL     →  localhost:5433  (cadife / cadife)
  ├─ Redis          →  localhost:6379
  └─ ngrok UI       →  http://localhost:4040

  ┌─ URL pública HTTPS do ngrok ──────────────────────────────────┐
  │  https://abc123.ngrok-free.app                                 │
  │  Webhook Meta: https://abc123.ngrok-free.app/webhook/whatsapp  │
  └────────────────────────────────────────────────────────────────┘
```

Pressione **Ctrl+C** para encerrar todos os processos.

### Frontend

```bash
cd frontend_flutter
flutter pub get
make run-dev
```

Para apontar o app para seu backend local via ngrok:
1. Pegue a URL exibida pelo `./dev.sh`
2. Atualize `apiBaseUrl` em `lib/config/app_config.dart` (flavor `dev`)

---

## Configurando o Webhook no Meta for Developers

O WhatsApp Cloud API exige uma URL HTTPS pública — o ngrok provê isso em desenvolvimento.

1. Copie a URL do terminal: `https://<id>.ngrok-free.app/webhook/whatsapp`
2. Acesse [developers.facebook.com](https://developers.facebook.com) → seu app → **WhatsApp → Configuração**
3. Em **Webhook**, clique em **Editar** e preencha:

| Campo | Valor |
| :--- | :--- |
| **Callback URL** | `https://<id>.ngrok-free.app/webhook/whatsapp` |
| **Verify Token** | valor de `VERIFY_TOKEN` no `backend/.env` |

4. Clique em **Verificar e Salvar** → ative os campos `messages` e `message_deliveries`

> A URL do ngrok muda a cada restart (plano gratuito). Configure `NGROK_DOMAIN` no `.env` para URL fixa.

### Logs em tempo real

```bash
tail -f .dev-logs/uvicorn.log   # API FastAPI
tail -f .dev-logs/ngrok.log     # túnel ngrok
```

---

## Estrutura de Pastas

```
cadife_smart_travel/
├── backend/
│   ├── main.py                      # Entry point FastAPI
│   ├── app/
│   │   ├── domain/                  # Entidades, interfaces de repositório, enums
│   │   ├── application/             # Use cases, state machine de lead, DTOs
│   │   ├── infrastructure/          # SQLAlchemy, ChromaDB, Firebase, adapters
│   │   │   ├── adapters/            # firebase.py, whatsapp_adapter.py
│   │   │   ├── config/              # settings.py (única fonte de verdade), logging_config.py
│   │   │   ├── persistence/         # models/, repositories/
│   │   │   └── security/            # jwt.py, rate_limiter.py, pii_encryption.py
│   │   ├── presentation/            # Routers FastAPI, middlewares
│   │   │   └── middlewares/         # RequestId, Timeout, AuditTrail, SecurityHeaders
│   │   ├── routes/                  # webhook.py, leads.py, ia.py, agenda.py, propostas.py, auth.py
│   │   ├── services/                # ai_service, rag_service, lead_service, fcm_service...
│   │   └── jobs/                    # lead_expiration_job.py (02:00 UTC diário)
│   ├── migrations/                  # Alembic
│   ├── scripts/                     # ingest_and_validate.py, seed_admin.py, rag_test.py
│   └── tests/
├── frontend_flutter/
│   ├── lib/
│   │   ├── app.dart                 # CadifeAppWrapper (root widget)
│   │   ├── main_dev.dart            # Entry point flavor dev
│   │   ├── main_staging.dart        # Entry point flavor staging
│   │   ├── main_prod.dart           # Entry point flavor prod
│   │   ├── config/                  # app_config.dart, app_router.dart, theme/
│   │   ├── core/                    # DI, Dio, Isar, FCM, offline, analytics
│   │   ├── features/
│   │   │   ├── agency/              # dashboard, leads, agenda, perfil
│   │   │   ├── client/              # dashboard, documentos, histórico, chat
│   │   │   └── auth/                # login, registro, recuperação
│   │   └── design_system/           # Componentes UI reutilizáveis
│   └── Makefile                     # Comandos de build e run por flavor
├── docker/
│   └── docker-compose.yml           # PostgreSQL 16 · Redis 7 · ChromaDB
├── docs/
│   ├── adr/                         # Architecture Decision Records
│   ├── bugs/                        # Bugs conhecidos com trace
│   ├── contracts/                   # api_contract.md
│   └── STATUS_E_ROADMAP.md          # Histórico de bloqueadores e estado técnico
├── specs/
│   ├── spec.md                      # Especificação técnica principal v1.1.0
│   └── done/                        # 19 specs concluídas
├── .claude/
│   ├── steering/                    # 10 docs de contexto do projeto
│   └── rules/                       # Regras por camada (backend, flutter, IA)
├── .env.example                     # Template de variáveis de ambiente
├── dev.sh                           # Script único de setup do ambiente dev
└── CLAUDE.md                        # Constituição do agente Claude
```

---

## Status Atual

**Versão:** 1.1.0 MVP — Estável

Todas as 19 specs do MVP foram concluídas. O projeto encontra-se em estado estável com Clean Architecture implementada em ambas as camadas.

| Feature | Status |
| :--- | :--- |
| Webhook WhatsApp + validação de assinatura | Concluído |
| Assistente AYA (LangChain + Gemini + RAG) | Concluído |
| Guardrails de prompt injection e IA | Concluído |
| Máquina de estados do lead | Concluído |
| Score de qualificação automático | Concluído |
| API de leads, propostas, agenda e auth | Concluído |
| Flutter — Clean Architecture consolidada | Concluído |
| Flutter — CRM da agência (dashboard, leads, agenda) | Concluído |
| Flutter — Portal do cliente (status, documentos, histórico) | Concluído |
| Cache Isar com PII criptografado | Concluído |
| Offline-first com sincronização ao reconectar | Concluído |
| Notificações FCM em tempo real | Concluído |
| Docker Compose completo (PostgreSQL + Redis + ChromaDB) | Concluído |
| RAG — ingestão e validação da base de conhecimento | Concluído |
| Suite de testes end-to-end | Pendente |
| Tratamento completo de mídia (áudio/imagem) | Parcial |

> Para o histórico técnico detalhado de bloqueadores resolvidos, consulte [docs/STATUS_E_ROADMAP.md](./docs/STATUS_E_ROADMAP.md).

---

## Regras de Negócio Críticas

1. **IA não gera preços** — proibido em qualquer prompt, chain ou resposta ao usuário
2. **Webhook responde em ≤ 5s** — todo processamento de IA usa `BackgroundTasks`
3. **Briefing score ≥ 60%** para lead transitar de `EM_ATENDIMENTO → QUALIFICADO`
4. **Soft delete** em leads — nunca exclusão física
5. **JWT obrigatório** em todos os endpoints exceto webhook e health
6. **HTTPS obrigatório** em todos os ambientes

---

## Documentação Técnica

| Documento | Caminho |
| :--- | :--- |
| Especificação técnica completa | `specs/spec.md` |
| Contrato da API (endpoints + schemas) | `docs/contracts/api_contract.md` |
| Design das telas Flutter | `docs/design/flutter_design.md` |
| Architecture Decision Records | `docs/adr/` |
| Steering docs (visão, arquitetura, IA, regras...) | `.claude/steering/` |
| Swagger UI (dev/staging) | `http://localhost:8000/docs` |

---

<p align="center">
  Desenvolvido pela equipe <strong>Cadife Smart Travel</strong> — Alpha Edtech 2026.
</p>
