# Backlog de Refactor — Arquitetura Flutter

## (R) refactor/auth-notifier-migration
**Prioridade:** Crítico | **Pontos:** 12 | **Sprint:** 5
**Related:** chore/flutter-architecture-audit

### Descrição
Migrar a gestão de estado de autenticação de `AuthBloc` (bloc) para `AuthNotifier` (Riverpod AsyncNotifier). Isso elimina o uso misto de padrões e facilita a observação do estado pelo GoRouter.

### Antes/Depois
```dart
// ANTES
final authBlocProvider = Provider<AuthBloc>((ref) => AuthBloc(repository));

// DEPOIS
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(
  () => AuthNotifier(),
);
```

---

## (R) refactor/api-error-handling-standardization
**Prioridade:** Crítico | **Pontos:** 8 | **Sprint:** 5
**Related:** chore/flutter-architecture-audit

### Descrição
Padronizar o tratamento de erros em todos os repositórios. Deixar de usar `e.toString()` genérico e implementar tipos específicos de `Failure` baseados no status code do Dio (Unauthorized, NotFound, Server, Network).

### Antes/Depois
```dart
// ANTES
catch (e) { return Left(ServerFailure(e.toString())); }

// DEPOIS
catch (e) { return Left(Failure.fromException(e)); }
```

---

## (R) refactor/freezed-model-migration
**Prioridade:** Alto | **Pontos:** 16 | **Sprint:** 6
**Related:** chore/flutter-architecture-audit

### Descrição
Migrar todas as classes de modelo (entities e DTOs) para utilizar o package `Freezed`. Isso reduz boilerplate de `copyWith`, `equals` e `fromJson`.

---

## (R) refactor/dto-entity-separation
**Prioridade:** Alto | **Pontos:** 12 | **Sprint:** 6
**Related:** chore/flutter-architecture-audit

### Descrição
Separar as classes de dados da API (DTOs) das entidades de domínio. Criar Mappers para converter `LeadDto` -> `Lead`. O domínio não deve ter dependência de pacotes de serialization ou formato JSON.

---

## (R) refactor/standardize-naming-conventions
**Prioridade:** Médio | **Pontos:** 6 | **Sprint:** 7
**Related:** chore/flutter-architecture-audit

### Descrição
Corrigir inconsistências de nomenclatura:
- Remover prefixo `i` de providers (ex: `iAgendaRepositoryProvider` -> `agendaRepositoryProvider`).
- Renomear pastas em Português para Inglês (`perfil` -> `profile`, `documentos` -> `documents`).
