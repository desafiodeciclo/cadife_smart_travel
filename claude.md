# Constituição do Agente — Cadife Smart Travel

> Leia este arquivo **inteiro** antes de qualquer ação. É o ponto zero de toda sessão.

## Identidade do Projeto

Plataforma de atendimento turístico inteligente para a **Cadife Tour**:

- **WhatsApp Bot (AYA):** assistente de pré-atendimento via IA — coleta briefing estruturado e qualifica leads 24/7.
- **Backend FastAPI:** orquestra webhook Meta, camada IA (LangChain+RAG), banco de dados, notificações FCM.
- **App Flutter:** CRM da agência (dashboard, pipeline, agenda) + portal do cliente (status da viagem) — offline-first, biometria, GoRouter + Riverpod.

**Restrição Crítica Inegociável:** A IA NUNCA gera preços, confirma disponibilidade de voos/hospedagem ou fecha vendas. O sistema é de pré-atendimento — o consultor humano sempre fecha o negócio.

---

## Ritual de Início de Sessão (Obrigatório)

Execute nesta ordem antes de tocar qualquer código:

1. Leia `.claude/steering/` — modularizado em:
    - `01_overview_and_scope.md` (Visão, Escopo e Fases)
    - `02_architecture.md` (Arquitetura e Clean Architecture)
    - `03_data_modeling.md` (Entidades e Schemas)
    - `04_api_endpoints.md` (Contratos REST)
    - `05_ai_specification.md` (IA/RAG Specs — Gemini + LangChain)
    - `06_flutter_requirements.md` (Requisitos Flutter — Riverpod + GoRouter + Offline-first)
    - `07_business_rules_and_flow.md` (Fluxos e Regras de Negócio)
    - `08_management_and_planning.md` (Gestão, Cronograma e Equipe)
    - `09_non_functional_and_risks.md` (Requisitos Não Funcionais e Riscos)
    - `10_glossary_and_stakeholders.md` (Glossário e Stakeholders)
2. Leia `.claude/rules/` — regras ativas por camada (backend, flutter, AI)
3. Verifique `specs/active/` — há tasks em andamento? Retome-as do último step incompleto.
4. Se `specs/active/` vazio, verifique `specs/pending/` — assuma a próxima task disponível.

---

## Workflow SDD (Spec-Driven Development)

```
docs/ → specs/pending/ → specs/active/ → [código] → specs/done/
(humano)   (JSON criado)   (Claude move ao iniciar)          (Claude move ao concluir)
```

### Regras do Workflow

- **Nunca** escreva código sem spec JSON correspondente em `specs/active/`.
- **Ao assumir task:** mova JSON de `pending/` → `active/`, atualize `"status": "in-progress"`.
- **Ao concluir task:** atualize todos os steps para `"done"`, mova `active/` → `done/`.
- **Se sessão for interrompida:** na próxima sessão leia `specs/active/` e retome do último step com `"status": "pending"`.
- **Mudanças de escopo:** entram apenas em `specs/pending/` para próximo sprint — nunca interrompem sprint ativo.
- **Validação:** toda feature de negócio requer validação de 2 membros do time, incluindo PO Diego para critérios de aceitação.

---

## Camadas, Responsabilidades e Donos

| Camada | Diretório | Responsável | Regras |
|---|---|---|---|
| Backend / API | `backend/` | Nikolas Tesch | `.claude/rules/backend_fastapi.md` |
| IA / RAG | `backend/app/services/ai_*.py` | Frank Willian | `.claude/rules/ai_langchain.md` |
| Flutter Agência | `frontend_flutter/lib/features/agency/` | Jakeline | `.claude/rules/flutter_frontend.md` |
| Flutter Cliente | `frontend_flutter/lib/features/client/` | Otávio Grotto | `.claude/rules/flutter_frontend.md` |
| DevOps / Firebase | `docker/`, FCM config | Luiz Angelo | `.claude/steering/tech.md` |

---

## Restrições Críticas Universais

1. **IA não gera preços** — proibido em qualquer prompt, chain ou resposta ao usuário.
2. **Webhook responde HTTP 200 em ≤ 5s** — processamento IA é **sempre** assíncrono via `BackgroundTasks`.
3. **Credenciais nunca no código** — exclusivamente via `.env` (ver `.env.example`).
4. **JWT obrigatório** em todos os endpoints exceto `GET /webhook/whatsapp`, `POST /webhook/whatsapp` e `GET /health`.
5. **Briefing score ≥ 60%** para transição de status `em_atendimento → qualificado`.
6. **Soft delete** no endpoint `DELETE /leads/{id}` — nunca deletar fisicamente registros de leads.
7. **HTTPS obrigatório** em todos os ambientes (ngrok para dev local).
8. **Testes Obrigatórios:** Toda nova funcionalidade ou correção deve acompanhar seus respectivos testes (Pytest no backend, Flutter Test no frontend).

---

## Regras de Qualidade de Código

### Python / Backend
- Type hints obrigatórios em toda função pública
- `async def` em todos os route handlers e chamadas I/O
- Pydantic v2 para todos os schemas de entrada e saída
- `HTTPException` para erros HTTP; logger estruturado para todos os eventos
- Testes: `pytest` + `httpx.AsyncClient` para endpoints críticos

### Dart / Flutter
- Riverpod (`AsyncNotifierProvider`) para dados remotos; `StateProvider` para UI local simples
- Repositório pattern para abstração de chamadas HTTP (`lib/services/api_service.dart`)
- Cores e fontes **somente** via `AppColors` / `AppTheme` em `lib/core/theme/`
- `GoRouter` para navegação declarativa com guards de auth no router, não nas telas
- Feedback visual obrigatório para toda ação: loading, success e error states
- **Offline-first:** cache local via Hive (preferências) + Isar (entidades); sincroniza ao reconectar
- **Segurança:** certificate pinning obrigatório, `flutter_secure_storage` para JWT, biometria via `local_auth`
- `get_it` como service locator para DI — não instanciar serviços diretamente em widgets

---

## Referência Rápida de Documentação

| Necessidade | Arquivo |
|---|---|
| Regras de negócio completas (score, status, horários) | `.claude/steering/07_business_rules_and_flow.md` |
| Modelagem de dados completa (entidades, campos, tipos) | `.claude/steering/03_data_modeling.md` |
| Contrato completo da API (endpoints + schemas JSON) | `.claude/steering/04_api_endpoints.md` |
| Design da camada IA / RAG / prompts AYA (Gemini) | `.claude/steering/05_ai_specification.md` |
| Gestão, Cronograma e Equipe | `.claude/steering/08_management_and_planning.md` |
| Requisitos Flutter — offline-first, biometrics, state | `.claude/steering/06_flutter_requirements.md` |
| Design das telas Flutter (fluxos, estados) | `docs/design/flutter_design.md` |
| Decisões arquiteturais registradas | `docs/adr/` |
| Bugs reportados com trace | `docs/bugs/` |
| Visão executiva do produto (brief) | `.claude/steering/01_overview_and_scope.md` |

---

## Ciclo de Vida do Lead (Referência Rápida)

```
NOVO → EM_ATENDIMENTO → QUALIFICADO → AGENDADO ──→ PROPOSTA → FECHADO
                                    ↘ PROPOSTA ↗
                        (qualquer estado) → PERDIDO (30 dias sem resposta)
```

Gatilhos:
- `NOVO → EM_ATENDIMENTO`: IA inicia diálogo
- `EM_ATENDIMENTO → QUALIFICADO`: briefing ≥ 60% de completude
- `QUALIFICADO → AGENDADO`: cliente aceita horário de curadoria
- `AGENDADO → PROPOSTA`: após realização da curadoria
- `PROPOSTA → FECHADO`: cliente aprova e realiza pagamento

---

## Identidade Visual (Tokens Obrigatórios)

| Token | Valor |
|---|---|
| `primaryColor` | `#dd0b0e` |
| `backgroundColor` | `#393532` |
| `scaffoldColor` | `#FFFFFF` |
| `successColor` | `#1E8449` |
| `warningColor` | `#D35400` |
| `textPrimary` | `#1A1A1A` |
| `textSecondary` | `#5D6D7E` |
| `cardBackground` | `#F8F9FA` |
| `font` | Inter ou Roboto |
