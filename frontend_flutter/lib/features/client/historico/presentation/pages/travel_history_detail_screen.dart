import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/trip_summary.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/providers/documentos_notifier.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/widgets/documents_section.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/providers/historico_notifier.dart';
import 'package:cadife_smart_travel/features/client/itinerary/domain/entities/itinerary_day.dart';
import 'package:cadife_smart_travel/features/client/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/itinerary_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TravelHistoryDetailScreen extends ConsumerWidget {
  const TravelHistoryDetailScreen({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(travelHistoryProvider);

    return tripsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Erro: $e')),
      ),
      data: (trips) {
        final trip = trips.where((t) => t.id == tripId).firstOrNull;
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Viagem')),
            body: const Center(child: Text('Viagem não encontrada')),
          );
        }
        return _DetailView(trip: trip);
      },
    );
  }
}

class _DetailView extends ConsumerWidget {
  const _DetailView({required this.trip});

  final TripSummary trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryState = ref.watch(itineraryProvider(trip.id));

    // Convert flat ItineraryItem list → sorted ItineraryDay list
    final days = itineraryState.itemsByDay.entries
        .map((e) => ItineraryDay(data: e.key, itens: e.value))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    final documentsAsync = ref.watch(tripDocumentsProvider(trip.id));

    return Scaffold(
      backgroundColor: context.cadife.background,
      body: CustomScrollView(
        slivers: [
          // Hero cover + AppBar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: context.cadife.background,
            flexibleSpace: FlexibleSpaceBar(
              background: _CoverImage(trip: trip),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title + destination
                Text(
                  trip.name,
                  style: AppTextStyles.h2.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.cadife.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (trip.destino != null)
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: context.cadife.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trip.destino!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: context.cadife.textSecondary,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // Info chips
                _TripInfoRow(trip: trip),

                const SizedBox(height: 28),

                // Documents section
                documentsAsync.when(
                  data: (docs) => Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: DocumentsSection(documents: docs),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.only(bottom: 28),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                // Roteiro section
                if (trip.roteiro != null) ...[
                  Text(
                    'Itinerário',
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.cadife.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ShadCard(
                    padding: const EdgeInsets.all(16),
                    radius: BorderRadius.circular(14),
                    border: ShadBorder.all(color: context.cadife.cardBorder),
                    child: Text(
                      trip.roteiro!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.cadife.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Itinerary section
                if (itineraryState.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (days.isNotEmpty)
                  ItineraryWidget(days: days, isCompact: false),

                const SizedBox(height: 96),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.trip});

  final TripSummary trip;

  @override
  Widget build(BuildContext context) {
    if (trip.imageUrl == null) {
      return Container(
        color: context.cadife.muted,
        child: Center(
          child: Icon(
            LucideIcons.plane,
            size: 64,
            color: context.cadife.textSecondary,
          ),
        ),
      );
    }

    return Hero(
      tag: 'trip_image_${trip.id}',
      child: Image.network(
        trip.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, e, s) => Container(
          color: context.cadife.muted,
          child: Icon(
            LucideIcons.image,
            size: 64,
            color: context.cadife.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TripInfoRow extends StatelessWidget {
  const _TripInfoRow({required this.trip});

  final TripSummary trip;

  @override
  Widget build(BuildContext context) {
    String dateRange = '—';
    if (trip.dataIda != null) {
      final fmt = DateFormat('dd/MM/yy');
      final start = fmt.format(trip.dataIda!);
      final end = trip.dataVolta != null ? fmt.format(trip.dataVolta!) : '?';
      dateRange = '$start – $end';
    }

    final budget = trip.orcamento != null
        ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
            .format(trip.orcamento)
        : null;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _InfoChip(
          icon: LucideIcons.calendar,
          label: dateRange,
        ),
        if (trip.numPessoas != null)
          _InfoChip(
            icon: LucideIcons.users,
            label:
                '${trip.numPessoas} ${trip.numPessoas == 1 ? 'pessoa' : 'pessoas'}',
          ),
        if (budget != null)
          _InfoChip(
            icon: LucideIcons.wallet,
            label: budget,
            color: AppColors.primary,
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.cadife.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
