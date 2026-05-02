import 'package:cadife_smart_travel/features/client/home/widgets/documents_section.dart';
import 'package:cadife_smart_travel/features/client/trip_status/trip_status_provider.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeLeadProvider = FutureProvider<LeadModel?>((ref) async {
  final leadPort = ref.watch(clientLeadPortProvider);
  return leadPort.getMyLead();
});

final clientDocumentsProvider = Provider<List<DocumentItem>>((ref) {
  return const [
    DocumentItem(name: 'Voucher Hotel', sizeMb: '1.2 MB'),
    DocumentItem(name: 'Seguro Viagem', sizeMb: '0.8 MB'),
    DocumentItem(name: 'Passagens Aéreas', sizeMb: '2.5 MB'),
  ];
});
