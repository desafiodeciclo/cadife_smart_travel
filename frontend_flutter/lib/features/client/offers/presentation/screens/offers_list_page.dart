import 'dart:async';

import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/providers/offers_filter_provider.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/providers/offers_provider.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/widgets/offer_card.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/widgets/offer_shimmer.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/widgets/offers_filter_sheet.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/app_empty_state.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OffersListPage extends ConsumerStatefulWidget {
  const OffersListPage({super.key});

  @override
  ConsumerState<OffersListPage> createState() => _OffersListPageState();
}

class _OffersListPageState extends ConsumerState<OffersListPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final updated = ref.read(offersFilterProvider).copyWith(searchQuery: value);
      ref.read(offersFilterProvider.notifier).state = updated;
      _syncFilters(updated);
    });
  }

  void _syncFilters(OffersFilters filters) {
    ref.read(offersProvider.notifier).applyFilters(
      OffersFilterState(
        search: filters.searchQuery.isEmpty ? null : filters.searchQuery,
        destination: filters.destination,
        minPrice: filters.minPrice > 0 ? filters.minPrice : null,
        maxPrice: filters.maxPrice < 50000.0 ? filters.maxPrice : null,
        minDays: filters.minDays,
        maxDays: filters.maxDays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(offersProvider);
    final filters = ref.watch(offersFilterProvider);

    return PageScaffold(
      title: 'Ofertas',
      actions: [
        const NotificationBell(),
        const SizedBox(width: 8),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShadInput(
              controller: _searchController,
              placeholder: const Text('Buscar destinos ou pacotes...'),
              onChanged: _onSearchChanged,
              leading: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(LucideIcons.search, size: 16),
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ShadIconButton.ghost(
                  icon: Icon(
                    LucideIcons.slidersHorizontal,
                    size: 16,
                    color: filters != const OffersFilters() ? context.cadife.primary : null,
                  ),
                  onPressed: () async {
                    final result = await showModalBottomSheet<Map<String, dynamic>>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => OffersFilterSheet(
                        initialDestination: filters.destination,
                        initialCategories: filters.categories,
                        initialMinPrice: filters.minPrice,
                        initialMaxPrice: filters.maxPrice,
                        initialStartDate: filters.startDate,
                        initialEndDate: filters.endDate,
                        initialMinDays: filters.minDays,
                        initialMaxDays: filters.maxDays,
                      ),
                    );

                    if (result != null) {
                      final updated = ref.read(offersFilterProvider).copyWith(
                        destination: result['destination'] as String?,
                        categories: result['categories'] as List<String>?,
                        minPrice: result['minPrice'] as double?,
                        maxPrice: result['maxPrice'] as double?,
                        startDate: result['startDate'] as DateTime?,
                        endDate: result['endDate'] as DateTime?,
                        minDays: result['minDays'] as int?,
                        maxDays: result['maxDays'] as int?,
                        clearDestination: result['destination'] == null,
                        clearDates: result['startDate'] == null,
                        clearDuration: result['minDays'] == null,
                      );
                      ref.read(offersFilterProvider.notifier).state = updated;
                      _syncFilters(updated);
                    }
                  },
                ),
              ),
            ),
          ),



          // Lista / Grid
          Expanded(
            child: offersAsync.when(
              data: (offers) {
                if (offers.isEmpty) {
                  return const AppEmptyState(
                    type: EmptyType.noOffers,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(offersProvider.notifier).loadOffers(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                            childAspectRatio: 0.58,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final offer = offers[index];
                              return OfferCard(
                                offer: offer,
                                onTap: () {
                                  context.pushNamed(
                                    'client_offer_details',
                                    pathParameters: {'offerId': offer.id},
                                    extra: offer,
                                  );
                                },
                              );
                            },
                            childCount: offers.length,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                );
              },
              loading: () => GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  childAspectRatio: 0.58,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 6,
                itemBuilder: (_, _) => const OfferShimmer(),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.circleAlert, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Erro ao carregar ofertas: $err'),
                    const SizedBox(height: 16),
                    ShadButton(
                      child: const Text('Tentar novamente'),
                      onPressed: () => ref.refresh(offersProvider),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
