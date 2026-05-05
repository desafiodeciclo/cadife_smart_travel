import 'dart:async';
import 'dart:developer' as dev;

import 'package:cadife_smart_travel/app.dart';
import 'package:cadife_smart_travel/core/analytics/analytics_bloc_observer.dart';
import 'package:cadife_smart_travel/core/analytics/analytics_provider_observer.dart';
import 'package:cadife_smart_travel/core/config/env_config.dart';
import 'package:cadife_smart_travel/core/di/provider_overrides.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_event.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_bloc_provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main({EnvConfig? config}) async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('pt_BR', null);
    
    Bloc.observer = AnalyticsBlocObserver();

    late final ProviderContainer container;

    try {
      await setupServiceLocator(
        config: config,
        onTokenExpired: () => container.read(authBlocProvider).add(const AuthEvent.logoutRequested()),
      );
      await initDependencies();
      
      // Configurar Crashlytics
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
      };
      
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

    } catch (e, stack) {
      dev.log('Initialization Error', error: e, stackTrace: stack, name: 'main');
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: true);
    }

    container = ProviderContainer(
      overrides: getProviderOverrides(),
      observers: [AnalyticsProviderObserver()],
    );

    runApp(
      UncontrolledProviderScope(container: container, child: const CadifeApp()),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}
