import 'package:cadife_smart_travel/features/client/offers/data/repositories/offer_repository.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OffersFilterState {
  final String? destination;
  final double? minPrice;
  final double? maxPrice;
  final int? minDays;
  final int? maxDays;
  final String? search;
  final int page;

  OffersFilterState({
    this.destination,
    this.minPrice,
    this.maxPrice,
    this.minDays,
    this.maxDays,
    this.search,
    this.page = 1,
  });

  OffersFilterState copyWith({
    String? destination,
    double? minPrice,
    double? maxPrice,
    int? minDays,
    int? maxDays,
    String? search,
    int? page,
  }) {
    return OffersFilterState(
      destination: destination ?? this.destination,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minDays: minDays ?? this.minDays,
      maxDays: maxDays ?? this.maxDays,
      search: search ?? this.search,
      page: page ?? this.page,
    );
  }
}

class OffersNotifier extends StateNotifier<AsyncValue<List<Offer>>> {
  final OfferRepository _repository;
  OffersFilterState _filter = OffersFilterState();

  OffersNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadOffers();
  }

  Future<void> loadOffers() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.listOffers(
        destination: _filter.destination,
        minPrice: _filter.minPrice,
        maxPrice: _filter.maxPrice,
        durationMin: _filter.minDays,
        durationMax: _filter.maxDays,
        search: _filter.search,
        page: _filter.page,
      );
      
      final List<dynamic> offersJson = result['offers'];
      final offers = offersJson.map((e) => Offer.fromJson(e)).toList();
      state = AsyncValue.data(offers);
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    } on Object catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void applyFilters(OffersFilterState filter) {
    _filter = filter;
    loadOffers();
  }

  void setSearch(String? search) {
    _filter = _filter.copyWith(search: search, page: 1);
    loadOffers();
  }
}

final offersProvider = StateNotifierProvider<OffersNotifier, AsyncValue<List<Offer>>>((ref) {
  final repository = ref.watch(offerRepositoryProvider);
  return OffersNotifier(repository);
});

// Provider for agency offers
class MyOffersNotifier extends AsyncNotifier<List<Offer>> {
  @override
  Future<List<Offer>> build() async {
    final repository = ref.watch(offerRepositoryProvider);
    final result = await repository.getMyOffers();
    final List<dynamic> offersJson = result['offers'];
    return offersJson.map((e) => Offer.fromJson(e)).toList();
  }
}

final myOffersProvider = AsyncNotifierProvider<MyOffersNotifier, List<Offer>>(MyOffersNotifier.new);
