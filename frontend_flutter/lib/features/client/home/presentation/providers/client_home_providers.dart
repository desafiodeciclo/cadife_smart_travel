import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:cadife_smart_travel/features/client/home/domain/entities/client_document.dart';
import 'package:cadife_smart_travel/features/client/home/domain/entities/client_trip.dart';
import 'package:cadife_smart_travel/features/client/home/domain/entities/consultant_info.dart';
import 'package:cadife_smart_travel/features/client/home/presentation/providers/travels_provider.dart';
import 'package:cadife_smart_travel/features/client/offers/data/repositories/offer_repository.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/checkpoint_item.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/providers/checkpoints_provider.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/providers/status_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _checkpointOrder = <TravelCheckpointType>[
  TravelCheckpointType.briefingColetado,
  TravelCheckpointType.curadoriaIniciada,
  TravelCheckpointType.propostaEnviada,
  TravelCheckpointType.propostaAprovada,
  TravelCheckpointType.viagemConfirmada,
  TravelCheckpointType.viagemEmAndamento,
  TravelCheckpointType.viagemConcluida,
];

/// Viagem atual do cliente montada a partir de dados reais do backend
/// (viagem + checkpoints).
final currentClientTripProvider = FutureProvider<ClientTrip?>((ref) async {
  final travel = await ref.watch(currentTravelProvider.future);
  if (travel == null) return null;

  final reached = <TravelCheckpointType>{};
  try {
    final checkpoints = await ref.watch(checkpointsProvider(travel.id).future);
    reached.addAll(checkpoints.map((c) => c.checkpoint));
  } on Object {
    // Sem checkpoints disponíveis — timeline vazia.
  }

  var currentAssigned = false;
  final tripCheckpoints = _checkpointOrder.map((type) {
    final completed = reached.contains(type);
    final isCurrent = !completed && !currentAssigned;
    if (isCurrent) currentAssigned = true;
    return TripCheckpoint(
      id: type.name,
      name: type.label,
      completed: completed,
      isCurrent: isCurrent,
    );
  }).toList();

  final progress = _checkpointOrder.isEmpty
      ? 0.0
      : reached.length / _checkpointOrder.length;

  return ClientTrip(
    id: travel.id,
    destination: travel.destination,
    destinationCountry: '',
    destinationFlag: '',
    startDate: travel.startDate,
    endDate: travel.endDate,
    coverImageUrl: travel.imageUrl ?? '',
    status: travel.status,
    progressPercentage: progress,
    checkpoints: tripCheckpoints,
    roteiro: travel.description,
  );
});

/// Consultor responsável, a partir do status ativo do cliente.
final clientConsultantProvider = FutureProvider<ConsultantInfo?>((ref) async {
  final status = await ref.watch(activeLeadProvider.future);
  if (status == null || status.consultorNome == null) return null;
  return ConsultantInfo(
    id: status.id,
    name: status.consultorNome!,
    phone: '',
    photoUrl: status.consultorAvatar ?? '',
    email: '',
  );
});

ClientDocument _toClientDocument(Documento d) {
  return ClientDocument(
    id: d.id,
    type: d.category ?? d.type.name,
    displayName: d.name,
    url: d.url,
    uploadedAt: d.createdAt ?? DateTime.now(),
  );
}

/// Documentos do cliente para a home (mapeados de [Documento]).
final clientHomeDocumentsProvider =
    FutureProvider<List<ClientDocument>>((ref) async {
  final docs = await ref.watch(clientDocumentsProvider.future);
  return docs.map(_toClientDocument).toList();
});

/// Ofertas recomendadas (dados reais do endpoint /offers).
final clientRecommendationsProvider =
    FutureProvider<List<Offer>>((ref) async {
  final repo = ref.watch(offerRepositoryProvider);
  final result = await repo.listOffers(limit: 6);
  final offersJson = result['offers'] as List<dynamic>? ?? <dynamic>[];
  return offersJson
      .map((e) => Offer.fromJson(e as Map<String, dynamic>))
      .toList();
});
