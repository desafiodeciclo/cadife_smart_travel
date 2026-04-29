import 'package:cadife_smart_travel/core/router/agency_shell.dart';
import 'package:cadife_smart_travel/core/router/client_shell.dart';
import 'package:cadife_smart_travel/features/agency/agenda/agenda_screen.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/dashboard_screen.dart';
import 'package:cadife_smart_travel/features/agency/leads/lead_detail_screen.dart';
import 'package:cadife_smart_travel/features/agency/leads/lead_edit_screen.dart';
import 'package:cadife_smart_travel/features/agency/leads/leads_screen.dart';
import 'package:cadife_smart_travel/features/agency/proposals/proposal_create_screen.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/login_screen.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/register_screen.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/splash_screen.dart';
import 'package:cadife_smart_travel/features/auth/providers/auth_provider.dart';
import 'package:cadife_smart_travel/features/client/documentos/documentos_screen.dart';
import 'package:cadife_smart_travel/features/client/historico/historico_screen.dart';
import 'package:cadife_smart_travel/features/client/profile/profile.dart';
import 'package:cadife_smart_travel/features/client/status/status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Bridges Riverpod auth state to GoRouter's refreshListenable
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AsyncValue<AuthState>>(authProvider, (_, _) => notifyListeners());
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
      final loc = state.matchedLocation;

      // Splash gerencia sua própria navegação — não redirecionar daqui
      if (loc == '/splash') return null;

      final authValue = ref.read(authProvider);
      final auth = authValue.valueOrNull;
      final isLogged = auth?.isAuthenticated ?? false;
      final isAuthRoute = loc.startsWith('/auth');

      if (!isLogged && !isAuthRoute) return '/auth/login';

      if (isLogged && isAuthRoute) {
        return auth?.userPerfil == 'agencia'
            ? '/agency/dashboard'
            : '/client/status';
      }

      // Cross-role guard
      if (isLogged &&
          auth?.userPerfil == 'agencia' &&
          loc.startsWith('/client')) {
        return '/agency/dashboard';
      }
      if (isLogged &&
          auth?.userPerfil == 'cliente' &&
          loc.startsWith('/agency')) {
        return '/client/status';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (_, state) =>
            NoTransitionPage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/auth/login',
        pageBuilder: (_, state) =>
            NoTransitionPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        pageBuilder: (_, state) => MaterialPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/register',
        pageBuilder: (_, state) => MaterialPage(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
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

      // Lead edit — full-screen push without BottomNavBar
      GoRoute(
        path: '/agency/leads/:id/edit',
        pageBuilder: (_, state) => MaterialPage(
          key: state.pageKey,
          child: LeadEditScreen(leadId: state.pathParameters['id']!),
        ),
      ),

      // Proposal create — full-screen modal
      GoRoute(
        path: '/agency/proposals/new',
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, String>? ?? {};
          return MaterialPage(
            key: state.pageKey,
            child: ProposalCreateScreen(
              leadId: extra['leadId'] ?? '',
              consultorId: extra['consultorId'] ?? '',
            ),
          );
        },
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
          GoRoute(
            path: '/client/perfil',
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}
