import 'dart:async';
import 'dart:developer' as dev;

import 'package:cadife_smart_travel/app.dart';
import 'package:cadife_smart_travel/config/app_config.dart';
import 'package:cadife_smart_travel/config/providers/app_config_provider.dart';
import 'package:cadife_smart_travel/core/analytics/analytics_bloc_observer.dart';
import 'package:cadife_smart_travel/core/analytics/analytics_provider_observer.dart';
import 'package:cadife_smart_travel/core/di/provider_overrides.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

late AppConfig _appConfig;
late ProviderContainer _providerContainer;

Future<void> initializeApp(AppConfig config) async {
  _appConfig = config;

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('pt_BR', null);

    // 1. Setup Service Locator first (contains AnalyticsService)
    try {
      await setupServiceLocator(
        appConfig: config,
        onTokenExpired: () => _providerContainer.read(authNotifierProvider.notifier).logout(),
      );

      // 2. Configure observers that depend on SL
      Bloc.observer = AnalyticsBlocObserver();

      // 3. Initialize async dependencies (Firebase, Isar, etc.)
      await initDependencies();

      // 4. Crashlytics — not available on Web
      if (!kIsWeb) {
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
        };

        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }
    } catch (e, stack) {
      dev.log('Initialization Error', error: e, stackTrace: stack, name: 'main');
      if (!kIsWeb) {
        try {
          FirebaseCrashlytics.instance.recordError(e, stack, fatal: true);
        } catch (_) {}
      }
    }

    _providerContainer = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(_appConfig),
        ...getProviderOverrides(),
      ],
      observers: [AnalyticsProviderObserver()],
    );
  }, (error, stack) {
    dev.log('Top level error', error: error, stackTrace: stack, name: 'main');
    if (!kIsWeb) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {}
    }
  });
}

class CadifeAppWrapper extends StatelessWidget {
  const CadifeAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: _providerContainer,
      child: const CadifeApp(),
    );
  }
}
