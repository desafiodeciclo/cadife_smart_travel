import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/features/agency/lead_detail/lead_detail_provider.dart';
import 'package:cadife_smart_travel/shared/models/lead_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeadDetailScreen extends ConsumerWidget {
  final String leadId;
  const LeadDetailScreen({super.key, required this.leadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(leadDetailProvider(leadId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do Lead')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (lead) => lead == null
            ? const Center(child: Text('Lead não encontrado.'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoCard(lead: lead),
                    const SizedBox(height: 16),
                    if (lead.destino != null) _BriefingCard(lead: lead),
                    const SizedBox(height: 16),
                    _ActionButtons(leadId: leadId, currentStatus: lead.status),
                  ],
                ),
              ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final LeadModel lead;
  const _InfoCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lead.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              lead.phone,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Chip(
                  label: lead.status.name,
                  color: AppColors.statusColor(lead.status.name),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: lead.score.name,
                  color: AppColors.scoreColor(lead.score.name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BriefingCard extends StatelessWidget {
  final LeadModel lead;
  const _BriefingCard({required this.lead});

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
                  '${lead.completudePct}%',
                  style: TextStyle(
                    color: lead.completudePct >= 60
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (lead.destino != null) _row('Destino', lead.destino!),
            if (lead.dataIda != null)
              _row('Ida', lead.dataIda!.toLocal().toString().split(' ')[0]),
            if (lead.dataVolta != null)
              _row('Volta', lead.dataVolta!.toLocal().toString().split(' ')[0]),
            if (lead.numPessoas != null)
              _row('Pessoas', '${lead.numPessoas}'),
            if (lead.perfil != null) _row('Perfil', lead.perfil!),
            if (lead.orcamentoFaixa != null)
              _row('Orçamento', lead.orcamentoFaixa!),
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
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _ActionButtons extends ConsumerWidget {
  final String leadId;
  final LeadStatus currentStatus;
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
        if (currentStatus == LeadStatus.qualificado)
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
