class Offer {
  final String id;
  final String title;
  final String destination;
  final String? destinationImageUrl;
  final DateTime departureDate;
  final DateTime returnDate;
  final int durationDays;
  final double basePrice;
  final double finalPrice;
  final String currency;
  final int travelers;
  final int availableSpots;
  final int spotsReserved;
  final String status;
  final List<String> highlights;
  final List<String> amenities;
  final int views;
  final int interests;
  final int conversions;
  final String? description;
  final List<String>? accommodations;
  final List<String>? includedServices;
  final DateTime? bookingDeadline;
  final Map<String, double>? discounts;
  final String? category;

  Offer({
    required this.id,
    required this.title,
    required this.destination,
    required this.departureDate,
    required this.returnDate,
    required this.durationDays,
    required this.basePrice,
    required this.finalPrice,
    required this.currency,
    required this.travelers,
    required this.availableSpots,
    required this.spotsReserved,
    required this.status,
    required this.highlights,
    required this.amenities,
    required this.views,
    required this.interests,
    this.conversions = 0,
    this.destinationImageUrl,
    this.description,
    this.accommodations,
    this.includedServices,
    this.bookingDeadline,
    this.discounts,
    this.category,
  });

  bool get hasDiscount => finalPrice < basePrice;
  double get discountPercent => basePrice > 0 ? ((basePrice - finalPrice) / basePrice) * 100 : 0;
  bool get availableSpot => availableSpots > spotsReserved;

  // Compatibility getters for legacy UI
  String get imageUrl => destinationImageUrl ?? '';
  double get estimatedPrice => finalPrice;
  // ignore: non_constant_identifier_names
  List<String>? get included_services => includedServices;

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'],
      title: json['title'],
      destination: json['destination'],
      destinationImageUrl: json['destination_image_url'],
      departureDate: DateTime.parse(json['departure_date']),
      returnDate: DateTime.parse(json['return_date']),
      durationDays: json['duration_days'],
      basePrice: (json['base_price'] as num).toDouble(),
      finalPrice: (json['final_price'] as num).toDouble(),
      currency: json['currency'] ?? 'BRL',
      travelers: json['travelers'],
      availableSpots: json['available_spots'],
      spotsReserved: json['spots_reserved'] ?? 0,
      status: json['status'],
      highlights: List<String>.from(json['highlights'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      views: json['views'] ?? 0,
      interests: json['interests'] ?? 0,
      conversions: json['conversions'] ?? 0,
      description: json['description'],
      accommodations: json['accommodations'] != null ? List<String>.from(json['accommodations']) : null,
      includedServices: json['included_services'] != null ? List<String>.from(json['included_services']) : null,
      bookingDeadline: json['booking_deadline'] != null ? DateTime.parse(json['booking_deadline']) : null,
      discounts: json['discounts'] != null ? Map<String, double>.from(json['discounts']) : null,
      category: json['category'],
    );
  }
}
