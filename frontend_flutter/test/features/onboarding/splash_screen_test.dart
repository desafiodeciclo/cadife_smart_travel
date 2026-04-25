import 'package:cadife_smart_travel/features/auth/auth_notifier.dart';
import 'package:cadife_smart_travel/features/onboarding/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ── MockAuthNotifier ──────────────────────────────────────────────────────────
// Estende StateNotifier diretamente para controlar o estado sem mocktail,
// pois StateNotifier.state é um setter protegido inacessível via Mock.

class _MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _MockAuthNotifier(super.initialState);

  @override
  Future<void> checkSession() async {
    // no-op: estado já configurado no construtor
  }

  @override
  Future<void> login(String email, String password) async {}

  @override
  Future<void> logout() async {}
}

// ── Captura de navegação ──────────────────────────────────────────────────────

class _NavRecorder {
  String? lastLocation;
}

GoRouter _buildRouter(Widget home, _NavRecorder recorder) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => home),
      GoRoute(
        path: '/agency/dashboard',
        builder: (_, _) {
          recorder.lastLocation = '/agency/dashboard';
          return const Scaffold(body: Text('Agency Dashboard'));
        },
      ),
      GoRoute(
        path: '/client/status',
        builder: (_, _) {
          recorder.lastLocation = '/client/status';
          return const Scaffold(body: Text('Client Status'));
        },
      ),
      GoRoute(
        path: '/auth/login',
        builder: (_, _) {
          recorder.lastLocation = '/auth/login';
          return const Scaffold(body: Text('Login'));
        },
      ),
    ],
  );
}

Widget _buildApp(AuthState initialState, _NavRecorder recorder) {
  final notifier = _MockAuthNotifier(initialState);
  final router = _buildRouter(const SplashScreen(), recorder);
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((_) => notifier),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('SplashScreen', () {
    testWidgets('1. Renderiza sem crash — exibe nome do app', (tester) async {
      final recorder = _NavRecorder();
      await tester.pumpWidget(
        _buildApp(const AuthState(isLoggedIn: false), recorder),
      );
      await tester.pump();

      // Lottie.asset falha em testes (sem bundle real), mas o errorBuilder
      // exibe Icons.travel_explore sem lançar exceção.
      expect(find.text('Cadife Smart Travel'), findsOneWidget);

      // Avança o timer de 2s do Future.delayed em _initialize() para evitar
      // "A Timer is still pending" ao descartar o widget tree.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });

    testWidgets('2. Sessão válida + perfil agencia → navega para /agency/dashboard',
        (tester) async {
      final recorder = _NavRecorder();
      await tester.pumpWidget(
        _buildApp(
          const AuthState(isLoggedIn: true, userPerfil: 'agencia'),
          recorder,
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(recorder.lastLocation, equals('/agency/dashboard'));
      expect(find.text('Agency Dashboard'), findsOneWidget);
    });

    testWidgets('3. Sessão válida + perfil cliente → navega para /client/status',
        (tester) async {
      final recorder = _NavRecorder();
      await tester.pumpWidget(
        _buildApp(
          const AuthState(isLoggedIn: true, userPerfil: 'cliente'),
          recorder,
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(recorder.lastLocation, equals('/client/status'));
      expect(find.text('Client Status'), findsOneWidget);
    });

    testWidgets('4. Sem sessão → navega para /auth/login', (tester) async {
      final recorder = _NavRecorder();
      await tester.pumpWidget(
        _buildApp(const AuthState(isLoggedIn: false), recorder),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(recorder.lastLocation, equals('/auth/login'));
      expect(find.text('Login'), findsOneWidget);
    });
  });
}
