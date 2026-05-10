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

class OffersListPage extends ConsumerWidget {
  const OffersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersProvider);
    final filters = ref.watch(offersFilterProvider);

    return PageScaffold(
      title: 'Ofertas',
      actions: [
        const NotificationBell(),
      ],
      body: Column(
        children: [
          // Busca (Visual apenas por enquanto)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShadInput(
              placeholder: const Text('Buscar destinos ou pacotes...'),
              onChanged: (v) {
                ref.read(offersFilterProvider.notifier).update((state) => state.copyWith(searchQuery: v));
              },
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
                      ),
                    );

                    if (result != null) {
                      ref.read(offersFilterProvider.notifier).update(
                        (state) => state.copyWith(
                          destination: result['destination'],
                          categories: result['categories'],
                          minPrice: result['minPrice'],
                          maxPrice: result['maxPrice'],
                          startDate: result['startDate'],
                          endDate: result['endDate'],
                          clearDestination: result['destination'] == null,
                          clearDates: result['startDate'] == null,
                        ),
                      );
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
                  onRefresh: () => ref.refresh(offersProvider.future),
                  child: CustomScrollView(
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
                  childAspectRatio: 0.7,
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
