import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecentLeadsSection extends StatelessWidget {
  const RecentLeadsSection({required this.leads, super.key});

  final List<Lead> leads;

  @override
  Widget build(BuildContext context) {
    final recent = leads.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leads Recentes',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            _EmptyLeads()
          else
            ...recent.map(
              (lead) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LeadRow(lead: lead),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeadRow extends StatelessWidget {
  const _LeadRow({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(lead.status);
    final statusLabel = _statusLabel(lead.status);
    final timeAgo = _timeAgo(lead.createdAt);

    return GestureDetector(
      onTap: () => context.pushNamed(
        'agency_lead_details',
        pathParameters: {'leadId': lead.id},
      ),
      child: ShadCard(
        padding: const EdgeInsets.all(12),
        radius: BorderRadius.circular(12),
        border: ShadBorder.all(color: context.cadife.cardBorder),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  _initials(lead.name),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lead.destino ?? 'Destino não informado',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.cadife.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Status + time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgo,
                  style: AppTextStyles.caption.copyWith(
                    color: context.cadife.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static Color _statusColor(LeadStatus status) => switch (status) {
        LeadStatus.novo => const Color(0xFF3B82F6),
        LeadStatus.emAtendimento => const Color(0xFFF97316),
        LeadStatus.qualificado => const Color(0xFF8B5CF6),
        LeadStatus.agendado => const Color(0xFF06B6D4),
        LeadStatus.proposta => const Color(0xFF3B82F6),
        LeadStatus.fechado => const Color(0xFF22C55E),
        LeadStatus.perdido => const Color(0xFF6B7280),
      };

  static String _statusLabel(LeadStatus status) => switch (status) {
        LeadStatus.novo => 'Novo',
        LeadStatus.emAtendimento => 'Atendimento',
        LeadStatus.qualificado => 'Qualificado',
        LeadStatus.agendado => 'Agendado',
        LeadStatus.proposta => 'Proposta',
        LeadStatus.fechado => 'Fechado',
        LeadStatus.perdido => 'Perdido',
      };

  static String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays}d';
  }
}

class _EmptyLeads extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'Nenhum lead recente',
          style: AppTextStyles.bodySmall
              .copyWith(color: context.cadife.textSecondary),
        ),
      ),
    );
  }
}
