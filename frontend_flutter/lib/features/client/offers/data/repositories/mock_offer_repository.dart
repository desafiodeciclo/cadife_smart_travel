import 'package:cadife_smart_travel/core/cache/isar_cache_manager.dart';
import 'package:cadife_smart_travel/core/cache/isar_schemas/isar_schemas.dart';
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
        estimatedPrice: c.estimatedPrice,
        imageUrl: c.imageUrl,
      )).toList();

      filtered = _applyFilters(filtered, query, categories, minPrice, maxPrice);

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
    offers = _applyFilters(offers, query, categories, minPrice, maxPrice);

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
        estimatedPrice: o.estimatedPrice,
        imageUrl: o.imageUrl,
        updatedAt: DateTime.now(),
      )).toList();
      await _cacheManager.putOffers(isarOffers);
    }

    return pagedOffers;
  }

  List<Offer> _applyFilters(
    List<Offer> list, 
    String? query, 
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
      if (categories != null && categories.isNotEmpty) {
        if (!categories.contains(o.category)) return false;
      }
      if (minPrice != null && o.estimatedPrice < minPrice) return false;
      if (maxPrice != null && o.estimatedPrice > maxPrice) return false;
      return true;
    }).toList();
  }

  List<Offer> _generateMockOffers() {
    return List.generate(100, (index) {
      final category = _categories[index % _categories.length];
      final destination = _destinations[index % _destinations.length];
      return Offer(
        id: 'offer-$index',
        title: 'Pacote Especial: $destination',
        destination: destination,
        category: category,
        description: 'Explore o melhor de $destination neste pacote exclusivo de $category. Inclui hospedagem premium, passeios guiados e experiências gastronômicas inesquecíveis.',
        estimatedPrice: 1500.0 + (index * 150) % 15000,
        imageUrl: 'https://picsum.photos/seed/offer$index/600/400',
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
