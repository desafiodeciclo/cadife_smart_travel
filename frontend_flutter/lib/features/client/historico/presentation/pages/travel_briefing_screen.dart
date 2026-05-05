import 'package:cadife_smart_travel/config/responsive/master_detail_layout.dart';
import 'package:cadife_smart_travel/config/responsive/responsive_breakpoints.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/providers/historico_notifier.dart';
import 'package:cadife_smart_travel/features/client/historico/presentation/widgets/trip_history_card.dart';
import 'package:cadife_smart_travel/features/client/documentos/domain/entities/trip_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TravelBriefingScreen extends ConsumerWidget {
  final String? tripId;
  
  const TravelBriefingScreen({this.tripId, super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(historicoProvider);
    final selectedTripId = ref.watch(selectedClientTripProvider);
    
    return MasterDetailLayout(
      master: (context) => Scaffold(
        appBar: AppBar(title: const Text('Minhas Viagens')),
        body: tripsAsync.when(
          data: (trips) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              final isSelected = trip.id == (selectedTripId ?? tripId);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TripHistoryCard(
                  trip: trip,
                  onTap: () {
                    ref.read(selectedClientTripProvider.notifier).state = trip.id;
                    if (context.isMobile) {
                      context.push('/client/interactions/${trip.id}');
                    }
                  },
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => const Center(child: Text('Erro ao carregar viagens')),
        ),
      ),
      
      detail: (context) => TravelBriefingContent(
        tripId: selectedTripId ?? tripId ?? '',
      ),
      
      showDetail: selectedTripId != null || tripId != null,
    );
  }
}

class TravelBriefingContent extends ConsumerWidget {
  final String tripId;
  
  const TravelBriefingContent({required this.tripId, super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tripId.isEmpty) return const SizedBox.shrink();

    // In a real app, we would fetch the specific briefing for tripId
    // For now, we'll try to find it in the history list or show a placeholder
    final tripsAsync = ref.watch(historicoProvider);
    
    return tripsAsync.when(
      data: (trips) {
        final trip = trips.firstWhere((t) => t.id == tripId, orElse: () => trips.first);
        
        return Scaffold(
          appBar: AppBar(
            title: Text(trip.name),
            leading: context.isMobile
              ? BackButton(onPressed: () => context.pop())
              : null,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trip.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      trip.imageUrl!,
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Destino: ${trip.destino}',
                  style: context.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Datas: ${trip.dataIda.toIso8601String().split('T')[0]} a ${trip.dataVolta?.toIso8601String().split('T')[0] ?? "..."}',
                  style: context.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                Text(
                  'Detalhes do Briefing',
                  style: context.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _BriefingItem(label: 'Número de Pessoas', value: '${trip.numPessoas}'),
                _BriefingItem(label: 'Orçamento Estimado', value: 'R$ ${trip.orcamento?.toStringAsFixed(2) ?? "0.00"}'),
                // Adicione mais itens conforme necessário
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('Erro ao carregar detalhes')),
    );
  }
}

class _BriefingItem extends StatelessWidget {
  final String label;
  final String value;

  const _BriefingItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.cadife.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
