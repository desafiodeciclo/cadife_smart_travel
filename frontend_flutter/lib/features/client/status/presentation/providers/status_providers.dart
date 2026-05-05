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

/// Provider mock para documentos do cliente.
// TODO: substituir por IDocumentRepository quando endpoint GET /client/documents existir.
final clientDocumentsProvider = Provider<List<Documento>>((ref) {
  return const [
    Documento(
      id: '1',
      name: 'Voucher Hotel',
      type: DocumentType.pdf,
      size: 1258291,
      url: 'https://example.com/voucher.pdf',
    ),
    Documento(
      id: '2',
      name: 'Seguro Viagem',
      type: DocumentType.pdf,
      size: 838860,
      url: 'https://example.com/seguro.pdf',
    ),
    Documento(
      id: '3',
      name: 'Passagens Aéreas',
      type: DocumentType.pdf,
      size: 2621440,
      url: 'https://example.com/passagens.pdf',
    ),
  ];
});
