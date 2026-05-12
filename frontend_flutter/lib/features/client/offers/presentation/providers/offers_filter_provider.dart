import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OffersFilters extends Equatable {
  final String? destination;
  final List<String> categories;
  final double minPrice;
  final double maxPrice;
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;
  final int? minDays;
  final int? maxDays;

  const OffersFilters({
    this.destination,
    this.categories = const [],
    this.minPrice = 0.0,
    this.maxPrice = 50000.0,
    this.startDate,
    this.endDate,
    this.searchQuery = '',
    this.minDays,
    this.maxDays,
  });

  @override
  List<Object?> get props => [
        destination,
        categories,
        minPrice,
        maxPrice,
        startDate,
        endDate,
        searchQuery,
        minDays,
        maxDays,
      ];

  OffersFilters copyWith({
    String? destination,
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? minDays,
    int? maxDays,
    bool clearDestination = false,
    bool clearDates = false,
    bool clearDuration = false,
  }) {
    return OffersFilters(
      destination: clearDestination ? null : (destination ?? this.destination),
      categories: categories ?? this.categories,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      searchQuery: searchQuery ?? this.searchQuery,
      minDays: clearDuration ? null : (minDays ?? this.minDays),
      maxDays: clearDuration ? null : (maxDays ?? this.maxDays),
    );
  }
}


final offersFilterProvider = StateProvider<OffersFilters>((ref) => const OffersFilters());
