import 'package:flutter/foundation.dart';

@immutable
class TravelRecommendation {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String destination;
  final List<String> reasons;
  final double rating;
  final int numberOfReviews;

  const TravelRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.destination,
    required this.reasons,
    required this.rating,
    required this.numberOfReviews,
  });
}
