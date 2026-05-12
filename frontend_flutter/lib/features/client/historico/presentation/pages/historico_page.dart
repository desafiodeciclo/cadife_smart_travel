import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/providers/historico_notifier.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/widgets/trip_history_card.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/state_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HistoricoPage extends ConsumerStatefulWidget {
  const HistoricoPage({super.key});

  @override
  ConsumerState<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends ConsumerState<HistoricoPage> {
  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(travelHistoryProvider);

    return PageScaffold(
      title: 'Histórico',
      actions: const [NotificationBell(), SizedBox(width: 8)],
      body: StateListView(
        state: tripsAsync,
        onRetry: () => ref.read(travelHistoryProvider.notifier).refresh(),
        emptyType: EmptyType.noTrips,
        padding: const EdgeInsets.only(top: kToolbarHeight, bottom: 96, left: 16, right: 16),
        itemBuilder: (trip, index) {
          return TripHistoryCard(
            trip: trip,
            onTap: () {
              context.push('/client/travel/${trip.id}/calendar');
            },
          );
        },
      ),
    );
  }
}

