import 'package:cadife_smart_travel/features/agency/leads/data/providers/leads_data_providers.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que busca o lead ativo do cliente logado.
final activeLeadProvider = FutureProvider<Lead?>((ref) async {
  final repository = ref.watch(leadsRepositoryProvider);
  return repository.getMyLead();
});

/// Provider mock para documentos do cliente.
final clientDocumentsProvider = Provider<List<Documento>>((ref) {
  return const [
    Documento(
      id: '1',
      name: 'Voucher Hotel',
      type: DocumentType.pdf,
      size: 1258291, // 1.2 MB
      url: 'https://example.com/voucher.pdf',
    ),
    Documento(
      id: '2',
      name: 'Seguro Viagem',
      type: DocumentType.pdf,
      size: 838860, // 0.8 MB
      url: 'https://example.com/seguro.pdf',
    ),
    Documento(
      id: '3',
      name: 'Passagens Aéreas',
      type: DocumentType.pdf,
      size: 2621440, // 2.5 MB
      url: 'https://example.com/passagens.pdf',
    ),
  ];
});
