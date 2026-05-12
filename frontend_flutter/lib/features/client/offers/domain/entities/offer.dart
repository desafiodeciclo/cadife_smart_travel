import 'package:cadife_smart_travel/features/client/offers/domain/entities/date_range.dart';
import 'package:equatable/equatable.dart';

class Offer extends Equatable {
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
  final bool hasDiscount;
  final double discountPercent;
  final bool availableSpot;

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
    this.hasDiscount = false,
    this.discountPercent = 0.0,
    this.availableSpot = true,
  });

  double get estimatedPrice => price;
  double get finalPrice => hasDiscount ? price * (1 - discountPercent / 100) : price;
  String? get destinationImageUrl => imageUrl;

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as String,
      title: json['title'] as String,
      destination: json['destination'] as String,
      category: json['category'] as String? ?? 'Geral',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String? ?? '',
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
      daysCount: json['days_count'] as int? ?? 0,
      dates: DateRange.fromJson(json['dates'] as Map<String, dynamic>),
      hasDiscount: json['has_discount'] as bool? ?? false,
      discountPercent: (json['discount_percent'] as num? ?? 0.0).toDouble(),
      availableSpot: json['available_spot'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'destination': destination,
    'category': category,
    'description': description,
    'price': price,
    'image_url': imageUrl,
    'rating': rating,
    'days_count': daysCount,
    'dates': dates.toJson(),
    'has_discount': hasDiscount,
    'discount_percent': discountPercent,
    'available_spot': availableSpot,
  };

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
    bool? hasDiscount,
    double? discountPercent,
    bool? availableSpot,
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
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountPercent: discountPercent ?? this.discountPercent,
      availableSpot: availableSpot ?? this.availableSpot,
    );
  }

  @override
  List<Object?> get props => [
    id, title, destination, category, description, price, imageUrl,
    rating, daysCount, dates, hasDiscount, discountPercent, availableSpot
  ];
}
