import 'package:cadife_smart_travel/config/theme/cadife_theme.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_bloc_provider.dart';
import 'package:cadife_smart_travel/features/settings/application/theme_notifier.dart';
import 'package:cadife_smart_travel/features/settings/domain/entities/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper central para testes de widget e golden tests.
/// Garante que o widget seja renderizado com o tema, providers e localização corretos.
Future<void> pumpApp(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
  ThemePreference themePreference = ThemePreference.light,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        themeNotifierProvider.overrideWith(() => _MockThemeNotifier(themePreference)),
        ...overrides,
      ],
      child: Consumer(
        builder: (context, ref, child) {
          final authBloc = ref.watch(authBlocProvider);
          final themeMode = themePreference == ThemePreference.dark 
              ? ThemeMode.dark 
              : (themePreference == ThemePreference.light ? ThemeMode.light : ThemeMode.system);
              
          return MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
            ],
            child: ShadApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.shadTheme(context, Brightness.light),
              darkTheme: AppTheme.shadTheme(context, Brightness.dark),
              themeMode: themeMode,
              materialThemeBuilder: (context, theme) => 
                  theme.brightness == Brightness.light ? CadifeTheme.light : CadifeTheme.dark,
              home: widget,
            ),
          );
        },
      ),
    ),
  );
}

class _MockThemeNotifier extends ThemeNotifier {
  final ThemePreference initial;
  _MockThemeNotifier(this.initial);

  @override
  Stream<ThemePreference> build() {
    return Stream.value(initial);
  }

  @override
  Future<void> setTheme(ThemePreference preference) async {
    // No-op for tests or update state if needed
  }
}
