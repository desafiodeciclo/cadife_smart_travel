import 'package:cadife_smart_travel/config/dev/component_library_page.dart';
import 'package:cadife_smart_travel/config/router/agency_shell.dart';
import 'package:cadife_smart_travel/config/router/client_shell.dart';
import 'package:cadife_smart_travel/config/router/transitions/custom_page_route.dart';
import 'package:cadife_smart_travel/core/analytics/analytics_navigation_observer.dart';
import 'package:cadife_smart_travel/features/agency/agenda/presentation/pages/agenda_page.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/dashboard_screen.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/pages/lead_detail_page.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/pages/leads_page.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/pages/manual_lead_create_page.dart';
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
import 'package:cadife_smart_travel/features/client/historico/presentation/pages/historico_page.dart';
import 'package:cadife_smart_travel/features/client/home/presentation/screens/client_home_screen.dart';
import 'package:cadife_smart_travel/features/client/home/presentation/screens/trip_details_screen.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/pages/travel_calendar_page.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/screens/offer_details_page.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/screens/offers_list_page.dart';
import 'package:cadife_smart_travel/features/client/profile/presentation/pages/profile_page.dart' as client_profile;
import 'package:cadife_smart_travel/features/client/profile/presentation/pages/travel_journal_detail_screen.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:cadife_smart_travel/screens/consultant/lead_detail_screen.dart';
import 'package:cadife_smart_travel/screens/consultant/profile_screen.dart';
import 'package:cadife_smart_travel/screens/settings_screen.dart';
import 'package:flutter/foundation.dart';
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
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => SlideTransitionPage(
          name: state.name,
          child: const NotificationCenterScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => SlideTransitionPage(
          name: state.name,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/consultant/leads/:leadId',
        name: 'leadDetail',
        builder: (context, state) => LeadDetailScreen(
          leadId: state.pathParameters['leadId']!,
        ),
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
              GoRoute(
                path: 'new',
                name: 'agency_lead_new',
                pageBuilder: (context, state) => SlideTransitionPage(
                  name: state.name,
                  child: const ManualLeadCreatePage(),
                ),
              ),
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
              child: const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/agency/settings',
            name: 'agency_settings',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const SettingsScreen(),
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
              child: const ClientHomeScreen(),
            ),
          ),
          GoRoute(
            path: '/client/offers',
            name: 'client_offers',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const OffersListPage(),
            ),
            routes: [
              GoRoute(
                path: ':offerId',
                name: 'client_offer_details',
                pageBuilder: (context, state) {
                  final offerId = state.pathParameters['offerId']!;
                  final offer = state.extra as Offer?;
                  return SlideTransitionPage(
                    name: state.name,
                    child: OfferDetailsPage(offerId: offerId, offer: offer),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/client/interactions',
            name: 'client_history',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const HistoricoPage(),
            ),
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
            routes: [
              GoRoute(
                path: 'diary/:tripId',
                name: 'client_diary_detail',
                pageBuilder: (context, state) {
                  final tripId = state.pathParameters['tripId']!;
                  return SlideTransitionPage(
                    name: state.name,
                    child: TravelJournalDetailScreen(tripId: tripId),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/client/settings',
            name: 'client_settings',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),

      // Travel Details & Calendar — full-screen detail (no bottom nav)
      GoRoute(
        path: '/client/travel/:tripId',
        name: 'client_trip_details',
        pageBuilder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return SlideTransitionPage(
            name: state.name,
            child: TripDetailsScreen(tripId: tripId),
          );
        },
      ),
      GoRoute(
        path: '/client/travel/:tripId/calendar',
        name: 'client_travel_calendar',
        pageBuilder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return SlideTransitionPage(
            name: state.name,
            child: TravelCalendarPage(tripId: tripId),
          );
        },
      ),

      // DEV ROUTES (apenas em debug)
      if (kDebugMode)
        GoRoute(
          path: '/dev/components',
          name: 'componentLibrary',
          pageBuilder: (context, state) => const MaterialPage(
            child: ComponentLibraryPage(),
          ),
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
