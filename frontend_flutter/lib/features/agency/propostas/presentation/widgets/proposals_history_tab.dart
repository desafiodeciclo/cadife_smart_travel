import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/propostas/domain/entities/proposta.dart';
import 'package:cadife_smart_travel/features/agency/propostas/presentation/providers/proposals_provider.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/empty_state/empty_type.dart';
import 'package:cadife_smart_travel/shared/presentation/widgets/state_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProposalsHistoryTab extends ConsumerWidget {
  final Lead lead;
  const ProposalsHistoryTab({required this.lead, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(proposalsByLeadProvider(lead.id));

    return StateContainer<List<Proposta>>(
      state: proposalsAsync,
      onRetry: () => ref.refresh(proposalsByLeadProvider(lead.id)),
      isEmpty: proposalsAsync.valueOrNull?.isEmpty ?? true,
      customEmptyType: EmptyType.noProposals, // Assuming this exists or using default
      dataBuilder: (proposals) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: proposals.length + 1,
          itemBuilder: (context, index) {
            if (index == proposals.length) {
              return const SizedBox(height: 80); // Bottom padding
            }
            final proposal = proposals[index];
            return _ProposalCard(proposal: proposal);
          },
        );
      },
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final Proposta proposal;
  const _ProposalCard({required this.proposal});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(proposal.status);
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadCard(
        padding: const EdgeInsets.all(16),
        radius: BorderRadius.circular(16),
        border: ShadBorder.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    proposal.titulo ?? 'Proposta sem título',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ShadBadge(
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  foregroundColor: statusColor,
                  child: Text(
                    proposal.status.name.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoItem(
                  icon: Icons.monetization_on_outlined,
                  label: 'Valor',
                  value: fmt.format(proposal.totalValue),
                ),
                const SizedBox(width: 24),
                _InfoItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Criada em',
                  value: proposal.createdAt != null
                      ? dateFmt.format(proposal.createdAt!)
                      : 'N/A',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoItem(
                  icon: Icons.place_outlined,
                  label: 'Destino',
                  value: proposal.destino ?? 'Não informado',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: () {
                    // Visualizar PDF ou detalhes
                  },
                  child: const Text('Visualizar'),
                ),
                const SizedBox(width: 8),
                ShadButton(
                  size: ShadButtonSize.sm,
                  onPressed: () {
                    // Editar ou reenviar
                  },
                  child: const Text('Detalhes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ProposalStatus status) {
    switch (status) {
      case ProposalStatus.rascunho:
        return Colors.orange;
      case ProposalStatus.enviada:
        return Colors.blue;
      case ProposalStatus.aceita:
        return AppColors.success;
      case ProposalStatus.recusada:
        return AppColors.error;
      case ProposalStatus.expirada:
        return Colors.grey;
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
