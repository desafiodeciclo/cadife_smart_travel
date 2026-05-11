import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/widgets/itinerary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ItineraryPreviewSection extends ConsumerWidget {
  const ItineraryPreviewSection({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cadife = context.cadife;
    final state = ref.watch(itineraryProvider(tripId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ITINERÁRIO (${state.items.length})',
              style: TextStyle(
                color: cadife.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            GestureDetector(
              onTap: () => context.pushNamed(
                'client_travel_calendar',
                pathParameters: {'tripId': tripId},
              ),
              child: Text(
                'Ver calendário',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cadife.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (state.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cadife.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cadife.cardBorder),
            ),
            child: Column(
              children: [
                Text(
                  'Erro ao carregar itinerário',
                  style: TextStyle(
                    fontSize: 13,
                    color: cadife.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.error!,
                  style: TextStyle(
                    fontSize: 12,
                    color: cadife.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (state.items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cadife.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cadife.cardBorder),
            ),
            child: Text(
              'Itinerário será disponibilizado após a curadoria',
              style: TextStyle(
                fontSize: 13,
                color: cadife.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          CadifeCard(
            padding: EdgeInsets.zero,
            borderRadius: 16,
            showBorder: true,
            child: Column(
              children: [
                for (int i = 0; i < state.items.take(3).length; i++) ...[
                  ItineraryCard(
                    key: ValueKey('home_itin_${state.items[i].id}'),
                    item: state.items[i],
                    showCard: false,
                    showBorder: false,
                  ),
                  if (i < state.items.take(3).length - 1)
                    Divider(height: 1, thickness: 1, color: cadife.cardBorder, indent: 12, endIndent: 12),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
