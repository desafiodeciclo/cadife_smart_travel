import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/lead_detail_provider.dart';
import 'package:cadife_smart_travel/features/agency/propostas/presentation/widgets/proposals_history_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProposalsPage extends ConsumerWidget {
  final String leadId;
  const ProposalsPage({required this.leadId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadAsync = ref.watch(leadDetailProvider(leadId));

    return Scaffold(
      appBar: leadAsync.when(
        data: (lead) => AppBar(
          title: Text('Propostas: ${lead?.name ?? ""}'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/agency/proposals/$leadId/new'),
            ),
          ],
        ),
        loading: () => AppBar(title: const Text('Carregando...')),
        error: (_, _) => AppBar(title: const Text('Erro')),
      ),
      body: leadAsync.when(
        data: (lead) {
          if (lead == null) return const Center(child: Text('Lead não encontrado'));
          return ProposalsHistoryTab(lead: lead);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erro ao carregar lead: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/agency/proposals/$leadId/new'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
