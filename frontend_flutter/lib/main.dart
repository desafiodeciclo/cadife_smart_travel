import 'dart:developer' as dev;

import 'package:cadife_smart_travel/app.dart';
import 'package:cadife_smart_travel/core/config/env_config.dart';
import 'package:cadife_smart_travel/core/di/provider_overrides.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_event.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_bloc_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main({EnvConfig? config}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  late final ProviderContainer container;

  try {
    await setupServiceLocator(
      onTokenExpired: () => container.read(authBlocProvider).add(const AuthEvent.logoutRequested()),
    );
    await initDependencies();
  } catch (e, stack) {
    dev.log('Initialization Error', error: e, stackTrace: stack, name: 'main');
  }

  container = ProviderContainer(overrides: getProviderOverrides());

  runApp(
    UncontrolledProviderScope(container: container, child: const CadifeApp()),
  );
}
