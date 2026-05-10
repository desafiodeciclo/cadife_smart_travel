import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/client_travel_status.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/providers/status_notifier.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/providers/status_providers.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/ongoing_trip_card.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/status_stepper_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StatusPage extends ConsumerWidget {
  const StatusPage({this.tripId, super.key});

  final String? tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cadife = context.cadife;
    
    // Se tripId for fornecido, usa o statusProvider. Caso contrário, usa o activeLeadProvider.
    final statusAsync = tripId != null 
        ? ref.watch(statusProvider(tripId!))
        : ref.watch(activeLeadProvider);

    return PageScaffold(
      title: tripId != null ? 'DETALHES DA VIAGEM' : 'MINHA VIAGEM',
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro ao carregar status: $err')),
        data: (status) {
          if (status == null) {
            return const Center(child: Text('Nenhuma viagem encontrada.'));
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OngoingTripCard(
                    destination: status.destino ?? 'Destino não definido',
                    date: status.dataPartida != null 
                        ? DateFormat('dd MMM yyyy').format(status.dataPartida!)
                        : 'Data a definir',
                    imageUrl: '', // Poderia vir do status se disponível
                    onTap: () => _navigateToCalendar(context, status.id),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sua Jornada',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: cadife.textPrimary,
                        ),
                      ),
                      ShadButton.outline(
                        onPressed: () => _navigateToCalendar(context, status.id),
                        leading: const Icon(LucideIcons.calendar, size: 16),
                        child: const Text('Calendário'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  StatusStepperWidget(currentStep: _mapStatusToStep(status.status)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _mapStatusToStep(TravelStatus status) {
    switch (status) {
      case TravelStatus.emAtendimento:
      case TravelStatus.qualificado:
      case TravelStatus.agendado:
        return 0;
      case TravelStatus.proposta:
        return 1;
      case TravelStatus.confirmado:
        return 2;
    }
  }

  void _navigateToCalendar(BuildContext context, String leadId) {
    context.pushNamed(
      'client_travel_calendar',
      pathParameters: {'leadId': leadId},
    );
  }
}
