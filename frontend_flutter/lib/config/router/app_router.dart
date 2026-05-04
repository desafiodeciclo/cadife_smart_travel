import 'package:cadife_smart_travel/features/agency/agenda/agenda_screen.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/dashboard_screen.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/pages/lead_detail_page.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/pages/leads_page.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_state.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_bloc_provider.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/login_screen.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/register_screen.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/splash_screen.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/pages/historico_page.dart';
import 'package:cadife_smart_travel/features/client/profile/profile_screen.dart';
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
          return _AgencyShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/agency/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/agency/leads',
            builder: (context, state) => const LeadsPage(),
            routes: [
              GoRoute(
                path: 'details',
                builder: (context, state) {
                  final lead = state.extra as Lead;
                  return LeadDetailPage(leadId: lead.id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/agency/agenda',
            builder: (context, state) => const AgendaScreen(),
          ),
          GoRoute(
            path: '/agency/proposals',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Propostas (Em breve)')),
            ),
          ),
        ],
      ),

      // Fluxo do Cliente
      ShellRoute(
        builder: (context, state, child) {
          return _ClientShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/client/status',
            builder: (context, state) => const StatusPage(),
          ),
          GoRoute(
            path: '/client/historico',
            builder: (context, state) => const HistoricoPage(),
          ),
          GoRoute(
            path: '/client/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class _AgencyShell extends StatelessWidget {
  final Widget child;
  const _AgencyShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/agency/dashboard')) {
      currentIndex = 0;
    } else if (location.startsWith('/agency/leads')) {
      currentIndex = 1;
    } else if (location.startsWith('/agency/agenda')) {
      currentIndex = 2;
    } else if (location.startsWith('/agency/proposals')) {
      currentIndex = 3;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) {
          switch (idx) {
            case 0:
              context.go('/agency/dashboard');
              break;
            case 1:
              context.go('/agency/leads');
              break;
            case 2:
              context.go('/agency/agenda');
              break;
            case 3:
              context.go('/agency/proposals');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.people_outline), label: 'Leads'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined), label: 'Agenda'),
          NavigationDestination(
              icon: Icon(Icons.description_outlined), label: 'Propostas'),
        ],
      ),
    );
  }
}

class _ClientShell extends StatelessWidget {
  final Widget child;
  const _ClientShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/client/status')) {
      currentIndex = 0;
    } else if (location.startsWith('/client/historico')) {
      currentIndex = 1;
    } else if (location.startsWith('/client/profile')) {
      currentIndex = 2;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) {
          switch (idx) {
            case 0:
              context.go('/client/status');
              break;
            case 1:
              context.go('/client/historico');
              break;
            case 2:
              context.go('/client/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Status'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Histórico'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}

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
