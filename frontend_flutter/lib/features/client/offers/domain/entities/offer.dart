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
  
  // New fields for UI compatibility
  final bool hasDiscount;
  final double discountPercent;
  final int availableSpots;
  final List<String> highlights;
  final List<String> includedServices;

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
    this.availableSpots = 10,
    this.highlights = const [],
    this.includedServices = const [],
  });

  // Getters for UI compatibility
  double get estimatedPrice => price;
  double get basePrice => hasDiscount ? price / (1 - discountPercent / 100) : price;
  double get finalPrice => price;
  String get destinationImageUrl => imageUrl;
  int get durationDays => daysCount;
  DateTime get departureDate => dates.start;
  DateTime get returnDate => dates.end;
  int get availableSpot => availableSpots;

  // fromJson
  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as String,
      title: json['title'] as String,
      destination: json['destination'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      rating: (json['rating'] as num).toDouble(),
      daysCount: json['daysCount'] as int,
      dates: DateRange(
        start: DateTime.parse(json['startDate'] as String),
        end: DateTime.parse(json['endDate'] as String),
      ),
      hasDiscount: json['hasDiscount'] as bool? ?? false,
      discountPercent: (json['discountPercent'] as num? ?? 0.0).toDouble(),
      availableSpots: json['availableSpots'] as int? ?? 10,
      highlights: (json['highlights'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      includedServices: (json['includedServices'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  // toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'destination': destination,
      'category': category,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'rating': rating,
      'daysCount': daysCount,
      'startDate': dates.start.toIso8601String(),
      'endDate': dates.end.toIso8601String(),
      'hasDiscount': hasDiscount,
      'discountPercent': discountPercent,
      'availableSpots': availableSpots,
      'highlights': highlights,
      'includedServices': includedServices,
    };
  }

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
    bool? hasDiscount,
    double? discountPercent,
    int? availableSpots,
    List<String>? highlights,
    List<String>? includedServices,
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
      availableSpots: availableSpots ?? this.availableSpots,
      highlights: highlights ?? this.highlights,
      includedServices: includedServices ?? this.includedServices,
    );
  }
}
