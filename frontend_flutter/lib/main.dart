import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/core/router/app_router.dart';
import 'package:cadife_smart_travel/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializa DI (get_it)
  await setupServiceLocator();

  // 2. Inicializa infra offline (Hive)
  await initDependencies();

  // 3. Firebase — será habilitado na Fase 3
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: CadifeApp()));
}

class CadifeApp extends ConsumerWidget {
  const CadifeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Cadife Smart Travel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
