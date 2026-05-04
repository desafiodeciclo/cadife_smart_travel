import 'package:cadife_smart_travel/config/router/app_router.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_event.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_bloc_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class CadifeApp extends ConsumerWidget {
  const CadifeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authBloc = ref.watch(authBlocProvider);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(
          value: authBloc..add(const AuthEvent.authCheckRequested()),
        ),
      ],
      child: ShadApp.router(
        title: 'Cadife Smart Travel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.shadTheme(context, Brightness.light),
        darkTheme: AppTheme.shadTheme(context, Brightness.dark),
        themeMode: themeMode,
        routerConfig: ref.watch(routerProvider),
        materialThemeBuilder: (context, theme) => 
            theme.brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
      ),


    );
  }
}
