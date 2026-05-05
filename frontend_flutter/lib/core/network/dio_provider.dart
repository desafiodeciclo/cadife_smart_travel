import 'package:cadife_smart_travel/config/providers/app_config_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

final dioClientProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  
  // Usamos a factory existente para manter a lógica de pinning e outros interceptores,
  // mas garantimos que a configuração venha do provider.
  final dio = GetIt.I<Dio>();
  
  // Adicionamos o interceptor de logging customizado por ambiente se habilitado
  if (config.enableDebugLogs) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('🌐 [${config.environment.name.toUpperCase()}] '
              '${options.method} ${options.path}');
          return handler.next(options);
        },
      ),
    );
  }
  
  return dio;
});
