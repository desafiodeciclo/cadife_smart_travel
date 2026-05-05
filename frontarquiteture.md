# Arquitetura Flutter — Cadife Smart Travel
# CRM Agência + Portal Cliente — Clean Architecture Reference

> App Flutter com dois perfis: **Agência** (CRM de leads, pipeline, agenda) e **Cliente** (status da viagem).
> Stack: Riverpod + GoRouter + BLoC (auth) + Isar (offline-first) + Firebase FCM + JWT

---

## Estrutura Raiz da `lib/`

```
lib/
├── main.dart                  ← runApp + ProviderScope apenas
├── app.dart                   ← widget raiz (MultiBlocProvider + MaterialApp.router)
├── config/
│   └── router/
│       └── app_router.dart    ← GoRouter com guards por role (agency/client)
├── core/                      ← infraestrutura compartilhada (sem lógica de negócio)
├── design_system/             ← tokens e componentes visuais Cadife Tour
└── features/
    ├── auth/
    ├── splash/
    ├── shell/
    ├── agency/
    │   ├── dashboard/
    │   ├── leads/
    │   ├── agenda/
    │   └── propostas/
    ├── client/
    │   ├── status/
    │   ├── historico/
    │   ├── documentos/
    │   └── perfil/
    └── notifications/
```

---

## `main.dart` e `app.dart`

**main.dart** — mínimo absoluto:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: CadifeApp()));
}
```

**app.dart** — widget raiz responsável por:
- Envolver com `MultiBlocProvider` (BLoC para auth) + `ProviderScope` (Riverpod para tudo mais)
- Configurar `MaterialApp.router` com GoRouter
- Escutar o `AuthBloc` para redirecionar após login/logout por role

```dart
class CadifeApp extends ConsumerWidget {
  const CadifeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()..add(const AuthCheckRequested())),
      ],
      child: MaterialApp.router(
        title: 'Cadife Smart Travel',
        routerConfig: router,
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
```

---

## `config/router/app_router.dart`

Define toda a navegação via **GoRouter** com `StatefulShellRoute.indexedStack` — mantém abas vivas sem recarregar ao trocar.

### Estrutura de rotas

```
/splash                              ← decide rota inicial por auth state

/auth/login                          ← autenticação JWT + Firebase Auth
/auth/register

[Shell Agência]                      ← StatefulShellRoute (4 branches)
├── /agency/dashboard                ← resumo do dia, KPIs, novos leads
├── /agency/leads                    ← lista com filtros (status, score, destino)
│   └── /agency/leads/:id            ← detalhe do lead (briefing, interações, ações)
│       └── /agency/leads/:id/agenda ← criar agendamento a partir do lead
├── /agency/agenda                   ← calendário semanal, agendamentos
└── /agency/propostas/:id            ← detalhe/criação de proposta

[Shell Cliente]                      ← StatefulShellRoute (3 branches)
├── /client/status                   ← status da viagem com barra de progresso
├── /client/historico                ← timeline de interações com AYA e consultor
├── /client/documentos               ← roteiros, vouchers, comprovantes
└── /client/perfil                   ← dados pessoais e preferências
```

### Redirecionamento por role

```dart
redirect: (context, state) {
  final authState = authBloc.state;
  final isPublicRoute = state.matchedLocation.startsWith('/auth') ||
                        state.matchedLocation == '/splash';

  if (authState is AuthUnauthenticated && !isPublicRoute) return '/auth/login';

  if (authState is AuthAuthenticated) {
    if (isPublicRoute) {
      return authState.user.role == UserRole.agency
          ? '/agency/dashboard'
          : '/client/status';
    }
    // Impede cliente de acessar rotas de agência e vice-versa
    final isAgencyRoute = state.matchedLocation.startsWith('/agency');
    final isClientRoute = state.matchedLocation.startsWith('/client');
    if (isAgencyRoute && authState.user.role != UserRole.agency) return '/client/status';
    if (isClientRoute && authState.user.role != UserRole.client) return '/agency/dashboard';
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
│       ├── auth_interceptor.dart        ← injeta Bearer JWT em cada request
│       ├── error_mapper_interceptor.dart
│       └── logging_interceptor.dart
├── providers/
│   ├── dio_provider.dart
│   ├── secure_storage_provider.dart
│   └── current_user_provider.dart
├── storage/
│   └── secure_token_storage.dart       ← flutter_secure_storage (JWT access + refresh)
└── utils/
    ├── date_formatter.dart
    └── lead_status_helper.dart         ← mapeia LeadStatus para label e cor
```

### `constants.dart`

```dart
// URL via variável de ambiente — nunca hardcode
const kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',  // emulador Android → localhost
);

// Feature flags de desenvolvimento
const kUseMockData = bool.fromEnvironment('USE_MOCK', defaultValue: false);

// Timeouts da API FastAPI
const kConnectTimeout = Duration(seconds: 10);
const kReceiveTimeout = Duration(seconds: 30);

// Thresholds de negócio
const kBriefingMinScore = 60;   // % mínimo para qualificar lead
const kLeadHotScore = 80;       // % para lead quente
```

### `network/dio_client.dart`

```dart
class DioClient {
  late final Dio _dio;

  DioClient(String baseUrl, SecureTokenStorage tokenStorage) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: kConnectTimeout,
      receiveTimeout: kReceiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ))
      ..interceptors.add(AuthInterceptor(tokenStorage))
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

class NetworkFailure     extends Failure { const NetworkFailure() : super('Sem conexão com a internet'); }
class ServerFailure      extends Failure { const ServerFailure([super.message = 'Erro no servidor']); }
class UnauthorizedFailure extends Failure { const UnauthorizedFailure() : super('Sessão expirada. Faça login novamente.'); }
class NotFoundFailure    extends Failure { const NotFoundFailure() : super('Recurso não encontrado'); }
class CacheFailure       extends Failure { const CacheFailure() : super('Erro ao acessar dados locais'); }
class ValidationFailure  extends Failure { const ValidationFailure(super.message); }
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

Tokens e componentes visuais da Cadife Tour. **Nunca use valores hardcoded** fora desta pasta.

```
design_system/
├── design_system.dart          ← barrel file (único import externo)
├── tokens/
│   ├── app_colors.dart
│   ├── app_typography.dart     ← Inter / Roboto
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
│   ├── app_badge.dart          ← score badge: quente/morno/frio
│   ├── app_avatar.dart
│   ├── app_chip.dart           ← chips de status do lead
│   ├── page_scaffold.dart
│   └── lead_status_stepper.dart ← stepper visual do ciclo de vida do lead
├── effects/
│   ├── transitions.dart
│   └── index.dart
└── utils/
    ├── extensions.dart
    └── index.dart
```

### `tokens/app_colors.dart`

```dart
class AppColors {
  AppColors._();

  // Marca Cadife Tour
  static const Color primary    = Color(0xFFdd0b0e);  // vermelho CTA
  static const Color background = Color(0xFF393532);  // AppBar / dark bg
  static const Color scaffold   = Color(0xFFFFFFFF);  // fundo padrão

  // Superfícies
  static const Color card       = Color(0xFFF8F9FA);
  static const Color surface    = Color(0xFFFFFFFF);

  // Texto
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5D6D7E);
  static const Color textDisabled  = Color(0xFFBDBDBD);

  // Semântico (score de leads)
  static const Color success = Color(0xFF1E8449);  // lead quente
  static const Color warning = Color(0xFFD35400);  // lead morno
  static const Color error   = Color(0xFFE74C3C);  // lead perdido / erro
  static const Color info    = Color(0xFF2980B9);  // informativo

  // Aliases de score
  static const Color scoreHot  = success;
  static const Color scoreWarm = warning;
  static const Color scoreCold = textSecondary;
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
    scaffoldBackgroundColor: AppColors.scaffold,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ),
    textTheme: AppTypography.textTheme,
  );
}
```

### `design_system.dart` — barrel file

```dart
export 'tokens/index.dart';
export 'theme/index.dart';
export 'components/index.dart';
export 'effects/index.dart';
export 'utils/index.dart';
```

---

## `features/` — Clean Architecture por Feature

Cada feature é **completamente autossuficiente**, organizada em 3 camadas.

```
features/nome_feature/
├── data/
│   ├── datasources/
│   │   ├── feature_datasources.dart             ← interface abstrata
│   │   ├── feature_remote_api_datasource.dart   ← Dio → FastAPI
│   │   └── feature_remote_mock_datasource.dart  ← dados mock (kUseMockData)
│   ├── models/
│   │   └── feature_api_model.dart               ← JSON ↔ Entity (fromJson / toEntity)
│   ├── providers/
│   │   └── feature_data_providers.dart          ← instâncias Riverpod da camada data
│   └── repositories/
│       └── feature_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── feature_entity.dart                  ← modelo puro, sem dependência externa
│   ├── repositories/
│   │   └── i_feature_repository.dart            ← contrato (interface)
│   └── usecases/
│       ├── get_feature_usecase.dart
│       └── create_feature_usecase.dart
└── presentation/
    ├── bloc/                                    ← somente auth usa BLoC
    ├── pages/
    ├── providers/                               ← AsyncNotifierProvider (dados remotos)
    └── widgets/                                 ← componentes locais da feature
```

### Fluxo de dados (nunca pule camadas)

```
Widget
  └── AsyncNotifierProvider / BLoC
        └── UseCase
              └── Repository Interface (domain)
                    └── Repository Impl (data)
                          └── Datasource
                                └── DioClient → FastAPI / Isar (cache local)
```

---

## Entidades do Domínio

### `features/agency/leads/domain/entities/lead.dart`

```dart
enum LeadStatus { novo, emAtendimento, qualificado, agendado, proposta, fechado, perdido }
enum LeadScore  { quente, morno, frio }
enum LeadOrigem { whatsapp, app, web }

class Lead {
  const Lead({
    required this.id,
    required this.telefone,
    required this.origem,
    required this.status,
    required this.criadoEm,
    required this.atualizadoEm,
    this.nome,
    this.score,
    this.briefing,
  });

  final String id;
  final String telefone;
  final LeadOrigem origem;
  final LeadStatus status;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final String? nome;
  final LeadScore? score;
  final Briefing? briefing;
}
```

### `features/agency/leads/domain/entities/briefing.dart`

```dart
enum OrcamentoNivel { baixo, medio, alto, premium }

class Briefing {
  const Briefing({
    required this.leadId,
    this.destino,
    this.dataIda,
    this.dataVolta,
    this.qtdPessoas,
    this.perfil,
    this.tipoViagem,
    this.preferencias,
    this.orcamento,
    this.temPassaporte,
    this.observacoes,
    this.completudePct = 0,
  });

  final String leadId;
  final String? destino;
  final DateTime? dataIda;
  final DateTime? dataVolta;
  final int? qtdPessoas;
  final String? perfil;           // casal, família, solo, grupo, amigos
  final List<String>? tipoViagem; // turismo, lazer, aventura, imigração, negócios
  final List<String>? preferencias;
  final OrcamentoNivel? orcamento;
  final bool? temPassaporte;
  final String? observacoes;
  final int completudePct;        // 0–100
}
```

### `features/agency/agenda/domain/entities/agendamento.dart`

```dart
enum AgendamentoStatus { pendente, confirmado, realizado, cancelado }
enum AgendamentoTipo   { online, presencial }

class Agendamento {
  const Agendamento({
    required this.id,
    required this.leadId,
    required this.data,
    required this.hora,
    required this.status,
    required this.tipo,
    this.consultorId,
  });

  final String id;
  final String leadId;
  final DateTime data;
  final String hora;             // "HH:mm"
  final AgendamentoStatus status;
  final AgendamentoTipo tipo;
  final String? consultorId;
}
```

### `features/agency/propostas/domain/entities/proposta.dart`

```dart
enum PropostaStatus { rascunho, enviada, aprovada, recusada, emRevisao }

class Proposta {
  const Proposta({
    required this.id,
    required this.leadId,
    required this.descricao,
    required this.status,
    required this.criadoEm,
    this.valorEstimado,
  });

  final String id;
  final String leadId;
  final String descricao;
  final PropostaStatus status;
  final DateTime criadoEm;
  final double? valorEstimado;
}
```

---

## Padrões de Implementação — Feature: Leads (exemplo completo)

### Domain — Interface do Repositório

```dart
// features/agency/leads/domain/repositories/i_leads_repository.dart
abstract interface class ILeadsRepository {
  Future<Either<Failure, List<Lead>>> getLeads({LeadStatus? status, LeadScore? score, int page = 1});
  Future<Either<Failure, Lead>> getLeadById(String id);
  Future<Either<Failure, Lead>> updateLeadStatus(String id, LeadStatus status);
  Future<Either<Failure, Briefing>> getBriefing(String leadId);
  Future<Either<Failure, Briefing>> updateBriefing(String leadId, Briefing briefing);
}
```

### Domain — UseCases

```dart
// features/agency/leads/domain/usecases/get_leads_usecase.dart
class GetLeadsUseCase {
  const GetLeadsUseCase(this._repository);
  final ILeadsRepository _repository;

  Future<Either<Failure, List<Lead>>> call({LeadStatus? status, LeadScore? score, int page = 1}) {
    return _repository.getLeads(status: status, score: score, page: page);
  }
}
```

### Data — Model

```dart
// features/agency/leads/data/models/lead_api_model.dart
class LeadApiModel {
  const LeadApiModel({
    required this.id,
    required this.telefone,
    required this.origem,
    required this.status,
    required this.criadoEm,
    required this.atualizadoEm,
    this.nome,
    this.score,
  });

  factory LeadApiModel.fromJson(Map<String, dynamic> json) => LeadApiModel(
    id:           json['id'] as String,
    telefone:     json['telefone'] as String,
    origem:       LeadOrigem.values.byName(json['origem'] as String),
    status:       LeadStatus.values.byName((json['status'] as String).replaceAll('_', '')),
    criadoEm:     DateTime.parse(json['criado_em'] as String),
    atualizadoEm: DateTime.parse(json['atualizado_em'] as String),
    nome:         json['nome'] as String?,
    score:        json['score'] != null ? LeadScore.values.byName(json['score'] as String) : null,
  );

  final String id;
  final String telefone;
  final LeadOrigem origem;
  final LeadStatus status;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final String? nome;
  final LeadScore? score;

  Lead toEntity() => Lead(
    id: id, telefone: telefone, origem: origem, status: status,
    criadoEm: criadoEm, atualizadoEm: atualizadoEm, nome: nome, score: score,
  );
}
```

### Data — Datasource

```dart
// features/agency/leads/data/datasources/leads_datasources.dart
abstract interface class ILeadsDatasource {
  Future<List<LeadApiModel>> getLeads({String? status, String? score, int page = 1});
  Future<LeadApiModel> getLeadById(String id);
  Future<LeadApiModel> updateLeadStatus(String id, String status);
}

// leads_remote_api_datasource.dart
class LeadsRemoteApiDatasource implements ILeadsDatasource {
  const LeadsRemoteApiDatasource(this._dio);
  final DioClient _dio;

  @override
  Future<List<LeadApiModel>> getLeads({String? status, String? score, int page = 1}) async {
    final response = await _dio.get('/leads', queryParameters: {
      if (status != null) 'status': status,
      if (score != null) 'score': score,
      'page': page,
    });
    return (response.data as List).map((e) => LeadApiModel.fromJson(e)).toList();
  }

  @override
  Future<LeadApiModel> getLeadById(String id) async {
    final response = await _dio.get('/leads/$id');
    return LeadApiModel.fromJson(response.data);
  }

  @override
  Future<LeadApiModel> updateLeadStatus(String id, String status) async {
    final response = await _dio.put('/leads/$id', data: {'status': status});
    return LeadApiModel.fromJson(response.data);
  }
}
```

### Data — Providers Riverpod

```dart
// features/agency/leads/data/providers/leads_data_providers.dart
@riverpod
ILeadsDatasource leadsDatasource(LeadsDatasourceRef ref) {
  if (kUseMockData) return LeadsRemoteMockDatasource();
  return LeadsRemoteApiDatasource(ref.watch(dioClientProvider));
}

@riverpod
ILeadsRepository leadsRepository(LeadsRepositoryRef ref) {
  return LeadsRepositoryImpl(ref.watch(leadsDatasourceProvider));
}
```

### Presentation — Notifier (paginação infinita)

```dart
// features/agency/leads/presentation/providers/leads_notifier.dart
@riverpod
class LeadsNotifier extends _$LeadsNotifier {
  int _currentPage = 1;
  bool _hasMore = true;
  LeadStatus? _filterStatus;
  LeadScore? _filterScore;

  @override
  Future<List<Lead>> build() => _loadPage(1);

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

  void applyFilter({LeadStatus? status, LeadScore? score}) {
    _filterStatus = status;
    _filterScore = score;
    refresh();
  }

  Future<List<Lead>> _loadPage(int page) async {
    final result = await ref.read(leadsRepositoryProvider).getLeads(
      status: _filterStatus,
      score: _filterScore,
      page: page,
    );
    return result.fold((f) => throw f, (leads) => leads);
  }
}
```

### Presentation — Página de Lista de Leads

```dart
// features/agency/leads/presentation/pages/leads_list_page.dart
class LeadsListPage extends ConsumerWidget {
  const LeadsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(leadsNotifierProvider);

    return PageScaffold(
      title: 'Leads',
      actions: [FilterButton(onFilter: (s, sc) => ref.read(leadsNotifierProvider.notifier).applyFilter(status: s, score: sc))],
      child: leadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e is Failure ? e.message : 'Erro inesperado',
          onRetry: () => ref.invalidate(leadsNotifierProvider),
        ),
        data: (leads) => leads.isEmpty
            ? const EmptyStateView(message: 'Nenhum lead encontrado')
            : RefreshIndicator(
                onRefresh: () => ref.read(leadsNotifierProvider.notifier).refresh(),
                child: ListView.builder(
                  itemCount: leads.length,
                  itemBuilder: (_, i) => LeadCard(lead: leads[i]),
                ),
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
| Auth global (role, redirect) | **BLoC + Freezed** | Broadcast via `BlocListener` para múltiplas telas |
| Leads, Briefing, Agenda, Propostas | **AsyncNotifierProvider** | Async nativo, cache, paginação, invalidação |
| Formulários e ações pontuais | **NotifierProvider** | Estado síncrono com lógica encapsulada |
| Filtros, tema, tab selecionada | **StateProvider** | Sem lógica, só armazena valor |
| Animações, foco, scroll | **StatefulWidget** | Escopo restrito ao widget |

### Regra de ouro

> A UI **nunca** chama HTTP diretamente. O fluxo é sempre:
> `Widget → Provider/BLoC → UseCase → Repository → Datasource → FastAPI`

---

## Auth — Feature Especial (BLoC + Freezed)

Usa BLoC porque o estado precisa ser ouvido em múltiplos pontos simultaneamente (GoRouter redirect + AppBar + Shell).

```dart
// features/auth/presentation/bloc/auth_event.dart
@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.checkRequested()                            = AuthCheckRequested;
  const factory AuthEvent.loginRequested(String email, String pass)   = AuthLoginRequested;
  const factory AuthEvent.logoutRequested()                           = AuthLogoutRequested;
}

// features/auth/presentation/bloc/auth_state.dart
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial()                    = AuthInitial;
  const factory AuthState.loading()                    = AuthLoading;
  const factory AuthState.authenticated(AuthUser user) = AuthAuthenticated;
  const factory AuthState.unauthenticated()             = AuthUnauthenticated;
  const factory AuthState.failure(String message)      = AuthFailure;
}
```

`AuthUser` inclui o campo `role: UserRole` (agency | client) para o redirect do GoRouter.

Redirecionamento pós-login no `app.dart`:
```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    state.whenOrNull(
      authenticated: (user) {
        user.role == UserRole.agency
            ? context.go('/agency/dashboard')
            : context.go('/client/status');
      },
      unauthenticated: (_) => context.go('/auth/login'),
    );
  },
)
```

---

## Shell — Navegação com Abas Persistentes por Role

```dart
// features/shell/presentation/pages/main_shell_page.dart
class MainShellPage extends ConsumerWidget {
  const MainShellPage({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tabs = user?.role == UserRole.agency ? _agencyTabs : _clientTabs;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        tabs: tabs,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

// Abas Agência
const _agencyTabs = [
  NavTab(label: 'Dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard),
  NavTab(label: 'Leads',     icon: Icons.people_outline,     activeIcon: Icons.people),
  NavTab(label: 'Agenda',    icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today),
];

// Abas Cliente
const _clientTabs = [
  NavTab(label: 'Status',    icon: Icons.flight_takeoff_outlined, activeIcon: Icons.flight_takeoff),
  NavTab(label: 'Histórico', icon: Icons.history,              activeIcon: Icons.history),
  NavTab(label: 'Docs',      icon: Icons.folder_outlined,      activeIcon: Icons.folder),
  NavTab(label: 'Perfil',    icon: Icons.person_outline,       activeIcon: Icons.person),
];
```

---

## Features do Projeto — Checklist

- [x] **auth** — login JWT + Firebase Auth, email/senha, registro
- [ ] **splash** — decide rota inicial por auth state e role
- [ ] **shell** — navegação com abas persistentes (bifurca por role)
- [ ] **agency/dashboard** — KPIs do dia: total leads, novos, agendamentos pendentes
- [ ] **agency/leads** — lista com filtros (status, score, destino, período), busca, paginação
- [ ] **agency/leads/detail** — briefing completo, interações, ações rápidas, timeline de status
- [ ] **agency/agenda** — calendário semanal (09h–16h, Seg–Sex), criar/confirmar/cancelar agendamentos
- [ ] **agency/propostas** — criar proposta vinculada a lead, ciclo rascunho → enviada → aprovada
- [ ] **client/status** — status atual da viagem com barra de progresso visual
- [ ] **client/historico** — timeline de conversas com AYA e consultor
- [ ] **client/documentos** — visualizar roteiros, vouchers, comprovantes da agência
- [ ] **client/perfil** — dados pessoais, preferências de viagem
- [ ] **notifications** — central de notificações FCM (agência recebe novos leads em < 2s)

---

## Convenções de Nomenclatura

| Elemento | Convenção | Exemplo Cadife |
|---|---|---|
| Arquivo | snake_case | `leads_repository_impl.dart` |
| Classe | PascalCase | `LeadsRepositoryImpl` |
| Provider (Riverpod) | camelCase + sufixo | `leadsNotifierProvider` |
| Entidade | singular, sem sufixo | `Lead`, `Briefing` (não `LeadEntity`) |
| Model de API | singular + ApiModel | `LeadApiModel`, `BriefingApiModel` |
| UseCase | verbo + UseCase | `GetLeadsUseCase`, `UpdateLeadStatusUseCase` |
| Interface | prefixo `I` | `ILeadsRepository`, `ILeadsDatasource` |
| BLoC event | sufixo freezed | `AuthLoginRequested`, `AuthLogoutRequested` |
| Página | sufixo Page | `LeadsListPage`, `LeadDetailPage` |
| Widget local | sem sufixo especial | `LeadCard`, `ScoreBadge`, `BriefingSection` |
| Notifier Riverpod | sufixo Notifier | `LeadsNotifier`, `AgendaNotifier` |

---

## Dependências (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_bloc: ^8.1.6
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  freezed_annotation: ^2.4.4

  # Routing
  go_router: ^14.2.7

  # Network
  dio: ^5.4.3+1

  # Firebase (Auth + FCM)
  firebase_core: ^3.3.0
  firebase_auth: ^5.1.4
  firebase_messaging: ^15.0.4

  # Storage
  flutter_secure_storage: ^9.2.2   # JWT tokens
  isar: ^3.1.0+1                   # cache local (offline-first)
  isar_flutter_libs: ^3.1.0+1
  shared_preferences: ^2.3.1

  # Segurança
  local_auth: ^2.3.0               # biometria
  # certificate pinning via dio interceptor

  # Utils
  fpdart: ^1.1.0                   # Either / Option
  equatable: ^2.0.5
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.11
  freezed: ^2.5.7
  riverpod_generator: ^2.4.3
  isar_generator: ^3.1.0+1
  mockito: ^5.4.4
```

---

## Regras de Ouro

1. **UI nunca chama HTTP diretamente** — sempre via Provider → UseCase → Repository → Datasource
2. **Cores e tipografia apenas via `AppColors` / `AppTypography`** — nunca hardcode hex ou font name em widget
3. **Estado remoto via `AsyncNotifierProvider`** — nunca `setState` para dados da API
4. **Repositório sempre retorna `Either<Failure, T>`** — nunca lança exceção para cima
5. **Mock controlado por `kUseMockData`** — em `constants.dart`, sem `if` espalhado por features
6. **Features isoladas** — uma feature não importa outra diretamente; comunica via `core/providers`
7. **`design_system.dart` é o único import** — nunca importe tokens individualmente fora do design system
8. **Soft delete em dados críticos** — nunca delete físico de lead (segue regra do backend)
9. **Navegação exclusivamente via GoRouter** — nunca `Navigator.push` diretamente
10. **Nenhuma credencial hardcoded** — sempre `String.fromEnvironment` ou variável de ambiente
11. **Perfis isolados** — `agency/` e `client/` nunca compartilham widgets ou providers diretamente
12. **Feedback visual obrigatório** — loading + error + empty state em toda ação assíncrona
