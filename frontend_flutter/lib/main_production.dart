import 'package:cadife_smart_travel/core/config/env_config.dart';
import 'package:cadife_smart_travel/main.dart' as app_main;

void main() async {
  // Configuração específica de Produção
  final prodConfig = EnvConfig.prod;
  
  // Inicia o app principal passando a configuração de Produção
  app_main.main(config: prodConfig);
}
