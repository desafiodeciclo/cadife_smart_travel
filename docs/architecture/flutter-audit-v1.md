# Flutter Architecture Audit — Cadife Smart Travel
## v1.1 | Revisado por Antigravity | Data: 2026-05-05

> **Nota de Revisão v1.1:** Auditoria cross-referenciada com o código atual em `/lib`. Itens marcados com ✅ estão implementados corretamente; ❌ indicam inconsistência ativa; ⚠️ indicam implementação parcial.

### Executivo

**Total de inconsistências encontradas:** 27
- Críticas: 5
- Altas: 10
- Médias: 8
- Baixas: 4

**Estimativa total de refactor:** 71 pontos de trabalho

---

## 1. Análise de Estrutura de Pastas

### Atual
O projeto utiliza uma estrutura **Feature-first** com divisões internas em `domain`, `data` e `presentation`. A camada de aplicação está **ausente** — a lógica de orquestração vive dentro de providers Riverpod dentro de `presentation/providers`. A camada de infraestrutura é nomeada como `data`.

### Recomendado
- Padronizar para Feature-first com Clean Architecture 4 layers: `domain`, `application`, `infrastructure`, `presentation`.
- Mover `data` para `infrastructure`.
- Criar `application` para lógica de orquestração e Riverpod Notifiers.

### Inconsistências
- ❌ **Múltiplos padrões de camadas** — `auth` usa `data/domain/presentation/providers` (4 camadas), mas `agency/leads` usa apenas `data/domain/presentation` (3 camadas sem separar providers). Impacto: Médio.
- ❌ **Core vs Shared** — Existe uma pasta `core` com 13 sub-módulos (analytics, cache, config, di, error, network, notifications, offline, router, security, utils, validators) e uma `shared` com apenas `presentation`. Responsabilidades sobrepostas: `core/notifications` coexiste com `features/notifications`. Impacto: Alto.
- ❌ **Providers dentro de `presentation`** — `auth/presentation/providers/` mistura lógica de UI com orquestração de negócio. Providers de repositório deveriam estar em `application/`. Impacto: Médio.
- ❌ **`features/auth/providers/`** — Existe um `providers/` diretamente em `auth/` (app_lock_provider.dart) **e** um `auth/presentation/providers/`. Duas localizações distintas para providers de auth. Impacto: Alto.

---

## 2. Análise de Riverpod

### Padrões Utilizados
Uso **misto e coexistente** de Riverpod com Bloc. O `AuthNotifier` (Riverpod `AsyncNotifier`) **já existe** em `auth_notifier.dart` mas **não é usado** — o app ainda depende do `authBlocProvider` em toda a árvore.

### Inconsistências & Recomendações
- ❌ **`authBlocProvider` ainda é o provider ativo** — `app.dart`, `app_router.dart`, `splash_screen.dart`, `forgot_password_screen.dart` e `main_common.dart` todos importam e usam `authBlocProvider`. O `authNotifierProvider` existe mas está **órfão** (nunca chamado). Impacto: **Crítico**.
- ❌ **`_RouterNotifier` depende do stream do Bloc** — `app_router.dart` instancia `_RouterNotifier(authBloc.stream)`, acoplando o roteador ao Bloc. Impacto: Alto.
- ❌ **`iAgendaRepositoryProvider` com prefixo `i`** — Encontrado em `agenda_provider.dart` (linha 5) e referenciado em `provider_overrides.dart` (linha 20) e `schedule_appointment_provider.dart` (linha 51). Deve ser `agendaRepositoryProvider`. Impacto: Baixo.
- ⚠️ **GetIt + Riverpod** — `provider_overrides.dart` usa `sl<IAgendaRepository>()` (GetIt) para injetar no Riverpod. Padrão híbrido documentado no `refactor_tasks.md` como a ser migrado. Impacto: Alto.

### Status dos Providers Existentes
| Provider | Tipo | Padrão | Status |
|---|---|---|---|
| `authBlocProvider` | `Provider<AuthBloc>` | Bloc wrapper (deprecated) | ❌ Em uso ativo |
| `authNotifierProvider` | `AsyncNotifierProvider` | Correto | ❌ Órfão - não usado |
| `iAgendaRepositoryProvider` | `Provider<IAgendaRepository>` | Nome errado (prefixo `i`) | ❌ Em uso ativo |
| `agendaProvider` | `AsyncNotifierProvider` | Correto | ✅ Em uso |
| `routerProvider` | `Provider<GoRouter>` | Correto | ✅ Em uso |

### Exemplos
**Antes (Bloc wrapper — ainda ativo):**
```dart
final authBlocProvider = Provider<AuthBloc>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthBloc(repository);
});
```
**Depois (AsyncNotifier — implementado mas não conectado):**
```dart
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  () => AuthNotifier(),
);
```

---

## 3. Análise de GoRouter

### Padrões Utilizados
Centralizado em `config/router/app_router.dart` com lógica de redirecionamento baseada em estado do Bloc. Existe um re-export em `core/router/app_router.dart` que simplesmente delega para `config/router/`.

### Inconsistências & Recomendações
- ❌ **Dependência de Bloc no Router** — O roteador cria `_RouterNotifier(authBloc.stream)` escutando o stream do `AuthBloc`. Quando migrar para `authNotifierProvider`, o `routerProvider` deve usar `ref.listen` no `AsyncNotifier`. Impacto: Alto.
- ❌ **Uso de `state.extra` para objetos complexos** — `Lead` em `/agency/leads/details` (linha 119) e `Documento` em `/client/documentos/viewer` (linha 192) são passados via `extra`, quebrando deep links via FCM. O router FCM já usa `/leads/:leadId` como path (linha 149-153), mas a rota de detalhe interna usa `extra`. Inconsistência entre os dois padrões no mesmo arquivo. Impacto: Médio.
- ❌ **Rota `/agency/perfil` usa caminho PT** — A rota é `/agency/perfil` (linha 137) mas o design doc especifica `/agency/profile`. Impacto: Baixo.
- ❌ **Rota `/client/perfil` usa caminho PT** — A rota é `/client/perfil` (linha 213) mas o design doc especifica `/client/profile`. Impacto: Baixo.
- ⚠️ **Rota `/client/historico` usa caminho PT** — O design doc especifica `/client/interactions`. Impacto: Baixo.
- ⚠️ **`/notifications` dentro do ShellRoute de Agency** — A rota de notificações (linha 144-147) está dentro do shell de agência. Clientes não podem acessar notificações. Impacto: Médio.

### Rotas: Doc vs Código
| Rota no Design Doc | Rota Real | Status |
|---|---|---|
| `/auth/login` | `/auth/login` | ✅ OK |
| `/agency/dashboard` | `/agency/dashboard` | ✅ OK |
| `/agency/leads` | `/agency/leads` | ✅ OK |
| `/agency/leads/:id` | `/agency/leads/details` (via extra) | ❌ Quebra deep links |
| `/agency/agenda` | `/agency/agenda` | ✅ OK |
| `/client/status` | `/client/status` | ✅ OK |
| `/client/interactions` | `/client/historico` | ❌ Nomenclatura PT |
| `/client/documents` | `/client/documentos` | ❌ Nomenclatura PT |
| `/client/profile` | `/client/perfil` | ❌ Nomenclatura PT |
| `/agency/proposals/:leadId` | Não encontrada | ❌ Ausente |

---

## 4. Análise de API & Networking

### Padrões Utilizados
Dio com interceptores e repositórios retornando `Either<Failure, T>` via `fpdart`.

### Inconsistências & Recomendações
- ❌ **Tratamento de Erro Genérico** — `catch (e) { return Left(ServerFailure(e.toString())); }` encontrado em **22 locais** confirmados:
  - `auth_repository_impl.dart`: linhas 31, 41, 72, 125, 135
  - `leads_repository_impl.dart`: linhas 21, 31, 41, 51, 61, 71, 81
  - `status_repository_impl.dart`: linhas 17, 27
  - `notifications_repository_impl.dart`: linhas 30, 40, 50, 60, 74
  - `offline_first.dart`: linhas 39, 79, 98
  
  Os repositórios de `perfil` e `agenda` já usam `on DioException catch (e)` com fallback para `catch (e)` — padrão mais correto, porém incompleto. Impacto: **Crítico**.

- ❌ **`Failure` sem factory `fromException`** — O `failures.dart` tem os tipos corretos (`NetworkFailure`, `UnauthorizedFailure`, `ServerFailure`) mas **não implementa** `Failure.fromException(e)` conforme proposto no `refactor_tasks.md`. Impacto: Crítico.

- ❌ **Falta de Retry Logic** — Nenhuma política de retry para falhas transientes. Impacto: Médio.

- ⚠️ **`AUDIT_CONTEXT.md` menciona GoRouter 12.x** — O pubspec usa `go_router: ^17.2.2`. Doc desatualizado. Impacto: Baixo (doc).

- ⚠️ **`AUDIT_CONTEXT.md` menciona Riverpod 2.x** — O pubspec usa `flutter_riverpod: ^2.6.1`. Compatível mas há v3 disponível. Impacto: Baixo.

---

## 5. Análise de Models & Serialization

### Padrões Utilizados
Uso misto: `Equatable` manual e `Freezed` (gerado).

### Inconsistências & Recomendações
- ❌ **`AuthUser` é manual com `Equatable`** — Tem `fromJson`/`toJson`/`copyWith` manuais e boilerplate extenso. O style guide exige `Freezed` para todas as models. Impacto: Alto.
- ❌ **`TokenModel` está dentro de `auth_user.dart`** — `TokenModel` é um DTO de infraestrutura vivendo em um arquivo de entidade de domínio. Viola separação de camadas. Deveria estar em `data/models/token_model.dart`. Impacto: Alto.
- ❌ **`AuthUser` contém campos de serialization** — `fromJson`/`toJson` dentro da entidade de domínio expõem detalhes de infraestrutura (nomes de campo JSON como `'nome'`, `'perfil'`, `'telefone'`). Camada `domain` não deve conhecer formato JSON. Impacto: Alto.
- ✅ **`AuthEvent` e `AuthState` usam Freezed** — Corretamente gerados (`.freezed.dart` existente).

---

## 6. Análise de Nomenclatura

### Inconsistências
- ❌ **Prefixo `i` em Providers** — `iAgendaRepositoryProvider` (agenda_provider.dart:5). Deve ser `agendaRepositoryProvider`.
- ❌ **Pastas em PT no `agency`** — `agency/perfil/`, `agency/propostas/`, `agency/agenda/`. Design doc especifica EN: `profile`, `proposals`, `agenda` (agenda é ambígua, mas as demais estão erradas).
- ❌ **Pastas em PT no `client`** — `client/documentos/`, `client/historico/`. Design doc especifica EN: `documents`, `interactions`.
- ⚠️ **Style guide (linha 11) conflita com audit** — O style guide define: *"Interfaces de repositório devem começar com `I`"* mas o audit recomenda remover prefixo `i` de **providers** (não de interfaces). Interfaces como `IAuthRepository`, `IAgendaRepository` estão corretas. Impacto: Baixo — clarificação necessária no doc.

---

## 7. Inconsistências entre `AUDIT_CONTEXT.md` e o Código

| Campo no AUDIT_CONTEXT | Valor Documentado | Valor Real | Status |
|---|---|---|---|
| Flutter version | Flutter 3.22 | SDK: ^3.11.4 (Dart) | ⚠️ Verificar |
| Riverpod | 2.x | 2.6.1 | ✅ OK |
| GoRouter | 12.x | 17.2.2 | ❌ Desatualizado |
| Dio | 5.x | 5.7.0 | ✅ OK |
| Freezed | mencionado | 2.5.2 (dev) / 2.4.4 (annotation) | ✅ OK |
| Isar | mencionado | 3.1.0+1 | ✅ OK |

---

## 8. Lista Priorizada de Refactors (Atualizada)

| # | Problema | Impacto | Esforço | Status |
|---|---|---|---|---|
| 1 | Conectar `authNotifierProvider` (já implementado) e remover `AuthBloc` do app | Crítico | 8h | 🔴 Pendente |
| 2 | Implementar `Failure.fromException(e)` e substituir 22 `catch (e)` genéricos | Crítico | 6h | 🔴 Pendente |
| 3 | Migrar `AuthUser` para Freezed + extrair `TokenModel` para infra | Alto | 8h | 🔴 Pendente |
| 4 | Separar DTOs de Entidades (criar Mappers) | Alto | 12h | 🔴 Pendente |
| 5 | Renomear `iAgendaRepositoryProvider` → `agendaRepositoryProvider` | Baixo | 1h | 🔴 Pendente |
| 6 | Renomear pastas PT → EN (`documentos`, `historico`, `perfil`, `propostas`) | Médio | 4h | 🔴 Pendente |
| 7 | Corrigir rotas GoRouter PT → EN (`/client/documentos`, `/client/perfil`, etc.) | Médio | 2h | 🔴 Pendente |
| 8 | Mover `notifications` para fora do ShellRoute de Agency | Médio | 2h | 🔴 Pendente |
| 9 | Migrar GetIt → Riverpod DI puro | Médio | 8h | 🔴 Pendente |
| 10 | Adicionar rota `/agency/proposals/:leadId` ao router | Alto | 2h | 🔴 Pendente |

---

## 9. Plano de Implementação (Revisado)

### Fase 1 (Sprint 5) — Críticos
- Task: `refactor/auth-notifier-migration` — conectar `authNotifierProvider` existente, migrar router, remover `AuthBloc` do app
- Task: `refactor/api-error-handling-standardization` — implementar `Failure.fromException`, varrer 22 sites

### Fase 2 (Sprint 6) — Altos
- Task: `refactor/auth-model-freezed` — `AuthUser` → Freezed, extrair `TokenModel`
- Task: `refactor/dto-entity-separation` — criar DTOs + Mappers em `data/`

### Fase 3 (Sprint 7) — Médios
- Task: `refactor/rename-pt-to-en` — pastas + rotas + imports
- Task: `refactor/router-cleanup` — mover `/notifications`, corrigir `state.extra`

---

## 10. Recomendações de Tooling

### Lint Rules (analysis_options.yaml)
Ativar `prefer_final_locals`, `always_declare_return_types`, e regras de `riverpod_lint`.

### Guia de Estilo (style-guide.md)
Clarificar distinção: interfaces de repositório **usam** prefixo `I` (ex: `IAuthRepository`); providers **não usam** prefixo `i`.

### Versões no AUDIT_CONTEXT.md
Atualizar referências: GoRouter 12.x → 17.x.
