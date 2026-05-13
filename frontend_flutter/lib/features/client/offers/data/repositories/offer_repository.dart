import 'package:cadife_smart_travel/core/network/dio_provider.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfferRepository {
  final Dio _dio;

  OfferRepository(this._dio);

  Future<Map<String, dynamic>> listOffers({
    String? destination,
    double? minPrice,
    double? maxPrice,
    DateTime? minDate,
    DateTime? maxDate,
    int? travelers,
    int? durationMin,
    int? durationMax,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = {
      'destination': destination,
      'min_price': minPrice,
      'max_price': maxPrice,
      'min_date': minDate?.toIso8601String(),
      'max_date': maxDate?.toIso8601String(),
      'travelers': travelers,
      'duration_min': durationMin,
      'duration_max': durationMax,
      'search': search,
      'page': page,
      'limit': limit,
    }..removeWhere((key, value) => value == null);

    final response = await _dio.get('/offers', queryParameters: queryParams);
    return response.data;
  }

  Future<Offer> getOffer(String id) async {
    final response = await _dio.get('/offers/$id');
    return Offer.fromJson(response.data);
  }

  Future<void> expressInterest(String offerId) async {
    await _dio.post('/offers/$offerId/interest');
  }

  Future<Map<String, dynamic>> getMyOffers({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final queryParams = {
      'page': page,
      'limit': limit,
      'status': status,
    }..removeWhere((key, value) => value == null);
    final response = await _dio.get('/offers/agency/my-offers', queryParameters: queryParams);
    return response.data;
  }

  Future<Offer> createOffer(Map<String, dynamic> data) async {
    final response = await _dio.post('/offers', data: data);
    return Offer.fromJson(response.data);
  }

  Future<Offer> updateOffer(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/offers/$id', data: data);
    return Offer.fromJson(response.data);
  }

  Future<void> togglePublish(String id) async {
    await _dio.patch('/offers/$id/publish');
  }

  Future<void> deleteOffer(String id) async {
    await _dio.delete('/offers/$id');
  }
}

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return OfferRepository(dio);
});
