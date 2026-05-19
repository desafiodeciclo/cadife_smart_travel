import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/trip_summary.dart';
import 'package:cadife_smart_travel/features/client/domain/entities/travel.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

/// Provider que gerencia a lista de viagens concluídas do cliente (histórico).
final travelHistoryProvider = AsyncNotifierProvider<HistoricoNotifier, List<TripSummary>>(
  HistoricoNotifier.new,
);

class HistoricoNotifier extends AsyncNotifier<List<TripSummary>> {
  @override
  Future<List<TripSummary>> build() async {
    // Recarrega o histórico quando uma viagem for concluída (evento FCM).
    final subscription = FirebaseMessaging.onMessage.listen((message) {
      if (message.data['type'] == 'travel_completed') {
        ref.invalidateSelf();
      }
    });
    ref.onDispose(subscription.cancel);

    return _fetchCompletedTravels();
  }

  Future<List<TripSummary>> _fetchCompletedTravels() async {
    final dio = GetIt.I<Dio>();
    final response = await dio.get(
      '${ApiConstants.baseUrl}/travels',
      queryParameters: {'status': 'completed'},
    );
    final travels = (response.data['travels'] as List)
        .map((e) => Travel.fromJson(e as Map<String, dynamic>))
        .map(_toSummary)
        .toList();
    return travels;
  }

  TripSummary _toSummary(Travel t) {
    return TripSummary(
      id: t.id,
      name: t.destination,
      destino: t.destination,
      dataIda: t.startDate,
      dataVolta: t.endDate,
      imageUrl: t.imageUrl,
      roteiro: t.description,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchCompletedTravels);
  }
}
