import 'package:cadife_smart_travel/config/dev/component_library_page.dart';
import 'package:cadife_smart_travel/config/router/agency_shell.dart';
import 'package:cadife_smart_travel/config/router/client_shell.dart';
import 'package:cadife_smart_travel/config/router/transitions/custom_page_route.dart';
import 'package:cadife_smart_travel/core/analytics/analytics_navigation_observer.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/dashboard_screen.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/pages/lead_detail_page.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/pages/lead_edit_page.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/pages/leads_page.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/pages/manual_lead_create_page.dart';
import 'package:cadife_smart_travel/features/agency/offers/presentation/screens/offer_form_screen.dart';
import 'package:cadife_smart_travel/features/agency/offers/presentation/screens/offers_management_screen.dart';
import 'package:cadife_smart_travel/features/agency/propostas/presentation/pages/proposal_create_page.dart';
import 'package:cadife_smart_travel/features/agency/propostas/presentation/pages/proposals_page.dart';
import 'package:cadife_smart_travel/features/agency/agenda/presentation/pages/agenda_page.dart';
import 'package:cadife_smart_travel/features/admin/presentation/pages/admin_overview_page.dart';
import 'package:cadife_smart_travel/features/admin/presentation/pages/admin_consultant_list_page.dart';
import 'package:cadife_smart_travel/features/admin/presentation/pages/create_consultant_page.dart';
import 'package:cadife_smart_travel/features/admin/presentation/pages/consultor_detail_page.dart';
import 'package:cadife_smart_travel/features/admin/presentation/pages/consultor_edit_page.dart';
import 'package:cadife_smart_travel/features/admin/presentation/pages/admin_all_leads_page.dart';
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

      debugPrint('ROUTER: redirect location=${state.matchedLocation} authState=${authValue.runtimeType} isLoggingIn=$isLoggingIn');

      return authValue.when(
        loading: () {
          debugPrint('ROUTER: Auth state is loading, redirecting to /splash');
          return state.matchedLocation == '/splash' ? null : '/splash';
        },
        error: (error, _) {
          debugPrint('ROUTER: Auth error: $error, redirecting to /auth/login');
          return isLoggingIn ? null : '/auth/login';
        },
        data: (user) {
          if (user == null) {
            debugPrint('ROUTER: No user found, isLoggingIn=$isLoggingIn');
            return isLoggingIn ? null : '/auth/login';
          }

          debugPrint('ROUTER: User logged in: ${user.email} role=${user.role}');

          // Se estiver na tela de login/onboarding ou splash, vai para o dashboard correto
          if (isLoggingIn || state.matchedLocation == '/splash' || state.matchedLocation == '/onboarding' || state.matchedLocation == '/') {
            if (user.role == UserRole.admin) {
              debugPrint('ROUTER: Redirecting to Admin Overview: /agency/admin');
              return '/agency/admin';
            }
            if (user.role == UserRole.consultor) {
              debugPrint('ROUTER: Redirecting to Consultant Dashboard: /agency/dashboard');
              return '/agency/dashboard';
            }
            debugPrint('ROUTER: Redirecting to Client Status: /client/status');
            return '/client/status';
          }

          // Proteção de rotas
          final isAgencyRoute = state.matchedLocation.startsWith('/agency');
          final isClientRoute = state.matchedLocation.startsWith('/client');
          final isAdminRoute = state.matchedLocation.startsWith('/agency/admin');

          if (isAdminRoute && user.role != UserRole.admin) {
            debugPrint('ROUTER: Unauthorized access to admin route, redirecting to /agency/dashboard');
            return '/agency/dashboard';
          }
          if (isAgencyRoute && user.role != UserRole.consultor && user.role != UserRole.admin) {
            debugPrint('ROUTER: Unauthorized access to agency route, redirecting to /client/status');
            return '/client/status';
          }
          if (isClientRoute && (user.role == UserRole.consultor || user.role == UserRole.admin)) {
            debugPrint('ROUTER: Unauthorized access to client route, redirecting to /agency/dashboard');
            return '/agency/dashboard';
          }

          debugPrint('ROUTER: No redirection needed for ${state.matchedLocation}');
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
        builder: (context, state) => Scaffold(body: Center(child: Text('Lead: ${state.pathParameters['leadId']}'))),
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
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'agency_lead_edit',
                    pageBuilder: (context, state) {
                      final leadId = state.pathParameters['leadId']!;
                      return SlideTransitionPage(
                        name: state.name,
                        child: LeadEditPage(leadId: leadId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/agency/proposals/:leadId',
            name: 'agency_proposals',
            builder: (context, state) {
              final leadId = state.pathParameters['leadId']!;
              return ProposalsPage(leadId: leadId);
            },
            routes: [
              GoRoute(
                path: 'new',
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
            ],
          ),
          GoRoute(
            path: '/agency/offers',
            name: 'agency_offers',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const OffersManagementScreen(),
            ),
            routes: [
              GoRoute(
                path: 'create',
                name: 'agency_offer_create',
                pageBuilder: (context, state) => SlideTransitionPage(
                  name: state.name,
                  child: const OfferFormScreen(),
                ),
              ),
              GoRoute(
                path: ':offerId/edit',
                name: 'agency_offer_edit',
                pageBuilder: (context, state) {
                  final offerId = state.pathParameters['offerId']!;
                  return SlideTransitionPage(
                    name: state.name,
                    child: OfferFormScreen(offerId: offerId),
                  );
                },
              ),
            ],
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
          // Admin routes (protected by AdminGuard redirect above)
          GoRoute(
            path: '/agency/admin',
            name: 'agency_admin',
            redirect: (context, state) => '/agency/admin/overview',
          ),
          GoRoute(
            path: '/agency/admin/overview',
            name: 'agency_admin_overview',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const AdminOverviewPage(),
            ),
          ),
          GoRoute(
            path: '/agency/admin/consultants',
            name: 'agency_admin_consultants',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const AdminConsultantListPage(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'agency_admin_consultant_new',
                pageBuilder: (context, state) => SlideTransitionPage(
                  name: state.name,
                  child: const CreateConsultantPage(),
                ),
              ),
              GoRoute(
                path: ':consultantId',
                name: 'agency_admin_consultant_details',
                pageBuilder: (context, state) {
                  final consultantId = state.pathParameters['consultantId']!;
                  return SlideTransitionPage(
                    name: state.name,
                    child: ConsultorDetailPage(consultorId: consultantId),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'agency_admin_consultant_edit',
                    pageBuilder: (context, state) {
                      final consultantId = state.pathParameters['consultantId']!;
                      return SlideTransitionPage(
                        name: state.name,
                        child: ConsultorEditPage(consultorId: consultantId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/agency/admin/leads',
            name: 'agency_admin_leads',
            pageBuilder: (context, state) => SlideTransitionPage(
              name: state.name,
              child: const AdminAllLeadsPage(),
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
            pageBuilder: (context, state) {
              final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
              return SlideTransitionPage(
                name: state.name,
                child: client_profile.ProfileScreen(initialTabIndex: tab),
              );
            },
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

      // Diary detail — full-screen (no bottom nav), pushable from outside ShellRoute
      GoRoute(
        path: '/client/profile/diary/:tripId',
        name: 'client_diary_detail',
        pageBuilder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return SlideTransitionPage(
            name: state.name,
            child: TravelJournalDetailScreen(tripId: tripId),
          );
        },
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
      GoRoute(
        path: '/client/travel/:tripId/details',
        name: 'client_travel_details',
        pageBuilder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return SlideTransitionPage(
            name: state.name,
            child: TripDetailsScreen(tripId: tripId),
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
