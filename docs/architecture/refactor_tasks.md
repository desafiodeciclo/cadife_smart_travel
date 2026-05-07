# Backlog de Refactor — Arquitetura Flutter
> Última atualização: 2026-05-05 v1.1 — cross-referenciado com código real

---

## (R) refactor/auth-notifier-migration ⚡ Crítico
**Prioridade:** Crítico | **Pontos:** 8 | **Sprint:** 5
**Related:** chore/flutter-architecture-audit

### Situação Atual (v1.1)
⚠️ O `AuthNotifier` **já existe** em `auth/presentation/providers/auth_notifier.dart` mas está **órfão** — nunca é consumido. O `authBlocProvider` ainda comanda toda a árvore.

### O que fazer
1. Conectar `authNotifierProvider` no `app.dart` substituindo `authBlocProvider`
2. Refatorar `app_router.dart` para que o `_RouterNotifier` escute `authNotifierProvider` em vez do stream do Bloc
3. Migrar `main_common.dart` (linha 34), `splash_screen.dart`, `forgot_password_screen.dart` e `app_lock_provider.dart`
4. Remover `authBlocProvider`, `AuthBloc`, `AuthEvent`, `AuthState` (ou manter apenas para referência histórica)

### Antes/Depois
```dart
// ANTES (ainda ativo)
final authBlocProvider = Provider<AuthBloc>((ref) => AuthBloc(repository));
// Em app_router.dart:
final authBloc = ref.watch(authBlocProvider);
final notifier = _RouterNotifier(authBloc.stream);

// DEPOIS (usar o que já existe)
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(AuthNotifier.new);
// Em app_router.dart:
ref.listen(authNotifierProvider, (_, __) => notifier.notify());
```

---

## (R) refactor/api-error-handling-standardization ⚡ Crítico
**Prioridade:** Crítico | **Pontos:** 8 | **Sprint:** 5
**Related:** chore/flutter-architecture-audit

### Situação Atual (v1.1)
❌ `catch (e) { return Left(ServerFailure(e.toString())); }` encontrado em **22+ locais** em todos os repositórios.
⚠️ `failures.dart` tem os tipos corretos (`NetworkFailure`, `UnauthorizedFailure`) mas não expõe factory `fromDioException`.

### O que fazer
1. Adicionar `Failure.fromDioException(DioException e)` em `failures.dart`
2. Varrer todos os `*_repository_impl.dart` e substituir `catch (e)` por `on DioException catch (e)` + fallback tipado

### Antes/Depois
```dart
// ANTES (em todos os repos)
} catch (e) { return Left(ServerFailure(e.toString())); }

// DEPOIS
} on DioException catch (e) {
  return Left(Failure.fromDioException(e));
} catch (e) {
  return Left(GenericFailure(e.toString()));
}

// Em failures.dart — adicionar:
static Failure fromDioException(DioException e) {
  if (e.type == DioExceptionType.connectionError) return const NetworkFailure();
  if (e.response?.statusCode == 401) return const UnauthorizedFailure();
  if (e.response?.statusCode == 404) return const NotFoundFailure();
  return ServerFailure(e.message ?? 'Erro no servidor.');
}
```

---

## (R) refactor/freezed-model-migration
**Prioridade:** Alto | **Pontos:** 16 | **Sprint:** 6
**Related:** chore/flutter-architecture-audit

### Situação Atual (v1.1)
⚠️ `AuthEvent` e `AuthState` já usam Freezed (correto). `AuthUser` ainda é manual com Equatable.
❌ `TokenModel` está embutido em `auth_user.dart` (arquivo de entidade de domínio) — violação de camadas.

### O que fazer
1. Migrar `AuthUser` de `Equatable` manual para `@freezed`
2. Extrair `TokenModel` para `auth/data/models/token_model.dart`
3. Varrer outras entidades manuais (leads, agendamento, documento) e migrar

---

## (R) refactor/dto-entity-separation
**Prioridade:** Alto | **Pontos:** 12 | **Sprint:** 6
**Related:** chore/flutter-architecture-audit

### Situação Atual (v1.1)
❌ `AuthUser.fromJson()/toJson()` vivem na entidade de domínio com conhecimento de nomes de campos JSON (`'nome'`, `'perfil'`, `'criado_em'`). O domínio não deve conhecer o formato da API.

### O que fazer
Criar `auth/data/models/auth_user_dto.dart` com `fromJson/toJson` e um Mapper:
```dart
// infrastructure/mappers/auth_mapper.dart
class AuthMapper {
  static AuthUser fromDto(AuthUserDto dto) => AuthUser(
    id: dto.id,
    name: dto.nome,
    email: dto.email,
    role: UserRole.fromString(dto.perfil),
  );
}
```

---

## (R) refactor/rename-pt-to-en ⚡ Médio
**Prioridade:** Médio | **Pontos:** 8 | **Sprint:** 7
**Related:** chore/flutter-architecture-audit

### Situação Atual (v1.1)
❌ Pastas em PT: `agency/perfil/`, `agency/propostas/`, `client/documentos/`, `client/historico/`
❌ Rotas em PT: `/agency/perfil`, `/client/perfil`, `/client/documentos`, `/client/historico`
❌ Rota ausente: `/agency/proposals/:leadId` (definida no design doc mas não implementada)

### O que fazer
1. Renomear pastas com `git mv` (preserva histórico)
2. Atualizar imports em massa
3. Atualizar rotas no `app_router.dart`
4. Adicionar rota `/agency/proposals/:leadId`

```
agency/perfil/     → agency/profile/
agency/propostas/  → agency/proposals/
client/documentos/ → client/documents/
client/historico/  → client/history/

/agency/perfil    → /agency/profile
/client/perfil    → /client/profile
/client/documentos → /client/documents
/client/historico  → /client/history
```

---

## (R) refactor/standardize-naming-conventions
**Prioridade:** Baixo | **Pontos:** 4 | **Sprint:** 7
**Related:** chore/flutter-architecture-audit

### Situação Atual (v1.1)
❌ `iAgendaRepositoryProvider` (agenda_provider.dart:5) usa prefixo `i`.
Referenciado em: `agenda_provider.dart`, `schedule_appointment_provider.dart`, `provider_overrides.dart`.

### O que fazer
```dart
// Renomear declaration em agenda_provider.dart:
// ANTES
final iAgendaRepositoryProvider = Provider<IAgendaRepository>(...);
// DEPOIS
final agendaRepositoryProvider = Provider<IAgendaRepository>(...);

// Atualizar 3 call sites
```

---

## (R) refactor/router-cleanup
**Prioridade:** Médio | **Pontos:** 6 | **Sprint:** 7
**Related:** chore/flutter-architecture-audit

### Situação Atual (v1.1)
❌ `/notifications` dentro do ShellRoute de Agency — clientes não têm acesso
❌ `state.extra as Lead` em `/agency/leads/details` quebra deep links FCM
❌ `state.extra as Documento` em `/client/documentos/viewer` quebra deep links

### O que fazer
1. Mover `/notifications` para fora de ambos os ShellRoutes (rota global)
2. Trocar `state.extra as Lead` por path parameter `/agency/leads/:id`
3. Trocar `state.extra as Documento` por path parameter `/client/documents/:id`
