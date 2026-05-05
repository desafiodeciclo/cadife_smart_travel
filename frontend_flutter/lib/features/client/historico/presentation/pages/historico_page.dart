import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/providers/historico_notifier.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/widgets/historico_states.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/widgets/trip_history_card.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/widgets/whatsapp_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoricoPage extends ConsumerStatefulWidget {
  const HistoricoPage({super.key});

  @override
  ConsumerState<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends ConsumerState<HistoricoPage> {
  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(historicoProvider);

    return PageScaffold(
      title: 'Histórico',
      floatingActionButton: const WhatsAppFab(),
      body: tripsAsync.when(
        loading: () => const HistoricoShimmer(),
        error: (_, s) => HistoricoErrorState(
          onRetry: () => ref.invalidate(historicoProvider),
        ),
        data: (trips) {
          if (trips.isEmpty) return const HistoricoEmptyState();
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(historicoProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 72, bottom: 96, left: 16, right: 16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return TripHistoryCard(
                  trip: trip,
                  onTap: () {
                    // Futura ação ao clicar na viagem
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
