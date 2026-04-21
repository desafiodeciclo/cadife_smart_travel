import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Provider do GoRouter — autenticação como guard central.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // TODO: implementar auth guard quando AuthProvider existir
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Cadife Smart Travel — Carregando...')),
        ),
      ),
    ],
  );
});
