import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadife_smart_travel/config/app_config.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  // Este provider será overridado nos entry points
  throw UnimplementedError(
    'appConfigProvider must be overridden with actual config',
  );
});

// Helper para acessar config facilmente
extension AppConfigRef on WidgetRef {
  AppConfig get appConfig => watch(appConfigProvider);
}
