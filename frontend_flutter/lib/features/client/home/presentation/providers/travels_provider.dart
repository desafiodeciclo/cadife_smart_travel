import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/features/client/domain/entities/travel.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

class TravelsNotifier extends AsyncNotifier<List<Travel>> {
  @override
  Future<List<Travel>> build() async {
    return _fetchTravels();
  }

  Future<List<Travel>> _fetchTravels({String? status}) async {
    final dio = GetIt.I<Dio>();
    try {
      String endpoint = '${ApiConstants.baseUrl}/travels';
      if (status != null && status.isNotEmpty) {
        endpoint += '?status=$status';
      }
      final response = await dio.get(endpoint);
      final travels = (response.data['travels'] as List)
          .map((e) => Travel.fromJson(e as Map<String, dynamic>))
          .toList();
      return travels;
    } catch (e, st) {
      throw AsyncError(e, st);
    }
  }

  Future<void> filterByStatus(String? status) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTravels(status: status));
  }
}

final travelsProvider = AsyncNotifierProvider<TravelsNotifier, List<Travel>>(
  TravelsNotifier.new,
);

/// Provider para viagem atual (primeira upcoming).
final currentTravelProvider = FutureProvider<Travel?>((ref) async {
  final travels = await ref.watch(travelsProvider.future);
  for (final t in travels) {
    if (t.isUpcoming) return t;
  }
  return null;
});
