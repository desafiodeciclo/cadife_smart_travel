import 'package:cadife_smart_travel/features/client/offers/domain/entities/date_range.dart';

class Offer {
  final String id;
  final String title;
  final String destination;
  final String category;
  final String description;
  final double price;
  final String imageUrl;
  final double rating;
  final int daysCount;
  final DateRange dates;

  const Offer({
    required this.id,
    required this.title,
    required this.destination,
    required this.category,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.rating,
    required this.daysCount,
    required this.dates,
  });

  double get estimatedPrice => price;

  // copyWith
  Offer copyWith({
    String? id,
    String? title,
    String? destination,
    String? category,
    String? description,
    double? price,
    String? imageUrl,
    double? rating,
    int? daysCount,
    DateRange? dates,
  }) {
    return Offer(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      daysCount: daysCount ?? this.daysCount,
      dates: dates ?? this.dates,
    );
  }
}
