import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/trip_summary.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/providers/historico_notifier.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/widgets/trip_history_card.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/app_empty_state.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HistoricoPage extends ConsumerStatefulWidget {
  const HistoricoPage({super.key});

  @override
  ConsumerState<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends ConsumerState<HistoricoPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TripSummary> _filter(List<TripSummary> trips) {
    if (_searchQuery.isEmpty) return trips;
    final q = _searchQuery.toLowerCase();
    return trips
        .where(
          (t) =>
              t.name.toLowerCase().contains(q) ||
              (t.destino?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(travelHistoryProvider);

    return PageScaffold(
      title: 'Histórico',
      actions: const [NotificationBell(), SizedBox(width: 8)],
      body: Column(
        children: [
          const SizedBox(height: kToolbarHeight),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShadInput(
              controller: _searchController,
              placeholder: const Text('Buscar viagem...'),
              onChanged: (v) => setState(() => _searchQuery = v),
              leading: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(LucideIcons.search, size: 16),
              ),
            ),
          ),

          // List
          Expanded(
            child: tripsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (trips) {
                final filtered = _filter(trips);

                if (filtered.isEmpty) {
                  return AppEmptyState(
                    type: _searchQuery.isNotEmpty
                        ? EmptyType.emptySearch
                        : EmptyType.noTrips,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(travelHistoryProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final trip = filtered[index];
                      return TripHistoryCard(
                        trip: trip,
                        onTap: () => context
                            .push('/client/travel/${trip.id}/details'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
