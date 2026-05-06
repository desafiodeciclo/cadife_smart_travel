import 'package:cadife_smart_travel/config/router/agency_shell.dart';
import 'package:cadife_smart_travel/config/router/client_shell.dart';
import 'package:cadife_smart_travel/config/router/transitions/custom_page_route.dart';
import 'package:cadife_smart_travel/core/analytics/analytics_navigation_observer.dart';
import 'package:cadife_smart_travel/features/agency/agenda/presentation/pages/agenda_page.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/dashboard_screen.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/pages/lead_detail_page.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/pages/leads_page.dart';
import 'package:cadife_smart_travel/features/agency/perfil/presentation/pages/profile_page.dart';
import 'package:cadife_smart_travel/features/agency/propostas/presentation/pages/proposal_create_page.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/login_screen.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/register_screen.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/splash_screen.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/pages/document_viewer_page.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/pages/documentos_page.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/pages/trip_documents_page.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/pages/travel_briefing_screen.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/pages/profile_page.dart' as client_profile;
import 'package:cadife_smart_travel/features/client/status/presentation/pages/status_page.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    observers: [AnalyticsNavigationObserver()],
    refreshListenable: notifier,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authValue = ref.read(authNotifierProvider);
      final bool isLoggingIn = state.matchedLocation.startsWith('/auth');

      return authValue.when(
        loading: () =>
            state.matchedLocation == '/splash' ? null : '/splash',
        error: (_, _) =>
            isLoggingIn ? null : '/auth/login',
        data: (user) {
          if (user == null) return isLoggingIn ? null : '/auth/login';

          if (isLoggingIn || state.matchedLocation == '/splash') {
            return user.role == UserRole.consultor
                ? '/agency/dashboard'
                : '/client/status';
          }

          final isAgencyRoute = state.matchedLocation.startsWith('/agency');
          final isClientRoute = state.matchedLocation.startsWith('/client');

          if (isAgencyRoute && user.role != UserRole.consultor) {
            return '/client/status';
          }
          if (isClientRoute && user.role == UserRole.consultor) {
            return '/agency/dashboard';
          }

          return null;
        },
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        name: 'forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Notifications — accessible to both roles
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),

      // Agency flow (Consultor)
      ShellRoute(
        builder: (context, state, child) {
          return AgencyShell(location: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(
            path: '/agency/dashboard',
            name: 'agency_dashboard',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/agency/leads',
            name: 'agency_leads',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const LeadsPage(),
            ),
            routes: [
              // Path-param route for deep linking via FCM
              GoRoute(
                path: ':leadId',
                name: 'agency_lead_details',
                pageBuilder: (context, state) {
                  final leadId = state.pathParameters['leadId']!;
                  return SlideTransitionPage(
                    name: state.name,
                    child: LeadDetailPage(leadId: leadId),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/agency/proposals/:leadId',
            name: 'agency_proposal_create',
            builder: (context, state) {
              final leadId = state.pathParameters['leadId']!;
              return Consumer(
                builder: (context, ref, _) {
                  final consultorId =
                      ref.watch(authNotifierProvider).valueOrNull?.id ?? '';
                  return ProposalCreateScreen(
                    leadId: leadId,
                    consultorId: consultorId,
                  );
                },
              );
            },
          ),
          GoRoute(
            path: '/agency/agenda',
            name: 'agency_agenda',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const AgendaScreen(),
            ),
          ),
          GoRoute(
            path: '/agency/profile',
            name: 'agency_profile',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const ConsultorProfileScreen(),
            ),
          ),
        ],
      ),

      // Client flow
      ShellRoute(
        builder: (context, state, child) {
          return ClientShell(location: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(
            path: '/client/status',
            name: 'client_status',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const StatusPage(),
            ),
          ),
          GoRoute(
            path: '/client/interactions',
            name: 'client_history',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const TravelBriefingScreen(),
            ),
            routes: [
              GoRoute(
                path: ':tripId',
                name: 'client_trip_details',
                pageBuilder: (context, state) {
                  final tripId = state.pathParameters['tripId']!;
                  return SlideTransitionPage(
                    name: state.name,
                    child: TravelBriefingScreen(tripId: tripId),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/client/documents',
            name: 'client_documents',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const DocumentosPage(),
            ),
            routes: [
              GoRoute(
                path: 'viewer',
                name: 'client_document_viewer',
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
                name: 'client_trip_documents',
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
            path: '/client/profile',
            name: 'client_profile',
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
  _RouterNotifier(Ref ref) {
    ref.listen<AsyncValue<AuthUser?>>(
      authNotifierProvider,
      (_, _) => notifyListeners(),
    );
  }
}
