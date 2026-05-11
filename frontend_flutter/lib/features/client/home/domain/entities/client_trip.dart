import 'package:flutter/foundation.dart';

@immutable
class TripCheckpoint {
  final String id;
  final String name;
  final bool completed;
  final bool isCurrent;

  const TripCheckpoint({
    required this.id,
    required this.name,
    required this.completed,
    required this.isCurrent,
  });
}

@immutable
class ClientTrip {
  final String id;
  final String destination;
  final String destinationCountry;
  final String destinationFlag;
  final DateTime startDate;
  final DateTime endDate;
  final String coverImageUrl;
  final String status;
  final double progressPercentage;
  final List<TripCheckpoint> checkpoints;

  const ClientTrip({
    required this.id,
    required this.destination,
    required this.destinationCountry,
    required this.destinationFlag,
    required this.startDate,
    required this.endDate,
    required this.coverImageUrl,
    required this.status,
    required this.progressPercentage,
    required this.checkpoints,
  });
}
