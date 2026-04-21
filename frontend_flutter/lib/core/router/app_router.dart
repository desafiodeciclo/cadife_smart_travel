import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_notifier.dart';
import '../../features/auth/login_screen.dart';
import '../../features/agency/dashboard/dashboard_screen.dart';
import '../../features/agency/leads/leads_screen.dart';
import '../../features/agency/leads/lead_detail_screen.dart';
import '../../features/agency/agenda/agenda_screen.dart';
import '../../features/client/status/status_screen.dart';
import '../../features/client/historico/historico_screen.dart';
import '../../features/client/documentos/documentos_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/auth/login',
    redirect: (context, state) {
      final isLogged = authState.isLoggedIn;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLogged && !isAuthRoute) return '/auth/login';
      if (isLogged && isAuthRoute) {
        return authState.userPerfil == 'agencia' ? '/agency/dashboard' : '/client/status';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/auth/login', builder: (_, _) => const LoginScreen()),

      // Agency routes
      GoRoute(path: '/agency/dashboard', builder: (_, _) => const DashboardScreen()),
      GoRoute(path: '/agency/leads', builder: (_, _) => const LeadsScreen()),
      GoRoute(
        path: '/agency/leads/:id',
        builder: (_, state) => LeadDetailScreen(leadId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/agency/agenda', builder: (_, _) => const AgendaScreen()),

      // Client routes
      GoRoute(path: '/client/status', builder: (_, _) => const StatusScreen()),
      GoRoute(path: '/client/historico', builder: (_, _) => const HistoricoScreen()),
      GoRoute(path: '/client/documentos', builder: (_, _) => const DocumentosScreen()),
    ],
  );
});
