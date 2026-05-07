import 'package:cadife_smart_travel/features/client/documentos/data/repositories/mock_documento_repository.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/repositories/i_documento_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final documentoRepositoryProvider = Provider<IDocumentoRepository>((ref) {
  // Por enquanto retorna o mock. No futuro, injetar a implementação real.
  return MockDocumentoRepository();
});
