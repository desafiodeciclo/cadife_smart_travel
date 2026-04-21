import 'package:cadife_smart_travel/features/auth/presentation/screens/login_screen.dart';
import 'package:cadife_smart_travel/features/auth/providers/auth_provider.dart';
import 'package:cadife_smart_travel/shared/widgets/feedback_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/login';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const _HomeShell(),
      ),
      GoRoute(
        path: '/agency',
        builder: (context, state) => const _AgencyShell(),
        routes: [
          GoRoute(
            path: 'dashboard',
            builder: (context, state) => const _PlaceholderScreen(title: 'Dashboard'),
          ),
          GoRoute(
            path: 'leads',
            builder: (context, state) => const _PlaceholderScreen(title: 'Leads'),
          ),
          GoRoute(
            path: 'leads/:id',
            builder: (context, state) => _PlaceholderScreen(
              title: 'Lead ${state.pathParameters['id']}',
            ),
          ),
          GoRoute(
            path: 'agenda',
            builder: (context, state) => const _PlaceholderScreen(title: 'Agenda'),
          ),
          GoRoute(
            path: 'proposals',
            builder: (context, state) => const _PlaceholderScreen(title: 'Propostas'),
          ),
        ],
      ),
      GoRoute(
        path: '/client',
        builder: (context, state) => const _ClientShell(),
        routes: [
          GoRoute(
            path: 'trip/:id',
            builder: (context, state) => _PlaceholderScreen(
              title: 'Viagem ${state.pathParameters['id']}',
            ),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const _PlaceholderScreen(title: 'Perfil'),
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