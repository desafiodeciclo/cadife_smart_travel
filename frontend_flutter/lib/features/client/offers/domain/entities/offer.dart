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
  final DateRange? dates;
  final bool hasDiscount;
  final double discountPercent;
  final bool availableSpot;

  // New fields for management and details
  final String status;
  final int views;
  final int interests;
  final int conversions;
  final int availableSpots;
  final int spotsReserved;
  final List<String> highlights;
  final List<String> amenities;
  final String currency;
  final int travelers;
  final double basePrice;

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
    this.dates,
    required this.basePrice,
    this.hasDiscount = false,
    this.discountPercent = 0.0,
    this.availableSpot = true,
    this.status = 'published',
    this.views = 0,
    this.interests = 0,
    this.conversions = 0,
    this.availableSpots = 0,
    this.spotsReserved = 0,
    this.highlights = const [],
    this.amenities = const [],
    this.currency = 'BRL',
    this.travelers = 1,
  });

  double get estimatedPrice => price;
  double get finalPrice => price; // Backend already computes final_price
  String get destinationImageUrl => imageUrl;
  DateTime? get departureDate => dates?.start;
  DateTime? get returnDate => dates?.end;
  int? get durationDays => dates?.durationInDays;
  List<String> get includedServices => amenities;

  factory Offer.fromJson(Map<String, dynamic> json) {
    // Derive discount info from backend discounts dict
    final discountsRaw = json['discounts'] != null
        ? Map<String, dynamic>.from(json['discounts'] as Map)
        : null;
    final hasDiscount = discountsRaw != null && discountsRaw.isNotEmpty;
    final discountPercent = hasDiscount
        ? discountsRaw.values
            .map((v) => (v as num).toDouble())
            .reduce((a, b) => a > b ? a : b)
        : 0.0;

    // Derive availability from backend spot counts
    final availableSpots = json['available_spots'] as int? ?? 0;
    final spotsReserved = json['spots_reserved'] as int? ?? 0;
    final availableSpot = availableSpots > spotsReserved;

    // Parse dates from flat backend fields
    DateRange? dates;
    final departureDateStr = json['departure_date'] as String?;
    final returnDateStr = json['return_date'] as String?;
    if (departureDateStr != null && returnDateStr != null) {
      dates = DateRange(
        start: DateTime.parse(departureDateStr),
        end: DateTime.parse(returnDateStr),
      );
    } else if (json['dates'] != null) {
      // Fallback for legacy cached data
      dates = DateRange.fromJson(json['dates'] as Map<String, dynamic>);
    }

    return Offer(
      id: json['id'] as String,
      title: json['title'] as String,
      destination: json['destination'] as String,
      category: json['category'] as String? ?? 'Geral',
      description: json['description'] as String? ?? '',
      price: double.parse(json['final_price']?.toString() ?? '0.0'),
      imageUrl: json['destination_image_url'] as String? ?? '',
      rating: 0.0, // Backend does not send ratings
      daysCount: json['duration_days'] as int? ?? 0,
      dates: dates,
      hasDiscount: hasDiscount,
      discountPercent: discountPercent,
      availableSpot: availableSpot,
      status: (json['status'] as String? ?? 'published').toLowerCase(),
      views: json['views'] as int? ?? 0,
      interests: json['interests'] as int? ?? 0,
      conversions: json['conversions'] as int? ?? 0,
      availableSpots: availableSpots,
      spotsReserved: spotsReserved,
      highlights: (json['highlights'] as List?)?.map((e) => e as String).toList() ?? const [],
      amenities: (json['amenities'] as List?)?.map((e) => e as String).toList() ?? const [],
      currency: json['currency'] as String? ?? 'BRL',
      travelers: json['travelers'] as int? ?? 1,
      basePrice: double.parse(json['base_price']?.toString() ?? '0.0'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'destination': destination,
    'category': category,
    'description': description,
    'final_price': price.toStringAsFixed(2),
    'base_price': basePrice.toStringAsFixed(2),
    'destination_image_url': imageUrl,
    'rating': rating,
    'duration_days': daysCount,
    'departure_date': dates?.start.toIso8601String(),
    'return_date': dates?.end.toIso8601String(),
    'discounts': hasDiscount
        ? {'default': discountPercent}
        : null,
    'available_spots': availableSpots,
    'spots_reserved': spotsReserved,
    'status': status,
    'views': views,
    'interests': interests,
    'conversions': conversions,
    'highlights': highlights,
    'amenities': amenities,
    'currency': currency,
    'travelers': travelers,
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
    bool clearDates = false,
    bool? hasDiscount,
    double? discountPercent,
    bool? availableSpot,
    String? status,
    int? views,
    int? interests,
    int? conversions,
    int? availableSpots,
    int? spotsReserved,
    List<String>? highlights,
    List<String>? amenities,
    String? currency,
    int? travelers,
    double? basePrice,
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
      dates: clearDates ? null : (dates ?? this.dates),
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountPercent: discountPercent ?? this.discountPercent,
      availableSpot: availableSpot ?? this.availableSpot,
      status: status ?? this.status,
      views: views ?? this.views,
      interests: interests ?? this.interests,
      conversions: conversions ?? this.conversions,
      availableSpots: availableSpots ?? this.availableSpots,
      spotsReserved: spotsReserved ?? this.spotsReserved,
      highlights: highlights ?? this.highlights,
      amenities: amenities ?? this.amenities,
      currency: currency ?? this.currency,
      travelers: travelers ?? this.travelers,
      basePrice: basePrice ?? this.basePrice,
    );
  }

  @override
  List<Object?> get props => [
    id, title, destination, category, description, price, imageUrl,
    rating, daysCount, dates, hasDiscount, discountPercent, availableSpot,
    status, views, interests, conversions, availableSpots, spotsReserved,
    highlights, amenities, currency, travelers, basePrice,
  ];
}

