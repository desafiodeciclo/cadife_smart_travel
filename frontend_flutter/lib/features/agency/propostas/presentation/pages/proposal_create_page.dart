import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/lead_detail_provider.dart';
import 'package:cadife_smart_travel/features/agency/propostas/presentation/widgets/proposal_form_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProposalCreateScreen extends ConsumerWidget {
  final String leadId;
  final String consultorId;

  const ProposalCreateScreen({
    required this.leadId,
    required this.consultorId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadAsync = ref.watch(leadDetailProvider(leadId));

    return Scaffold(
      appBar: leadAsync.when(
        data: (lead) => AppBar(
          title: Text('Nova Proposta: ${lead?.name ?? ""}'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        loading: () => AppBar(title: const Text('Carregando...')),
        error: (_, _) => AppBar(title: const Text('Erro')),
      ),
      body: leadAsync.when(
        data: (lead) {
          if (lead == null) return const Center(child: Text('Lead não encontrado'));
          return ProposalFormTab(lead: lead);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erro ao carregar lead: $e')),
      ),
    );
  }
}
