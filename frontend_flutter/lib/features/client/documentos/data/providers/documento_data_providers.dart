import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/features/client/documentos/data/repositories/documento_repository_impl.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/repositories/i_documento_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final documentoRepositoryProvider = Provider<IDocumentoRepository>((ref) {
  return DocumentoRepositoryImpl(dio: sl<Dio>());
});
