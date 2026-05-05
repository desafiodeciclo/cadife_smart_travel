import 'package:cadife_smart_travel/config/providers/app_config_provider.dart';
import 'package:cadife_smart_travel/core/network/dio_client.dart';
import 'package:cadife_smart_travel/core/network/interceptors/auth_interceptor.dart';
import 'package:cadife_smart_travel/core/network/interceptors/error_interceptor.dart';
import 'package:cadife_smart_travel/core/network/interceptors/logging_interceptor.dart';
import 'package:cadife_smart_travel/core/offline/offline_interceptor.dart';
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
