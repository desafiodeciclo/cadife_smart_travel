import 'dart:async';

import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/providers/offers_provider.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/widgets/offer_card.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/widgets/offer_shimmer.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/widgets/offers_filter_sheet.dart';
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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(offersProvider.notifier).loadOffers();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(offersProvider.notifier).updateFilters(query: query);
    });
  }

  Future<void> _openFilters() async {
    final state = ref.read(offersProvider);
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OffersFilterSheet(
        initialCategories: state.categories,
        initialMinPrice: state.minPrice,
        initialMaxPrice: state.maxPrice,
      ),
    );

    if (result != null) {
      ref.read(offersProvider.notifier).updateFilters(
        categories: result['categories'] as List<String>,
        minPrice: result['minPrice'] as double,
        maxPrice: result['maxPrice'] as double,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(offersProvider);
    final theme = ShadTheme.of(context);

    final showEmptyState = !state.isLoading && state.offers.isEmpty;
    final isFiltering = state.query != null && state.query!.isNotEmpty || state.categories.isNotEmpty || state.minPrice > 0 || state.maxPrice < 50000;

    return PageScaffold(
      title: 'Ofertas',
      actions: [
        IconButton(
          icon: Icon(
            LucideIcons.slidersHorizontal,
            color: state.categories.isNotEmpty ? theme.colorScheme.primary : null,
          ),
          onPressed: _openFilters,
        ),
      ],
      body: Column(
        children: [
          // Banner Offline
          if (state.isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.wifiOff, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Você está offline. Exibindo ofertas salvas.',
                    style: theme.textTheme.small.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          
          // Busca
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShadInput(
              controller: _searchController,
              placeholder: const Text('Buscar destinos ou pacotes...'),
              leading: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(LucideIcons.search, size: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Lista / Grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(offersProvider.notifier).loadOffers(refresh: true);
              },
              child: showEmptyState
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        AppEmptyState(
                          type: isFiltering ? EmptyType.emptySearch : EmptyType.noOffers,
                          onAction: isFiltering
                              ? () {
                                  _searchController.clear();
                                  ref.read(offersProvider.notifier).clearFilters();
                                }
                              : null,
                        ),
                      ],
                    )
                  : CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index < state.offers.length) {
                                  return OfferCard(
                                    offer: state.offers[index],
                                    onTap: () {
                                      context.pushNamed(
                                        'client_offer_details',
                                        pathParameters: {'offerId': state.offers[index].id},
                                        extra: state.offers[index],
                                      );
                                    },
                                  );
                                } else if (state.isLoading || state.isLoadingMore) {
                                  return const OfferShimmer();
                                }
                                return null;
                              },
                              childCount: state.offers.length +
                                  (state.isLoading || state.isLoadingMore ? 4 : 0),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
