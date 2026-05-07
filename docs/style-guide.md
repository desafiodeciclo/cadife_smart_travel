# Flutter Style Guide — Cadife Smart Travel

## Nomenclatura

### Arquivos
- **Snake_case**: `auth_provider.dart`, `user_repository_impl.dart`.
- Evitar sufixos redundantes exceto para implementações (`_impl.dart`).

### Classes e Enums
- **PascalCase**: `AuthRepository`, `UserStatus`.
- Interfaces de repositório **devem** começar com `I`: `IAuthRepository`, `IAgendaRepository`. Isso é intencional e correto.
- ⚠️ **Distinção crítica**: O prefixo `I` se aplica a **classes de interface** (`abstract class IFooRepository`), **NÃO** a **providers Riverpod**. Exemplo incorreto: `iAgendaRepositoryProvider`. Correto: `agendaRepositoryProvider`.

### Variáveis e Métodos
- **camelCase**: `currentUser`, `fetchLeads()`.
- Variáveis privadas com underscore: `_repository`.

## Arquitetura (Feature-First + Clean Architecture)

Toda feature em `lib/features/` deve seguir a estrutura:
- `domain/`: Entidades puras e interfaces de repositório.
- `application/`: Notifiers do Riverpod e Use Cases.
- `infrastructure/`: DTOs, implementações de repositório e datasources.
- `presentation/`: Widgets, Screens e Providers de UI.

## Riverpod Patterns

- **Simple Providers**: `final myProvider = Provider<T>(...)`.
- **Async Notifiers**: Usar `AsyncNotifier` para estados assíncronos.
- **Naming**: Todos os providers devem terminar em `Provider`.
- **Auto-dispose**: Usar sempre que o estado não precisar ser persistido globalmente.

## Serialization

- **Obrigatório**: Usar `Freezed` para todas as models e DTOs.
- **Mappers**: Toda conversão de JSON para Entidade deve passar por um Mapper em `infrastructure`.

## Error Handling

- **Failure Pattern**: Repositórios retornam `Either<Failure, T>`.
- **Custom Failures**: Criar tipos específicos para erros comuns (Network, Unauthorized, Server).
- ⚠️ **Proibido**: `catch (e) { return Left(ServerFailure(e.toString())); }`. Use `on DioException catch (e)` para erros de rede e inspecione `e.type` / `e.response?.statusCode`.
- **Factory obrigatória**: Adicionar `Failure.fromDioException(DioException e)` em `failures.dart`.

## Idioma de Pastas e Rotas

- Todas as pastas em `features/` devem usar **inglês**: `documents` (não `documentos`), `history` (não `historico`), `profile` (não `perfil`), `proposals` (não `propostas`).
- Todas as rotas GoRouter devem usar inglês: `/client/documents`, `/client/profile`, `/client/history`, `/agency/profile`.
