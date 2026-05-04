import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/dashboard_provider.dart';
import 'package:flutter/material.dart';

class SummarySection extends StatelessWidget {
  const SummarySection({
    super.key,
    required this.stats,
  });

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo do Dia',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _SummaryCard(
                label: 'Total de Leads',
                value: '${stats.totalLeads}',
                icon: Icons.people,
                color: AppColors.primary,
              ),
              _SummaryCard(
                label: 'Novos Hoje',
                value: '${stats.leadsPorStatus['novo'] ?? 0}',
                icon: Icons.trending_up,
                color: AppColors.warning,
                variation: '+12%',
              ),
              _SummaryCard(
                label: 'Agendamentos',
                value: '${stats.todayAgenda}',
                icon: Icons.calendar_month,
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.variation,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? variation;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: context.cadife.textSecondary,
              ),
            ),
            if (variation != null) ...[
              const SizedBox(height: 4),
              Text(
                variation!,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
