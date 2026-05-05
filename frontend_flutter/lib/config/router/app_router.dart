import 'package:cadife_smart_travel/config/router/agency_shell.dart';
import 'package:cadife_smart_travel/config/router/client_shell.dart';
import 'package:cadife_smart_travel/config/router/transitions/custom_page_route.dart';
import 'package:cadife_smart_travel/features/agency/agenda/presentation/pages/agenda_page.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/dashboard_screen.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/pages/lead_detail_page.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/pages/leads_page.dart';
import 'package:cadife_smart_travel/features/agency/perfil/presentation/pages/profile_page.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_state.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_bloc_provider.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/login_screen.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/register_screen.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/splash_screen.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/pages/document_viewer_page.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/pages/documentos_page.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/pages/trip_documents_page.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/pages/historico_page.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/pages/profile_page.dart' as client_profile;
import 'package:cadife_smart_travel/features/client/status/presentation/pages/status_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authBloc = ref.watch(authBlocProvider);
  final notifier = _RouterNotifier(authBloc.stream);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = authBloc.state;
      final bool isLoggingIn = state.matchedLocation.startsWith('/auth');

      if (authState is AuthInitial || authState is AuthLoading) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }

      if (authState is AuthUnauthenticated) {
        return isLoggingIn ? null : '/auth/login';
      }

      if (authState is AuthAuthenticated) {
        if (isLoggingIn || state.matchedLocation == '/splash') {
          return authState.user.role == UserRole.consultor
              ? '/agency/dashboard'
              : '/client/status';
        }

        // Proteção de rotas por role
        final isAgencyRoute = state.matchedLocation.startsWith('/agency');
        final isClientRoute = state.matchedLocation.startsWith('/client');

        if (isAgencyRoute && authState.user.role != UserRole.consultor) {
          return '/client/status';
        }
        if (isClientRoute && authState.user.role == UserRole.consultor) {
          return '/agency/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Fluxo da Agência (Consultor)
      ShellRoute(
        builder: (context, state, child) {
          return AgencyShell(location: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(
            path: '/agency/dashboard',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/agency/leads',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const LeadsPage(),
            ),
            routes: [
              GoRoute(
                path: 'details',
                pageBuilder: (context, state) {
                  final lead = state.extra as Lead;
                  return SlideTransitionPage(
                    name: state.name,
                    child: LeadDetailPage(leadId: lead.id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/agency/agenda',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const AgendaScreen(),
            ),
          ),
          GoRoute(
            path: '/agency/perfil',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const ConsultorProfileScreen(),
            ),
          ),
        ],
      ),

      // Fluxo do Cliente
      ShellRoute(
        builder: (context, state, child) {
          return ClientShell(location: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(
            path: '/client/status',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const StatusPage(),
            ),
          ),
          GoRoute(
            path: '/client/historico',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const HistoricoPage(),
            ),
          ),
          GoRoute(
            path: '/client/documentos',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const DocumentosPage(),
            ),
            routes: [
              GoRoute(
                path: 'viewer',
                pageBuilder: (context, state) {
                  final doc = state.extra as Documento;
                  return SlideTransitionPage(
                    name: state.name,
                    child: DocumentViewerPage(document: doc),
                  );
                },
              ),
              GoRoute(
                path: ':tripId',
                pageBuilder: (context, state) {
                  final tripId = state.pathParameters['tripId']!;
                  return SlideTransitionPage(
                    name: state.name,
                    child: TripDocumentsPage(tripId: tripId),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/client/perfil',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const client_profile.ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Stream stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
