import 'package:cadife_smart_travel/core/cache/isar_cache_manager.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/core/network/network_info.dart';
import 'package:cadife_smart_travel/features/client/offers/data/repositories/mock_offer_repository.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/repositories/i_offer_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider do repositório
final offerRepositoryProvider = Provider<IOfferRepository>((ref) {
  final isar = sl<IsarCacheManager>();
  // Para fins do mock, podemos sempre ler do networkInfo para isOffline
  // Mas vamos tornar isso reativo, o que requereria ref.watch do networkInfoProvider (se houvesse).
  // Por simplicidade, assumimos online, mas o repositorio lida com isso.
  // Vamos passar isOffline: false por padrao e melhorar depois, ou verificar Future.
  return MockOfferRepository(isar, isOffline: false);
});

class OffersState {
  final List<Offer> offers;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isOffline;
  final String? error;
  final int currentPage;
  final bool hasReachedMax;

  // Filtros
  final String? query;
  final List<String> categories;
  final double minPrice;
  final double maxPrice;

  OffersState({
    this.offers = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isOffline = false,
    this.error,
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.query,
    this.categories = const [],
    this.minPrice = 0,
    this.maxPrice = 50000,
  });

  OffersState copyWith({
    List<Offer>? offers,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isOffline,
    String? error,
    int? currentPage,
    bool? hasReachedMax,
    String? query,
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
  }) {
    return OffersState(
      offers: offers ?? this.offers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isOffline: isOffline ?? this.isOffline,
      error: error, // pode ser nulo para limpar
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      query: query ?? this.query,
      categories: categories ?? this.categories,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}

class OffersNotifier extends Notifier<OffersState> {
  @override
  OffersState build() {
    // Carrega a primeira página imediatamente no build
    Future.microtask(() => loadOffers(refresh: true));
    return OffersState();
  }

  Future<void> loadOffers({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, currentPage: 1, hasReachedMax: false, error: null);
    } else {
      if (state.isLoadingMore || state.hasReachedMax) return;
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      final isOffline = !await sl<NetworkInfo>().isConnected;
      final repo = MockOfferRepository(sl<IsarCacheManager>(), isOffline: isOffline);

      final newOffers = await repo.getOffers(
        page: state.currentPage,
        limit: 20,
        query: state.query,
        categories: state.categories,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
      );

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        isOffline: isOffline,
        offers: refresh ? newOffers : [...state.offers, ...newOffers],
        currentPage: state.currentPage + 1,
        hasReachedMax: newOffers.length < 20,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  void updateFilters({
    String? query,
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
  }) {
    state = state.copyWith(
      query: query ?? state.query,
      categories: categories ?? state.categories,
      minPrice: minPrice ?? state.minPrice,
      maxPrice: maxPrice ?? state.maxPrice,
    );
    loadOffers(refresh: true);
  }

  void clearFilters() {
    state = OffersState(
      query: '',
      categories: [],
      minPrice: 0,
      maxPrice: 50000,
    );
    loadOffers(refresh: true);
  }
}

final offersProvider = NotifierProvider<OffersNotifier, OffersState>(() {
  return OffersNotifier();
});
