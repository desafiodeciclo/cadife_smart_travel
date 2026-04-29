# Regra de Comportamento: Flutter Frontend — Cadife Smart Travel

## Contexto

Para manter consistência no App Flutter do Cadife Smart Travel (perfis Agência e Cliente), garantindo design system correto da Cadife Tour, gerenciamento de estado com Riverpod e padrões de UX adequados para consultores não-técnicos.

## Instruções para o Claude

### Regra 1 — Estado remoto via AsyncNotifierProvider

**Sempre** use `AsyncNotifierProvider` para dados que vêm da API. **Nunca** use `setState` para dados remotos.

Exemplo Aceito:
```dart
@riverpod
class LeadsNotifier extends _$LeadsNotifier {
  @override
  Future<List<Lead>> build() async {
    return ref.read(leadsRepositoryProvider).getLeads();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(leadsRepositoryProvider).getLeads());
  }
}
```

Exemplo Recusado:
```dart
class LeadsScreen extends StatefulWidget {
  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}
class _LeadsScreenState extends State<LeadsScreen> {
  List<Lead> leads = [];
  // setState para dados remotos = impossível testar e cache fraco
  void loadLeads() async {
    final data = await api.getLeads();
    setState(() => leads = data);
  }
}
```

### Regra 2 — Repositório pattern obrigatório

**Sempre** crie um `*_repository.dart` entre o provider e a chamada HTTP. **Nunca** use `Dio` diretamente dentro de um Notifier ou Widget.

Exemplo Aceito:
```dart
// lib/features/agency/leads/leads_repository.dart
class LeadsRepository {
  final ApiService _api;
  LeadsRepository(this._api);

  Future<List<Lead>> getLeads({LeadStatus? status, LeadScore? score}) async {
    final response = await _api.get('/leads', queryParameters: {
      if (status != null) 'status': status.name,
      if (score != null) 'score': score.name,
    });
    return (response.data as List).map((e) => Lead.fromJson(e)).toList();
  }
}
```

Exemplo Recusado:
```dart
// Dentro de um Notifier — acoplamento direto
final dio = Dio();
final response = await dio.get('http://api/leads'); // sem interceptors, sem tratamento
```

### Regra 3 — Cores e fontes SOMENTE via AppColors / AppTheme

**Nunca** hardcode valores hexadecimais ou nomes de fonte em widgets.

Exemplo Aceito:
```dart
// lib/core/theme/app_colors.dart
class AppColors {
  static const Color primary = Color(0xFFdd0b0e);
  static const Color background = Color(0xFF393532);
  static const Color scaffold = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF1E8449);
  static const Color warning = Color(0xFFD35400);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5D6D7E);
  static const Color cardBackground = Color(0xFFF8F9FA);
}

// Uso no widget:
Container(color: AppColors.background)
```

Exemplo Recusado:
```dart
Container(color: Color(0xFF393532))  // cor hardcoded — quebra o design system
Text("Leads", style: TextStyle(color: Color(0xFFdd0b0e)))
```

### Regra 4 — Feedback visual obrigatório em toda ação

**Sempre** implemente loading, success e error states. **Nunca** deixe a UI silenciosa após uma ação.

Exemplo Aceito:
```dart
Widget build(BuildContext context, WidgetRef ref) {
  final leadsAsync = ref.watch(leadsNotifierProvider);
  return leadsAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => ErrorWidget(message: 'Erro ao carregar leads. Tente novamente.'),
    data: (leads) => LeadsList(leads: leads),
  );
}
```

Exemplo Recusado:
```dart
Widget build(BuildContext context, WidgetRef ref) {
  final leads = ref.watch(leadsNotifierProvider).value ?? [];
  return LeadsList(leads: leads);  // sem loading, sem erro — UI silent fail
}
```

### Regra 5 — Navegação exclusivamente via GoRouter

**Sempre** use `context.go()` ou `context.push()` do GoRouter. **Nunca** use `Navigator.push` diretamente.

Exemplo Aceito:
```dart
// lib/core/router/app_router.dart
final router = GoRouter(
  redirect: (context, state) {
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    if (!isLoggedIn && !state.matchedLocation.startsWith('/auth')) {
      return '/auth/login';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/agency/leads/:id', builder: (_, state) => LeadDetailScreen(id: state.pathParameters['id']!)),
  ],
);

// Uso:
context.go('/agency/leads/${lead.id}');
```

Exemplo Recusado:
```dart
Navigator.push(context, MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)));
// sem guard de auth, sem deep link, não testável
```

### Regra 6 — Score e status do lead com cores semânticas

**Sempre** mapeie scores e status para as cores corretas do design system.

Exemplo Aceito:
```dart
Color scoreColor(LeadScore score) => switch (score) {
  LeadScore.quente => AppColors.success,   // #1E8449
  LeadScore.morno  => AppColors.warning,   // #D35400
  LeadScore.frio   => AppColors.textSecondary,
};
```

### Regra 7 — Separação de perfis Agency / Client

**Nunca** misture widgets ou lógica dos perfis Agência e Cliente no mesmo arquivo. Cada feature tem seu próprio diretório em `lib/features/agency/` ou `lib/features/client/`.
