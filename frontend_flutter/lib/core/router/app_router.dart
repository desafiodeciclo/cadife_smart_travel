import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_notifier.dart';
import '../../features/auth/login_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/agency/dashboard/dashboard_screen.dart';
import '../../features/agency/leads/leads_screen.dart';
import '../../features/agency/leads/lead_detail_screen.dart';
import '../../features/agency/agenda/agenda_screen.dart';
import '../../features/client/status/status_screen.dart';
import '../../features/client/historico/historico_screen.dart';
import '../../features/client/documentos/documentos_screen.dart';
import 'agency_shell.dart';
import 'client_shell.dart';

// Bridges Riverpod auth state to GoRouter's refreshListenable
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isLogged = auth.isLoggedIn;
      final loc = state.matchedLocation;
      final isAuthRoute = loc.startsWith('/auth');
      final isSplash = loc == '/splash';

      if (isSplash) return null; // Let SplashScreen handle logic

      if (!isLogged && !isAuthRoute) return '/auth/login';

      if (isLogged && isAuthRoute) {
        return auth.userPerfil == 'agencia'
            ? '/agency/dashboard'
            : '/client/status';
      }

      // Cross-role guard
      if (isLogged && auth.userPerfil == 'agencia' && loc.startsWith('/client')) {
        return '/agency/dashboard';
      }
      if (isLogged && auth.userPerfil == 'cliente' && loc.startsWith('/agency')) {
        return '/client/status';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (_, state) => NoTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/login',
        pageBuilder: (_, state) => NoTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),

      // Agency shell — persistent BottomNavBar with SharedAxis tab transitions
      ShellRoute(
        builder: (context, state, child) => AgencyShell(
          key: const ValueKey('agency-shell'),
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/agency/dashboard',
            pageBuilder: (_, state) =>
                NoTransitionPage(key: state.pageKey, child: const DashboardScreen()),
          ),
          GoRoute(
            path: '/agency/leads',
            pageBuilder: (_, state) =>
                NoTransitionPage(key: state.pageKey, child: const LeadsScreen()),
          ),
          GoRoute(
            path: '/agency/agenda',
            pageBuilder: (_, state) =>
                NoTransitionPage(key: state.pageKey, child: const AgendaScreen()),
          ),
        ],
      ),

      // Lead detail — full-screen push without BottomNavBar
      GoRoute(
        path: '/agency/leads/:id',
        pageBuilder: (_, state) => MaterialPage(
          key: state.pageKey,
          child: LeadDetailScreen(leadId: state.pathParameters['id']!),
        ),
      ),

      // Client shell — persistent BottomNavBar with SharedAxis tab transitions
      ShellRoute(
        builder: (context, state, child) => ClientShell(
          key: const ValueKey('client-shell'),
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/client/status',
            pageBuilder: (_, state) =>
                NoTransitionPage(key: state.pageKey, child: const StatusScreen()),
          ),
          GoRoute(
            path: '/client/historico',
            pageBuilder: (_, state) =>
                NoTransitionPage(key: state.pageKey, child: const HistoricoScreen()),
          ),
          GoRoute(
            path: '/client/documentos',
            pageBuilder: (_, state) =>
                NoTransitionPage(key: state.pageKey, child: const DocumentosScreen()),
          ),
        ],
      ),
    ],
  );
});

class _HomeShell extends StatelessWidget {
  const _HomeShell();

  @override
  Widget build(BuildContext context) {
    return const AppLoadingWidget(message: 'Carregando...');
  }
}

class _AgencyShell extends StatelessWidget {
  const _AgencyShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadife Smart Travel')),
      body: const Center(child: AppLoadingWidget(message: 'Carregando dashboard...')),
    );
  }
}

class _ClientShell extends StatelessWidget {
  const _ClientShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Viagem')),
      body: const Center(child: AppLoadingWidget(message: 'Carregando...')),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title, style: const TextStyle(fontSize: 24))),
    );
  }
}