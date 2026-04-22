import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/core/widgets/shimmer_loading.dart';
import 'package:cadife_smart_travel/features/agency/leads/leads_notifier.dart';
import 'package:cadife_smart_travel/features/agency/leads/leads_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LeadsScreen extends ConsumerWidget {
  const LeadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(leadsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(leadsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: leadsAsync.when(
        loading: () => ShimmerLoading(
          isLoading: true,
          child: AppSkeletons.listPage(),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Erro ao carregar leads.'),
              TextButton(
                onPressed: () => ref.read(leadsNotifierProvider.notifier).refresh(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (leads) => leads.isEmpty
            ? const Center(child: Text('Nenhum lead encontrado.'))
            : RefreshIndicator(
                onRefresh: () => ref.read(leadsNotifierProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: leads.length,
                  itemBuilder: (context, i) => _LeadCard(lead: leads[i]),
                ),
              ),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final Lead lead;
  const _LeadCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/agency/leads/${lead.id}'),
        leading: CircleAvatar(
          backgroundColor: lead.score != null
              ? AppColors.scoreColor(lead.score!)
              : AppColors.textSecondary,
          child: Text(
            (lead.nome?.isNotEmpty == true ? lead.nome![0] : '?').toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(lead.nome ?? lead.telefone),
        subtitle: Text(lead.telefone),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _StatusChip(status: lead.status),
            if (lead.completudePct != null)
              Text(
                '${lead.completudePct}% briefing',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.statusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusColor(status)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 11,
          color: AppColors.statusColor(status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
