import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/features/client/documentos/data/providers/documento_data_providers.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/documento.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/trip_summary.dart';
import 'package:cadife_smart_travel/features/client/domain/entities/travel.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

/// Documentos globais do usuário (viagem ativa/próxima).
final globalDocumentsProvider = FutureProvider<List<Documento>>((ref) async {
  final repo = ref.watch(documentoRepositoryProvider);
  final result = await repo.getMyDocuments();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (docs) => docs,
  );
});

/// Lista de viagens do usuário para navegação de documentos por viagem.
final tripsWithDocumentsProvider =
    FutureProvider<List<TripSummary>>((ref) async {
  final dio = GetIt.I<Dio>();
  final response = await dio.get('${ApiConstants.baseUrl}/travels');
  final travels = (response.data['travels'] as List)
      .map((e) => Travel.fromJson(e as Map<String, dynamic>))
      .map(
        (t) => TripSummary(
          id: t.id,
          name: t.destination,
          destino: t.destination,
          dataIda: t.startDate,
          dataVolta: t.endDate,
          imageUrl: t.imageUrl,
          roteiro: t.description,
        ),
      )
      .toList();
  return travels;
});

/// Documentos de uma viagem específica.
final tripDocumentsProvider =
    FutureProvider.family<List<Documento>, String>((ref, tripId) async {
  final repo = ref.watch(documentoRepositoryProvider);
  final result = await repo.getDocumentsByTrip(tripId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (docs) => docs,
  );
});
