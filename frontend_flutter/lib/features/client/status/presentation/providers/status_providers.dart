import 'package:cadife_smart_travel/features/client/documentos/data/providers/documento_data_providers.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:cadife_smart_travel/features/client/status/data/providers/status_data_providers.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/client_travel_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que busca o status de viagem ativo do cliente logado.
final activeLeadProvider = FutureProvider<ClientTravelStatus?>((ref) async {
  final repository = ref.watch(statusRepositoryProvider);
  final result = await repository.getMyStatus();
  return result.fold(
    (failure) => throw failure,
    (status) => status,
  );
});

/// Provider para documentos do cliente usando o repositório.
final clientDocumentsProvider = FutureProvider<List<Documento>>((ref) async {
  final repository = ref.watch(documentoRepositoryProvider);
  final result = await repository.getMyDocuments();
  return result.fold(
    (failure) => throw failure,
    (documents) => documents,
  );
});
