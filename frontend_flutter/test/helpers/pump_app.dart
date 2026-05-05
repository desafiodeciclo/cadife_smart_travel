import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_bloc_provider.dart';
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
  ThemeMode themeMode = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith((ref) => ThemeModeNotifier()),
        ...overrides,
      ],
      child: Consumer(
        builder: (context, ref, child) {
          final authBloc = ref.watch(authBlocProvider);
          return MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
            ],
            child: ShadApp(
              theme: AppTheme.shadTheme(null as dynamic, Brightness.light),
              darkTheme: AppTheme.shadTheme(null as dynamic, Brightness.dark),
              themeMode: themeMode,
              materialThemeBuilder: (context, theme) => 
                  theme.brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
              home: widget,
            ),
          );
        },
      ),
    ),
  );
}
