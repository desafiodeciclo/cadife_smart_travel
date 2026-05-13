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
    required this.dates,
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
  double get finalPrice => hasDiscount ? price * (1 - discountPercent / 100) : price;
  String get destinationImageUrl => imageUrl;
  DateTime get departureDate => dates.start;
  DateTime get returnDate => dates.end;
  int get durationDays => dates.durationInDays;
  List<String> get includedServices => amenities;

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
      status: json['status'] as String? ?? 'published',
      views: json['views'] as int? ?? 0,
      interests: json['interests'] as int? ?? 0,
      conversions: json['conversions'] as int? ?? 0,
      availableSpots: json['available_spots'] as int? ?? 0,
      spotsReserved: json['spots_reserved'] as int? ?? 0,
      highlights: (json['highlights'] as List?)?.map((e) => e as String).toList() ?? const [],
      amenities: (json['amenities'] as List?)?.map((e) => e as String).toList() ?? const [],
      currency: json['currency'] as String? ?? 'BRL',
      travelers: json['travelers'] as int? ?? 1,
      basePrice: (json['base_price'] as num? ?? (json['price'] as num)).toDouble(),
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
    'status': status,
    'views': views,
    'interests': interests,
    'conversions': conversions,
    'available_spots': availableSpots,
    'spots_reserved': spotsReserved,
    'highlights': highlights,
    'amenities': amenities,
    'currency': currency,
    'travelers': travelers,
    'base_price': basePrice,
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
      dates: dates ?? this.dates,
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

