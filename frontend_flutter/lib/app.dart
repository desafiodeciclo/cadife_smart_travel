import 'package:cadife_smart_travel/config/providers/app_config_provider.dart';
import 'package:cadife_smart_travel/config/router/app_router.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CadifeApp extends ConsumerWidget {
  const CadifeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final config = ref.watch(appConfigProvider);
    // Trigger auth check on startup; router refreshes when state changes.
    ref.watch(authNotifierProvider);

    return ShadApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.shadTheme(context, Brightness.light),
      darkTheme: AppTheme.shadTheme(context, Brightness.dark),
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      materialThemeBuilder: (context, theme) =>
          theme.brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
    );
  }
}
