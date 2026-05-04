import 'package:cadife_smart_travel/core/config/env_config.dart';
import 'package:cadife_smart_travel/main.dart' as app_main;

void main() async {
  // Configuração específica de Staging
  final stagingConfig = EnvConfig.staging;

  // Inicia o app principal passando a configuração de Staging
  app_main.main(config: stagingConfig);
}
