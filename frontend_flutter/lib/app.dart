import 'package:cadife_smart_travel/config/providers/app_config_provider.dart';
import 'package:cadife_smart_travel/config/router/app_router.dart';


import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_event.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_bloc_provider.dart';
import 'package:cadife_smart_travel/features/settings/application/theme_notifier.dart';
import 'package:cadife_smart_travel/features/settings/domain/entities/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class CadifeApp extends ConsumerWidget {
  const CadifeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePreference = ref.watch(themeNotifierProvider);
    final authBloc = ref.watch(authBlocProvider);
    final config = ref.watch(appConfigProvider);

    return themePreference.when(
      data: (theme) {
        final themeMode = switch (theme) {
          ThemePreference.light => ThemeMode.light,
          ThemePreference.dark => ThemeMode.dark,
          ThemePreference.system => ThemeMode.system,
        };

        // Configurar SystemChrome (Removido daqui para evitar side-effects no build)
        // Idealmente isso deveria estar em um listener ou no initState de um StatefulWidget superior.

        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(
              value: authBloc..add(const AuthEvent.authCheckRequested()),
            ),
          ],
          child: AnimatedTheme(
            duration: const Duration(milliseconds: 200),
            data: themeMode == ThemeMode.dark
                ? AppTheme.dark
                : AppTheme.light,
            child: ShadApp.router(
              title: config.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.shadTheme(context, Brightness.light),
              darkTheme: AppTheme.shadTheme(context, Brightness.dark),
              themeMode: themeMode,
              routerConfig: ref.watch(routerProvider),
              materialThemeBuilder: (context, theme) => 
                  theme.brightness == Brightness.light 
                      ? AppTheme.light 
                      : AppTheme.dark,
            ),
          ),
        );
      },
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, stack) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(child: Text('Erro ao carregar preferências: $err')),
        ),
      ),
    );
  }
}
