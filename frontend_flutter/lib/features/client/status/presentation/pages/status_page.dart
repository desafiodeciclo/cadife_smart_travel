import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/auth/providers/auth_provider.dart';
import 'package:cadife_smart_travel/features/client/documentos/presentation/widgets/documents_section.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/providers/status_providers.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/ongoing_trip_card.dart';
import 'package:cadife_smart_travel/features/client/status/presentation/widgets/status_stepper_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class StatusPage extends ConsumerWidget {
  const StatusPage({super.key});

  int _mapLeadStatusToStep(LeadStatus? status) {
    if (status == null) return 0;
    switch (status) {
      case LeadStatus.novo:
      case LeadStatus.emAtendimento:
      case LeadStatus.qualificado:
      case LeadStatus.agendado:
        return 0;
      case LeadStatus.proposta:
        return 1;
      case LeadStatus.fechado:
        return 2;
      default:
        return 0;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'A definir';
    return DateFormat('dd MMM yyyy', 'pt_BR').format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.valueOrNull?.user?.name ?? 'Viajante';
    final activeLeadAsync = ref.watch(activeLeadProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Cadife Tour'),
            floating: true,
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: activeLeadAsync.when(
              loading: () => const _StatusLoadingState(),
              error: (err, stack) => Center(child: Text('Erro ao carregar dados: $err')),
              data: (lead) {
                final currentStep = _mapLeadStatusToStep(lead?.status);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GreetingSection(userName: userName),
                    const SizedBox(height: 12),
                    StatusStepperWidget(currentStep: currentStep),
                    const SizedBox(height: 20),
                    OngoingTripCard(
                      destination: lead?.destino ?? 'Próxima aventura',
                      date: _formatDate(lead?.dataIda),
                      time: lead?.dataIda != null ? DateFormat('HH:mm').format(lead!.dataIda!) : '--:--',
                      imageUrl: null,
                    ),
                    const SizedBox(height: 24),
                    ConsultantCard(
                      consultantName: lead?.consultorNome ?? 'Ricardo Silva',
                      avatarUrl: lead?.consultorAvatar,
                    ),
                    const SizedBox(height: 24),
                    DocumentsSection(documents: ref.watch(clientDocumentsProvider)),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLoadingState extends StatelessWidget {
  const _StatusLoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircularProgressIndicator(color: Theme.of(context).primaryColor),
          const SizedBox(height: 20),
          const Text('Carregando sua viagem...'),
        ],
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, $userName!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sua próxima aventura começa em breve.',
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
