import 'package:cadife_smart_travel/core/cache/isar_cache_manager.dart';
import 'package:cadife_smart_travel/core/cache/isar_schemas/isar_schemas.dart';

import 'package:cadife_smart_travel/features/client/offers/domain/entities/date_range.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/repositories/i_offer_repository.dart';

class MockOfferRepository implements IOfferRepository {
  final IsarCacheManager _cacheManager;
  final bool isOffline;

  MockOfferRepository(this._cacheManager, {this.isOffline = false});

  @override
  Future<List<Offer>> getOffers({
    int page = 1,
    int limit = 20,
    String? query,
    String? destination,
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
  }) async {
    // Se estiver offline, buscar do Isar
    if (isOffline) {
      final cachedOffers = await _cacheManager.getAllOffers();
      
      var filtered = cachedOffers.map((c) => Offer(
        id: c.serverId,
        title: c.title,
        destination: c.destination,
        category: c.category,
        description: c.description,
        basePrice: c.estimatedPrice,
        price: c.estimatedPrice,
        currency: 'BRL',
        imageUrl: c.imageUrl,
        dates: DateRange(
          start: DateTime.now(),
          end: DateTime.now().add(const Duration(days: 7)),
        ),
        daysCount: 7,
        rating: 4.5,
        travelers: 2,
        availableSpots: 10,
        spotsReserved: 0,
        status: 'published',
        highlights: const [],
        amenities: const [],
        views: 0,
        interests: 0,
      )).toList();

      filtered = _applyFilters(filtered, query, destination, categories, minPrice, maxPrice);

      // Paginação
      final start = (page - 1) * limit;
      if (start >= filtered.length) return [];
      return filtered.sublist(start, (start + limit).clamp(0, filtered.length));
    }

    // Se online, simula delay da rede
    await Future.delayed(const Duration(milliseconds: 800));

    // Gera dados mockados
    var offers = _generateMockOffers();
    
    // Aplica os mesmos filtros
    offers = _applyFilters(offers, query, destination, categories, minPrice, maxPrice);

    // Paginação
    final start = (page - 1) * limit;
    final pagedOffers = start >= offers.length 
      ? <Offer>[] 
      : offers.sublist(start, (start + limit).clamp(0, offers.length));

    // Salva no cache os itens que vieram da "API"
    if (pagedOffers.isNotEmpty) {
      final isarOffers = pagedOffers.map((o) => OfferCache(
        serverId: o.id,
        title: o.title,
        destination: o.destination,
        category: o.category,
        description: o.description,
        estimatedPrice: o.finalPrice,
        imageUrl: o.destinationImageUrl,
        updatedAt: DateTime.now(),
      )).toList();
      await _cacheManager.putOffers(isarOffers);
    }

    return pagedOffers;
  }

  List<Offer> _applyFilters(
    List<Offer> list, 
    String? query, 
    String? destination,
    List<String>? categories, 
    double? minPrice, 
    double? maxPrice
  ) {
    return list.where((o) {
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        if (!o.title.toLowerCase().contains(q) && !o.destination.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (destination != null && destination.isNotEmpty) {
        if (o.destination != destination) return false;
      }
      if (categories != null && categories.isNotEmpty) {
        if (!categories.contains(o.category)) return false;
      }
      if (minPrice != null && o.finalPrice < minPrice) return false;
      if (maxPrice != null && o.finalPrice > maxPrice) return false;
      return true;
    }).toList();
  }

  List<Offer> _generateMockOffers() {
    return List.generate(100, (index) {
      final category = _categories[index % _categories.length];
      final destination = _destinations[index % _destinations.length];
      final basePrice = 2000.0 + (index * 150) % 15000;
      return Offer(
        id: 'offer-$index',
        title: 'Pacote Especial: $destination',
        destination: destination,
        category: category,
        description: 'Explore o melhor de $destination neste pacote exclusivo de $category. Inclui hospedagem premium, passeios guiados e experiências gastronômicas inesquecíveis.',
        basePrice: basePrice,
        price: basePrice * 0.9,
        imageUrl: 'https://picsum.photos/seed/offer$index/600/400',
        dates: DateRange(
          start: DateTime.now().add(Duration(days: index * 2)),
          end: DateTime.now().add(Duration(days: index * 2 + 7)),
        ),
        daysCount: 7,
        rating: 4.5 + (index % 5) / 10,
        travelers: 2,
        availableSpots: 20,
        spotsReserved: index % 10,
        status: 'published',
        highlights: const ['Highlight 1', 'Highlight 2'],
        amenities: const ['Amenity 1', 'Amenity 2'],
        views: 50 + index,
        interests: 5 + (index % 20),
      );
    });
  }

  static const _categories = [
    'Sol & Praia',
    'Neve & Frio',
    'Urbano & Cultura',
    'Aventura & Natureza',
    'Cruzeiro'
  ];

  static const _destinations = [
    'Maldivas', 'Paris', 'Gramado', 'Cancún', 'Tóquio', 
    'Nova York', 'Alpes Suíços', 'Patagônia', 'Caribe', 'Dubai'
  ];
}
