# Arquitetura Flutter — Template de Referência

> Baseado no projeto I-Móveis. Use como template e adapte os nomes de features, entidades e providers para o seu domínio.

---

## Estrutura Raiz da `lib/`

```
lib/
├── main.dart              ← ponto de entrada (runApp apenas)
├── app.dart               ← widget raiz (providers, tema, roteamento)
├── config/
│   └── router/
│       └── app_router.dart
├── core/                  ← infraestrutura compartilhada
├── design_system/         ← componentes e tokens visuais
└── features/              ← funcionalidades do app
    └── nome_feature/
        ├── data/
        ├── domain/
        └── presentation/
```

---

## `main.dart` e `app.dart`

**main.dart** — mínimo absoluto:
```dart
void main() {
  runApp(const ProviderScope(child: MyApp()));
}
```

**app.dart** — widget raiz `MyApp` responsável por:
- Envolver com `MultiBlocProvider` (BLoC para auth) + `ProviderScope` (Riverpod para tudo mais)
- Configurar `MaterialApp.router` com GoRouter
- Aplicar tema dinâmico (dark/light com seed color via provider)
- Escutar o `AuthBloc` para redirecionar após login/logout

```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(themeProvider);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()..add(AuthCheckRequested())),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: theme,
      ),
    );
  }
}
```

---

## `config/router/app_router.dart`

Define toda a navegação via **GoRouter** com `StatefulShellRoute.indexedStack` — mantém as abas vivas em memória sem recarregar ao trocar.

### Estrutura de rotas

```
/splash                        ← primeira tela
/onboarding                    ← boas-vindas
/login                         ← autenticação
/register
/forgot-password

[Shell Principal]              ← 5 branches persistentes (tabs)
├── /home                      ← branch 1
├── /search                    ← branch 2
│   └── /search/map
├── /favorites                 ← branch 3
├── /chat                      ← branch 4
│   └── /chat/:id
└── /profile                   ← branch 5
    ├── /profile/edit
    ├── /profile/settings
    └── /profile/my-items

/item/:id                      ← rota global (fora do shell)
    └── /item/:id/photos
    └── /item/:id/schedule
    └── /item/:id/proposal

/admin/*                       ← seção restrita
```

### Redirecionamento por role

```dart
redirect: (context, state) {
  final authState = authBloc.state;
  final isPublicRoute = ['/splash', '/login', '/register'].contains(state.matchedLocation);

  if (authState is AuthUnauthenticated && !isPublicRoute) return '/login';
  if (authState is AuthAuthenticated && isPublicRoute) return '/home';

  // Redirecionamento por role após login
  if (authState is AuthAuthenticated) {
    if (authState.user.isAdmin) return '/admin/dashboard';
    if (authState.user.isOwner) return '/profile/my-items';
  }
  return null;
},
```

---

## `core/`

Infraestrutura **compartilhada por todas as features** — sem lógica de negócio.

```
core/
├── constants.dart
├── error/
│   ├── failures.dart
│   └── failure_messages.dart
├── network/
│   ├── dio_client.dart
│   └── interceptors/
│       ├── auth_interceptor.dart
│       ├── error_mapper_interceptor.dart
│       └── logging_interceptor.dart
├── providers/
│   ├── dio_provider.dart
│   ├── auth_provider.dart           ← instância do SDK de auth (ex: Auth0)
│   ├── secure_storage_provider.dart
│   ├── shared_preferences_provider.dart
│   └── current_user_provider.dart
├── storage/
│   └── secure_token_storage.dart
├── theme/
│   ├── theme_provider.dart
│   └── seed_color_provider.dart
└── utils/
    └── location_service.dart        ← adapte conforme o domínio
```

### `constants.dart`

Centraliza todas as configurações — nunca dispersar em arquivos de feature:

```dart
// URL via variável de ambiente (não hardcode)
const kApiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');

// Toggles de modo de desenvolvimento
const kUseMockData = bool.fromEnvironment('USE_MOCK', defaultValue: true);
const kUseMockAuth = bool.fromEnvironment('USE_MOCK_AUTH', defaultValue: true);

// Credenciais de terceiros
const kAuth0Domain    = String.fromEnvironment('AUTH0_DOMAIN');
const kAuth0ClientId  = String.fromEnvironment('AUTH0_CLIENT_ID');
const kAuth0Audience  = String.fromEnvironment('AUTH0_AUDIENCE');
const kAuth0RolesClaim = 'https://seuapp.com/roles';

// Timeouts de rede
const kConnectTimeout = Duration(seconds: 15);
const kReceiveTimeout = Duration(seconds: 30);
```

### `network/dio_client.dart`

```dart
class DioClient {
  late final Dio _dio;

  DioClient(String baseUrl) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: kConnectTimeout,
      receiveTimeout: kReceiveTimeout,
    ))
      ..interceptors.add(AuthInterceptor())
      ..interceptors.add(ErrorMapperInterceptor())
      ..interceptors.add(LoggingInterceptor());
  }
}
```

### `error/failures.dart`

```dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure    extends Failure { const NetworkFailure() : super('Sem conexão com a internet'); }
class ServerFailure     extends Failure { const ServerFailure([super.message = 'Erro no servidor']); }
class UnauthorizedFailure extends Failure { const UnauthorizedFailure() : super('Sessão expirada'); }
class NotFoundFailure   extends Failure { const NotFoundFailure() : super('Recurso não encontrado'); }
class CacheFailure      extends Failure { const CacheFailure() : super('Erro de cache local'); }
```

### `providers/current_user_provider.dart`

```dart
@riverpod
AuthUser? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authBlocProvider);
  return authState is AuthAuthenticated ? authState.user : null;
}
```

---

## `design_system/`

Sistema de design próprio com componentes, tokens e efeitos. **Nunca use valores hardcoded** (hex, font names) fora desta pasta.

```
design_system/
├── design_system.dart       ← barrel file (único import para o resto do app)
├── tokens/
│   ├── app_colors.dart
│   ├── app_typography.dart
│   ├── app_spacing.dart
│   ├── app_radius.dart
│   ├── app_shadows.dart
│   ├── app_durations.dart
│   └── index.dart
├── theme/
│   ├── app_theme.dart
│   └── index.dart
├── components/
│   ├── index.dart
│   ├── app_button.dart
│   ├── app_text_field.dart
│   ├── app_card.dart
│   ├── app_bottom_nav.dart
│   ├── app_badge.dart
│   ├── app_avatar.dart
│   ├── app_chip.dart
│   └── page_scaffold.dart
├── effects/
│   ├── transitions.dart
│   ├── scroll_animations.dart
│   └── index.dart
└── utils/
    ├── extensions.dart
    └── index.dart
```

### `tokens/app_colors.dart`

```dart
class AppColors {
  AppColors._();

  // Marca
  static const Color primary    = Color(0xFF___);   // substitua pelo hex do projeto
  static const Color secondary  = Color(0xFF___);

  // Superfícies
  static const Color background = Color(0xFF___);
  static const Color surface    = Color(0xFF___);
  static const Color card       = Color(0xFF___);

  // Texto
  static const Color textPrimary   = Color(0xFF___);
  static const Color textSecondary = Color(0xFF___);
  static const Color textDisabled  = Color(0xFF___);

  // Semântico
  static const Color success = Color(0xFF1E8449);
  static const Color warning = Color(0xFFD35400);
  static const Color error   = Color(0xFFE74C3C);
  static const Color info    = Color(0xFF2980B9);
}
```

### `tokens/app_spacing.dart`

```dart
class AppSpacing {
  AppSpacing._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}
```

### `theme/app_theme.dart`

```dart
class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    // configure: ElevatedButtonTheme, InputDecorationTheme, CardTheme, etc.
    // usando os tokens de AppColors, AppTypography, AppRadius
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark),
  );
}
```

### `design_system.dart` — barrel file

```dart
// Tokens
export 'tokens/index.dart';
// Tema
export 'theme/index.dart';
// Componentes
export 'components/index.dart';
// Efeitos
export 'effects/index.dart';
// Utils
export 'utils/index.dart';
```

---

## `features/` — Clean Architecture por Feature

Cada feature é **completamente autossuficiente**, organizada em 3 camadas:

```
features/nome_feature/
├── data/
│   ├── datasources/
│   │   ├── feature_datasources.dart        ← interface abstrata
│   │   ├── feature_remote_api_datasource.dart
│   │   └── feature_remote_mock_datasource.dart
│   ├── models/
│   │   └── feature_api_model.dart          ← JSON ↔ Entity
│   ├── providers/
│   │   └── feature_data_providers.dart     ← instâncias Riverpod da camada data
│   └── repositories/
│       └── feature_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── feature_entity.dart             ← modelo puro, sem dependência externa
│   ├── repositories/
│   │   └── i_feature_repository.dart       ← contrato (interface)
│   └── usecases/
│       ├── get_feature_usecase.dart
│       └── create_feature_usecase.dart
└── presentation/
    ├── bloc/                               ← apenas se usar BLoC (ex: auth)
    │   ├── feature_bloc.dart
    │   ├── feature_event.dart
    │   └── feature_state.dart
    ├── pages/
    │   ├── feature_list_page.dart
    │   └── feature_detail_page.dart
    ├── providers/                          ← Notifiers Riverpod de UI
    │   └── feature_notifier.dart
    └── widgets/                            ← componentes locais (não vão pro design_system)
        └── feature_card.dart
```

### Fluxo de dados (nunca pule camadas)

```
UI (Widget)
  └── Provider/BLoC (presentation/providers ou bloc)
        └── UseCase (domain/usecases)
              └── Repository Interface (domain/repositories)
                    └── Repository Impl (data/repositories)
                          └── Datasource (data/datasources)
                                └── DioClient / MockData / LocalStorage
```

---

## Padrões de Implementação por Camada

### Domain — Entidade

```dart
// domain/entities/item.dart
class Item {
  const Item({
    required this.id,
    required this.title,
    required this.createdAt,
    this.description,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final String? description;
}
```

### Domain — Interface do Repositório

```dart
// domain/repositories/i_item_repository.dart
abstract interface class IItemRepository {
  Future<Either<Failure, List<Item>>> getAll({int page = 1});
  Future<Either<Failure, Item>> getById(String id);
  Future<Either<Failure, Item>> create(ItemInput input);
  Future<Either<Failure, void>> delete(String id);
}
```

### Domain — UseCase

```dart
// domain/usecases/get_items_usecase.dart
class GetItemsUseCase {
  const GetItemsUseCase(this._repository);
  final IItemRepository _repository;

  Future<Either<Failure, List<Item>>> call({int page = 1}) {
    return _repository.getAll(page: page);
  }
}
```

### Data — Model (JSON ↔ Entity)

```dart
// data/models/item_api_model.dart
class ItemApiModel {
  const ItemApiModel({required this.id, required this.title, required this.createdAt});

  factory ItemApiModel.fromJson(Map<String, dynamic> json) => ItemApiModel(
    id: json['id'] as String,
    title: json['title'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  final String id;
  final String title;
  final DateTime createdAt;

  Item toEntity() => Item(id: id, title: title, createdAt: createdAt);
}
```

### Data — Datasource (interface + implementações)

```dart
// data/datasources/item_datasources.dart
abstract interface class IItemDatasource {
  Future<List<ItemApiModel>> getAll({int page = 1});
  Future<ItemApiModel> getById(String id);
}

// data/datasources/item_remote_api_datasource.dart
class ItemRemoteApiDatasource implements IItemDatasource {
  const ItemRemoteApiDatasource(this._dio);
  final DioClient _dio;

  @override
  Future<List<ItemApiModel>> getAll({int page = 1}) async {
    final response = await _dio.get('/items', queryParameters: {'page': page});
    return (response.data as List).map((e) => ItemApiModel.fromJson(e)).toList();
  }
}

// data/datasources/item_remote_mock_datasource.dart
class ItemRemoteMockDatasource implements IItemDatasource {
  @override
  Future<List<ItemApiModel>> getAll({int page = 1}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [/* dados mock */];
  }
}
```

### Data — Repositório (implementação)

```dart
// data/repositories/item_repository_impl.dart
class ItemRepositoryImpl implements IItemRepository {
  const ItemRepositoryImpl(this._datasource);
  final IItemDatasource _datasource;

  @override
  Future<Either<Failure, List<Item>>> getAll({int page = 1}) async {
    try {
      final models = await _datasource.getAll(page: page);
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Erro desconhecido'));
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
```

### Data — Providers Riverpod

```dart
// data/providers/item_data_providers.dart
@riverpod
IItemDatasource itemDatasource(ItemDatasourceRef ref) {
  if (kUseMockData) return ItemRemoteMockDatasource();
  return ItemRemoteApiDatasource(ref.watch(dioClientProvider));
}

@riverpod
IItemRepository itemRepository(ItemRepositoryRef ref) {
  return ItemRepositoryImpl(ref.watch(itemDatasourceProvider));
}
```

### Presentation — Notifier (Riverpod)

```dart
// presentation/providers/items_notifier.dart
@riverpod
class ItemsNotifier extends _$ItemsNotifier {
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  Future<List<Item>> build() async {
    return _loadPage(1);
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadPage(1));
  }

  Future<void> loadNextPage() async {
    if (!_hasMore || state.isLoading) return;
    final current = state.valueOrNull ?? [];
    final next = await _loadPage(_currentPage + 1);
    if (next.isEmpty) { _hasMore = false; return; }
    _currentPage++;
    state = AsyncData([...current, ...next]);
  }

  Future<List<Item>> _loadPage(int page) async {
    final result = await ref.read(itemRepositoryProvider).getAll(page: page);
    return result.fold((f) => throw f, (items) => items);
  }
}
```

### Presentation — Página

```dart
// presentation/pages/items_list_page.dart
class ItemsListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsNotifierProvider);

    return PageScaffold(
      title: 'Itens',
      child: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e is Failure ? e.message : 'Erro inesperado',
          onRetry: () => ref.invalidate(itemsNotifierProvider),
        ),
        data: (items) => items.isEmpty
            ? const EmptyStateView(message: 'Nenhum item encontrado')
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) => ItemCard(item: items[i]),
              ),
      ),
    );
  }
}
```

---

## Gerenciamento de Estado — Resumo

| Situação | Tecnologia | Motivo |
|---|---|---|
| Auth global (toda a app depende) | **BLoC + Freezed** | Estado broadcast, listeners em múltiplas telas |
| Dados remotos (listas, detalhes) | **AsyncNotifierProvider** | Async nativo, cache, invalidação simples |
| Formulários / ações pontuais | **NotifierProvider** | Estado síncrono com lógica encapsulada |
| Configurações simples (tema, filtro) | **StateProvider** | Sem lógica, só armazena valor |
| Estado local de widget | **StatefulWidget** | Animações, foco de campo, scroll |

### Regra de ouro

> A UI **nunca** chama HTTP diretamente. O fluxo é sempre:
> `Widget → Provider/BLoC → UseCase → Repository → Datasource → HTTP`

---

## Auth — Feature Especial (BLoC + Freezed)

A auth usa BLoC (em vez de Riverpod) porque seu estado precisa ser transmitido via `BlocListener` para múltiplas partes da árvore de widgets simultaneamente.

```dart
// presentation/bloc/auth_event.dart
@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.checkRequested()                          = AuthCheckRequested;
  const factory AuthEvent.loginRequested(String email, String pass) = AuthLoginRequested;
  const factory AuthEvent.logoutRequested()                         = AuthLogoutRequested;
  const factory AuthEvent.socialLoginRequested(SocialProvider p)    = AuthSocialLoginRequested;
}

// presentation/bloc/auth_state.dart
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial()                   = AuthInitial;
  const factory AuthState.loading()                   = AuthLoading;
  const factory AuthState.authenticated(AuthUser user) = AuthAuthenticated;
  const factory AuthState.unauthenticated()            = AuthUnauthenticated;
  const factory AuthState.failure(String message)      = AuthFailure;
}
```

Redirecionamento pós-login no `app.dart`:
```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    state.whenOrNull(
      authenticated: (user) {
        if (user.isAdmin)  return context.go('/admin/dashboard');
        if (user.isOwner)  return context.go('/profile/my-items');
        context.go('/home');
      },
      unauthenticated: (_) => context.go('/login'),
    );
  },
)
```

---

## Shell — Navegação com Abas Persistentes

```dart
// features/shell/presentation/pages/main_shell_page.dart
class MainShellPage extends ConsumerWidget {
  const MainShellPage({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isOwner = user?.isOwner ?? false;

    final tabs = isOwner ? _ownerTabs : _tenantTabs;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        tabs: tabs,
        onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
      ),
    );
  }
}
```

---

## Features do Projeto — Checklist

Adapte esta lista para o seu domínio:

- [ ] **auth** — login, registro, logout, recuperação de senha, social login
- [ ] **onboarding** — boas-vindas (Cubit simples)
- [ ] **splash** — decide para onde redirecionar na abertura
- [ ] **shell** — navegação principal com abas persistentes
- [ ] **home** — tela inicial (pode bifurcar por role)
- [ ] **[dominio_principal]** — feature central do app (ex: imóveis, produtos, serviços)
- [ ] **search** — busca com filtros, paginação, modos de visualização
- [ ] **detail** — detalhe de um item
- [ ] **favorites** — lista de favoritos
- [ ] **chat** — conversas e mensagens
- [ ] **profile** — perfil do usuário, edição, configurações
- [ ] **notifications** — central de notificações
- [ ] **admin** — painel de administração (separado, acesso restrito)

---

## Convenções de Nomenclatura

| Elemento | Convenção | Exemplo |
|---|---|---|
| Arquivo | snake_case | `item_repository_impl.dart` |
| Classe | PascalCase | `ItemRepositoryImpl` |
| Provider (Riverpod) | camelCase + sufixo | `itemsNotifierProvider` |
| Entidade | singular, sem sufixo | `Item` (não `ItemEntity`) |
| Model de API | singular + ApiModel | `ItemApiModel` |
| UseCase | verbo + UseCase | `GetItemsUseCase` |
| Interface | prefixo `I` | `IItemRepository` |
| BLoC event | sufixo no nome freezed | `AuthLoginRequested` |
| Página | sufixo `Page/` | `ItemDetailPage` |
| Widget local | sem sufixo especial | `ItemCard`, `PriceTag` |
| Notifier Riverpod | sufixo `Notifier` | `ItemsNotifier` |

---

## Dependências Essenciais (`pubspec.yaml`)

```yaml
dependencies:
  # State management
  flutter_bloc: ^8.x
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  freezed_annotation: ^2.x

  # Routing
  go_router: ^13.x

  # Network
  dio: ^5.x

  # Auth (substitua pelo seu provider)
  auth0_flutter: ^1.x

  # Storage
  flutter_secure_storage: ^9.x
  shared_preferences: ^2.x

  # Utils
  fpdart: ^1.x              # Either / Option (functional error handling)
  equatable: ^2.x           # value equality

dev_dependencies:
  build_runner: ^2.x
  freezed: ^2.x
  riverpod_generator: ^2.x
```

---

## Regras de Ouro

1. **UI nunca chama HTTP diretamente** — sempre via Provider → UseCase → Repository
2. **Cores e tipografia apenas via tokens** — nunca hardcode hex ou font name em widget
3. **Estado remoto via `AsyncNotifierProvider`** — nunca `setState` para dados de API
4. **Repositório sempre retorna `Either<Failure, T>`** — nunca lança exceção para cima
5. **Mock controlado por constante** — `kUseMockData` em `constants.dart`, sem `if` espalhado
6. **Features isoladas** — uma feature não importa outra feature diretamente; comunica via `core/providers`
7. **`design_system.dart` é o único import** — nunca importe tokens ou componentes individualmente fora do design system
8. **Soft delete em dados críticos** — nunca delete físico de registros de usuário ou item principal
9. **Navegação exclusivamente via GoRouter** — nunca `Navigator.push` diretamente
10. **Nenhuma credencial hardcoded** — sempre `String.fromEnvironment` ou `.env`
