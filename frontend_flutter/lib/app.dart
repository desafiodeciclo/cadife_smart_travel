import 'package:cadife_smart_travel/core/router/app_router.dart';
import 'package:cadife_smart_travel/core/theme/app_theme.dart';
import 'package:cadife_smart_travel/core/theme/theme_mode_provider.dart';
import 'package:cadife_smart_travel/features/auth/presentation/widgets/app_lock_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// MultiBlocProvider será adicionado aqui na E6 (auth BLoC migration).
// Por ora CadifeApp é ConsumerWidget puro com Riverpod.
class CadifeApp extends ConsumerWidget {
  const CadifeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Cadife Smart Travel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, child) => AppLockWrapper(
        key: const ValueKey('app-lock'),
        child: child ?? const SizedBox.shrink(),
      ),
      routerConfig: router,
    );
  }
}
