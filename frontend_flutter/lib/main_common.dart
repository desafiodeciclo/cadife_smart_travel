import 'dart:developer' as dev;
import 'package:cadife_smart_travel/app.dart';
import 'package:cadife_smart_travel/config/app_config.dart';
import 'package:cadife_smart_travel/config/providers/app_config_provider.dart';
import 'package:cadife_smart_travel/core/di/provider_overrides.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

late AppConfig _appConfig;

Future<void> initializeApp(AppConfig config) async {
  _appConfig = config;
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  try {
    // Passar AppConfig para o setupServiceLocator (atualizaremos o sl depois)
    await setupServiceLocator(
      appConfig: config,
    );
    await initDependencies();
  } catch (e, stack) {
    dev.log('Initialization Error', error: e, stackTrace: stack, name: 'main');
  }
}

class CadifeAppWrapper extends StatelessWidget {
  const CadifeAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(_appConfig),
        ...getProviderOverrides(),
      ],
      child: const CadifeApp(),
    );
  }
}
