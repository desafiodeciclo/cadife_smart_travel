import 'package:flutter/foundation.dart';

/// Representa uma viagem do cliente no portal.
/// Mapeia diretamente o schema TravelResponse do backend.
@immutable
class Travel {
  const Travel({
    required this.id,
    required this.userId,
    required this.destination,
    required this.startDate,
    required this.status,
    this.endDate,
    this.imageUrl,
    this.description,
  });

  final String id;
  final String userId;
  final String destination;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final String? imageUrl;
  final String? description;

  bool get isUpcoming => status == 'upcoming';
  bool get isOngoing => status == 'ongoing';
  bool get isCompleted => status == 'completed';

  factory Travel.fromJson(Map<String, dynamic> json) {
    return Travel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      destination: json['destination'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      status: json['status'] as String,
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'destination': destination,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'image_url': imageUrl,
      'description': description,
    };
  }
}
