import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../auth/auth_notifier.dart';
import 'leads_notifier.dart';
import 'leads_repository.dart';

final _leadDetailProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.read(leadsRepositoryProvider).getLeadDetail(id),
);

class LeadDetailScreen extends ConsumerWidget {
  final String leadId;
  const LeadDetailScreen({super.key, required this.leadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(_leadDetailProvider(leadId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do Lead')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (lead) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoCard(lead: lead),
              const SizedBox(height: 16),
              if (lead['briefing'] != null) _BriefingCard(briefing: lead['briefing']),
              const SizedBox(height: 16),
              _ActionButtons(leadId: leadId, currentStatus: lead['status']),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Map<String, dynamic> lead;
  const _InfoCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lead['nome'] ?? 'Sem nome', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(lead['telefone'], style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                _Chip(label: lead['status'], color: AppColors.statusColor(lead['status'])),
                if (lead['score'] != null) ...[
                  const SizedBox(width: 8),
                  _Chip(
                    label: lead['score'],
                    color: AppColors.scoreColor(lead['score']),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BriefingCard extends StatelessWidget {
  final Map<String, dynamic> briefing;
  const _BriefingCard({required this.briefing});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Briefing', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '${briefing['completude_pct'] ?? 0}%',
                  style: TextStyle(
                    color: (briefing['completude_pct'] ?? 0) >= 60
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (briefing['destino'] != null) _row('Destino', briefing['destino']),
            if (briefing['data_ida'] != null) _row('Ida', briefing['data_ida']),
            if (briefing['data_volta'] != null) _row('Volta', briefing['data_volta']),
            if (briefing['qtd_pessoas'] != null) _row('Pessoas', '${briefing['qtd_pessoas']}'),
            if (briefing['perfil'] != null) _row('Perfil', briefing['perfil']),
            if (briefing['orcamento'] != null) _row('Orçamento', briefing['orcamento']),
            if (briefing['observacoes'] != null) _row('Obs.', briefing['observacoes']),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}

class _ActionButtons extends ConsumerWidget {
  final String leadId;
  final String currentStatus;
  const _ActionButtons({required this.leadId, required this.currentStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today),
          label: const Text('Agendar'),
          onPressed: () {},
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.description),
          label: const Text('Criar Proposta'),
          onPressed: () {},
        ),
        if (currentStatus == 'qualificado')
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Aprovar'),
            onPressed: () {},
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
