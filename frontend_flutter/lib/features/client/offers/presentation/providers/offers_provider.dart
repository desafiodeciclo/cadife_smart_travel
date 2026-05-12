import 'package:cadife_smart_travel/data/mock/offers_mock.dart';
import 'package:cadife_smart_travel/features/client/offers/domain/entities/offer.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/providers/offers_filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final offersProvider = FutureProvider<List<Offer>>((ref) async {
  final filters = ref.watch(offersFilterProvider);
  
  // Simula um delay de rede para demonstração do estado de loading
  await Future.delayed(const Duration(milliseconds: 600));
  
  var offers = List<Offer>.from(mockOffers);

  // Filtro por busca (título ou destino)
  if (filters.searchQuery.isNotEmpty) {
    final query = filters.searchQuery.toLowerCase();
    offers = offers.where((o) => 
      o.title.toLowerCase().contains(query) || 
      o.destination.toLowerCase().contains(query)
    ).toList();
  }

  // Filtro por destino
  if (filters.destination != null) {
    offers = offers.where((o) => o.destination == filters.destination).toList();
  }


  // Filtro por categorias
  if (filters.categories.isNotEmpty) {
    offers = offers.where((o) => filters.categories.contains(o.category)).toList();
  }

  // Filtro por preço
  offers = offers.where((o) => o.price >= filters.minPrice && o.price <= filters.maxPrice).toList();

  // Filtro por período
  if (filters.startDate != null && filters.endDate != null) {
    offers = offers.where((o) {
      // Verifica se há sobreposição entre o período desejado e o período da oferta
      return !(o.dates.start.isAfter(filters.endDate!) || o.dates.end.isBefore(filters.startDate!));
    }).toList();
  }
  
  return offers;
});

