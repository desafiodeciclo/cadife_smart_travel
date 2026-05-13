// lib/features/client/domain/entities/client_trip.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_trip.freezed.dart';

@freezed
class ClientTrip with _$ClientTrip {
  const factory ClientTrip({
    required String id,
    required String destination,
    required String destinationCountry,
    required String destinationFlag, // emoji
    required DateTime startDate,
    required DateTime endDate,
    required String coverImageUrl,
    required String status, // planejando, confirmado, em andamento, concluído
    required double progressPercentage,
    required TripCheckpoint currentCheckpoint,
    required List<TripCheckpoint> checkpoints,
  }) = _ClientTrip;
}

@freezed
class TripCheckpoint with _$TripCheckpoint {
  const factory TripCheckpoint({
    required String id,
    required String name,
    required bool completed,
    required bool isCurrent,
  }) = _TripCheckpoint;
}

@freezed
class ConsultantInfo with _$ConsultantInfo {
  const factory ConsultantInfo({
    required String id,
    required String name,
    required String phone,
    required String photoUrl,
    required String email,
  }) = _ConsultantInfo;
}

@freezed
class ClientDocument with _$ClientDocument {
  const factory ClientDocument({
    required String id,
    required String type, // passport, proposal, insurance, itinerary
    required String displayName,
    required String url,
    required DateTime uploadedAt,
    required String? expiresAt,
  }) = _ClientDocument;
}

@freezed
class TravelRecommendation with _$TravelRecommendation {
  const factory TravelRecommendation({
    required String id,
    required String title,
    required String description,
    required String imageUrl,
    required String destination,
    required List<String> reasons, // ["Clima tropical", "Praias"]
    required double rating,
    required int numberOfReviews,
  }) = _TravelRecommendation;
}
