import 'package:cadife_smart_travel/core/router/agency_shell.dart';
import 'package:cadife_smart_travel/core/router/client_shell.dart';
import 'package:cadife_smart_travel/features/agency/agenda/agenda_screen.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/dashboard_screen.dart';
import 'package:cadife_smart_travel/features/agency/leads/lead_detail_screen.dart';
import 'package:cadife_smart_travel/features/agency/leads/leads_screen.dart';
import 'package:cadife_smart_travel/features/auth/auth_notifier.dart';
import 'package:cadife_smart_travel/features/auth/login_screen.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/login_screen.dart';
import 'package:cadife_smart_travel/features/client/documentos/documentos_screen.dart';
import 'package:cadife_smart_travel/features/client/historico/historico_screen.dart';
import 'package:cadife_smart_travel/features/client/status/status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    initialLocation: '/auth/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isLogged = auth.isLoggedIn;
      final loc = state.matchedLocation;
      final isAuthRoute = loc.startsWith('/auth');

      if (!isLogged && !isAuthRoute) return '/auth/login';

      if (isLogged && isAuthRoute) {
        return auth.userPerfil == 'agencia'
            ? '/agency/dashboard'
            : '/client/status';
      }

      // Cross-role guard
      if (isLogged &&
          auth.userPerfil == 'agencia' &&
          loc.startsWith('/client')) {
        return '/agency/dashboard';
      }
      if (isLogged &&
          auth.userPerfil == 'cliente' &&
          loc.startsWith('/agency')) {
        return '/client/status';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/login',
        pageBuilder: (_, state) =>
            NoTransitionPage(key: state.pageKey, child: const LoginScreen()),
      ),

      // Agency shell — persistent BottomNavBar with SharedAxis tab transitions
      ShellRoute(
        builder: (context, state, child) => AgencyShell(
          key: const ValueKey('agency-shell'),
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/agency/dashboard',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/agency/leads',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const LeadsScreen(),
            ),
          ),
          GoRoute(
            path: '/agency/agenda',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AgendaScreen(),
            ),
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
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/client/status',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const StatusScreen(),
            ),
          ),
          GoRoute(
            path: '/client/historico',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HistoricoScreen(),
            ),
          ),
          GoRoute(
            path: '/client/documentos',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DocumentosScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
