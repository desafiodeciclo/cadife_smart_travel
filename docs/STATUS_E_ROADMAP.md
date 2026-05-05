# Status do Projeto & Roadmap — Cadife Smart Travel

> Atualizado em: 2026-05-05 | Branch: developer | Versão: 1.1.0 MVP

---

## Estado Atual (Maio 2026)

| Camada | Estado | Observação |
|---|---|---|
| Backend (FastAPI) | **ESTÁVEL** | Clean Architecture implementada, `main.py` limpo, Settings unificadas |
| Banco de Dados (PostgreSQL) | **ESTÁVEL** | Todas as migrations aplicadas, tabela `users` criada, FKs corretas |
| IA / RAG (AYA) | **FUNCIONAL** | LangChain + Gemini, ChromaDB integrado, guardrails ativos |
| WhatsApp Webhook | **FUNCIONAL** | Validação de assinatura HMAC, BackgroundTasks, persist-first |
| Flutter App | **ESTÁVEL** | Clean Architecture consolidada, dois perfis, Riverpod, GoRouter |
| Docker / Infra | **COMPLETO** | PostgreSQL 16 + Redis 7 + ChromaDB no Compose |
| Testes | **PARCIAL** | Testes unitários de serviços e DioClient; E2E pendente |
| Segurança | **REFORÇADO** | PII criptografado (Isar), certificate pinning, prompt injection defense |

**Total de specs concluídas:** 19 de 19 do MVP

---

## Specs Concluídas (specs/done/)

| Spec | Descrição |
|---|---|
| `flutter_foundation.json` | Setup base do Flutter, DI, temas, constantes |
| `flutter-arch-refactor-001.json` | Migração completa para Clean Architecture |
| `flutter-network-http-layer-001.json` | Dio client com interceptors de auth/erro |
| `flutter-security-isar-002.json` | Isar com criptografia de PII, secure_storage |
| `flutter-ui-manager-agenda-001.json` | Tela de agenda do consultor |
| `flutter-client-documents-002.json` | Gerenciamento de documentos do cliente |
| `flutter-client-history-timeline-001.json` | Timeline de interações do cliente |
| `agency-dashboard-refactor-001.json` | Refatoração do dashboard da agência |
| `agency-profile-settings-001.json` | Configurações de perfil do consultor |
| `flutter_lib_refactor_spec.json` | Refatoração completa da `lib/` |
| `lead-lifecycle-state-machine-001.json` | Máquina de estados do lead (backend) |
| `lead-auto-score-on-qualified-001.json` | Score automático na transição de status |
| `proposals-api-001.json` | API de propostas (CRUD + ciclo de vida) |
| `proposals-lifecycle-002.json` | Fluxo completo de proposta → fechamento |
| `whatsapp-send-persist-001.json` | Persistência de mensagens WhatsApp |
| `rag-kb-population-validation-001.json` | Ingestão e validação da base RAG |
| `vector-db-ingestion-metadata-001.json` | Pipeline de ingestão ChromaDB com metadados |
| `ai-prompt-injection-defense-fallback-001.json` | Defesa contra prompt injection, fallback ao consultor |
| `ai-hybrid-search-rag-guardrails-langfuse-002.json` | Busca híbrida RAG + guardrails + observabilidade Langfuse |

---

## Histórico de Bloqueadores Críticos (Resolvidos)

Os bloqueadores abaixo foram identificados em 2026-04-27 e resolvidos até 2026-05-05 como parte das specs acima.

### B1 — `main.py` com sintaxe Python inválida — RESOLVIDO
- Parêntese do `CORSMiddleware` não fechado antes do próximo `app.add_middleware`
- **Resolução:** `main.py` reescrito seguindo Clean Architecture; CORS configurado via `settings.ALLOWED_ORIGINS`

### B2 — Credenciais reais versionadas no repositório — RESOLVIDO
- `backend/.env` com tokens Meta e Google reais commitados
- **Resolução:** `.env` adicionado ao `.gitignore`; tokens revogados e regenerados; apenas `.env.example` com placeholders no repositório

### B3 — Modelos SQLAlchemy duplicados (`__tablename__` conflitante) — RESOLVIDO
- `app/models/` e `app/infrastructure/persistence/models/` declarando os mesmos `__tablename__`
- **Resolução:** modelos legados em `app/models/` removidos; imports unificados para `infrastructure/persistence/models/`

### B4 — Settings duplicadas com campos disjuntos — RESOLVIDO
- `app/core/config.py` e `app/infrastructure/config/settings.py` coexistindo
- **Resolução:** Settings unificadas em `app/infrastructure/config/settings.py`; `app/core/config.py` removido

### B5 — `requirements.txt` incompleto — RESOLVIDO
- `structlog`, `slowapi`, `cryptography`, `alembic`, `langchain-google-genai`, `langchain-community`, `redis`, `argon2-cffi` ausentes
- **Resolução:** `requirements.txt` na raiz atualizado com todas as dependências e versões fixas

### B6 — `docker-compose.yml` sem Redis — RESOLVIDO
- `rate_limiter.py` tentava conectar em Redis inexistente no Compose
- **Resolução:** `docker/docker-compose.yml` atualizado com serviços `redis` (dev) e `redis_staging`

### B7 — `main.dart` Flutter com imports duplicados — RESOLVIDO
- Blocos de imports repetidos impediam compilação
- **Resolução:** arquivo consolidado; estrutura migrada para `main_dev.dart`, `main_staging.dart`, `main_prod.dart` + `main_common.dart`

### B8 — Tabela `users` sem migration — RESOLVIDO
- FKs para `users.id` sem a tabela existir; `alembic upgrade head` falhava
- **Resolução:** `user_model.py` criado em `infrastructure/persistence/models/`; migration `create_users_table` adicionada com precedência correta

---

## Pendências Pós-MVP

Os itens abaixo estão fora do escopo das 19 specs concluídas e entram no backlog de evolução:

| Item | Prioridade | Observação |
|---|---|---|
| Suite de testes E2E (Patrol) | Alta | Testes unitários existem; E2E ainda não cobre fluxo completo |
| Tratamento de áudio (Whisper) | Média | Lógica existe em `whatsapp_service.py`; não está ativada no fluxo de produção |
| Tratamento de imagem (armazenamento S3/GCS) | Média | Recebe e armazena; sem processamento IA |
| Swagger/OpenAPI refinado | Baixa | `/docs` funciona em dev/staging; exemplos de payload incompletos em alguns endpoints |
| Monitoring/Alertas (Langfuse) | Baixa | Hooks de observabilidade existem; integração Langfuse opcional via `.env` |
| Timeline do cliente — animações | Baixa | Funcional; sem animações de entrada |

---

## Arquitetura de Referência

```
WhatsApp (Meta)
    │ POST /webhook/whatsapp
    ▼
FastAPI (presentation/)
    │ HTTP 200 imediato
    │ BackgroundTasks →
    ▼
application/ (use cases)
    │
    ├─► domain/ (entidades, interfaces)
    │
    └─► infrastructure/
            ├── persistence/   (SQLAlchemy + PostgreSQL)
            ├── adapters/      (Firebase FCM, WhatsApp API)
            └── services/      (LangChain+Gemini, ChromaDB RAG)
                    │
                    └─► FCM push → Flutter App
```

---

## Ciclo de Vida do Lead

```
NOVO → EM_ATENDIMENTO → QUALIFICADO → AGENDADO → PROPOSTA → FECHADO
                     ↑ score ≥ 60%
         (qualquer estado) → PERDIDO (30 dias sem resposta)
```

Score = `(completude_briefing × 0.5) + (nível_interesse × 0.3) + (urgência × 0.2)`
Campos de briefing: destino, datas, num_pessoas, orçamento, tipo_viagem

---

## Como Rodar o Ambiente

```bash
# Configuração inicial (uma vez)
cp backend/.env.example backend/.env
# Preencher: GEMINI_API_KEY, WHATSAPP_TOKEN, PHONE_NUMBER_ID, VERIFY_TOKEN, JWT_SECRET_KEY

python3 -m venv .venv && source .venv/bin/activate
pip install -r backend/requirements.txt

# Subir tudo
./dev.sh
```

Endpoints após `./dev.sh`:
- API: `http://localhost:8000`
- Swagger: `http://localhost:8000/docs`
- PostgreSQL: `localhost:5433` (cadife/cadife)
- Redis: `localhost:6379`
- ngrok UI: `http://localhost:4040`
