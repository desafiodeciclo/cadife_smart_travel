import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/providers/historico_notifier.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/widgets/historico_states.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/widgets/trip_history_card.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/widgets/whatsapp_fab.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/state_container.dart';
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
      body: StateListView(
        state: tripsAsync,
        onRetry: () => ref.read(historicoProvider.notifier).refresh(),
        emptyType: EmptyType.noTrips,
        padding: const EdgeInsets.only(top: 72, bottom: 96, left: 16, right: 16),
        itemBuilder: (trip, index) {
          return TripHistoryCard(
            trip: trip,
            onTap: () {
              // Futura ação ao clicar na viagem
            },
          );
        },
      ),
    );
  }
}

