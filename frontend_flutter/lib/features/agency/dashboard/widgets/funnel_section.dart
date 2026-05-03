import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/dashboard_provider.dart';
import 'package:flutter/material.dart';

class FunnelSection extends StatelessWidget {
  const FunnelSection({
    super.key,
    required this.stats,
  });

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final novo = stats.leadsPorStatus['novo'] ?? 0;
    final qualificado = stats.leadsPorStatus['qualificado'] ?? 0;
    final proposta = stats.leadsPorStatus['proposta'] ?? 0;
    final fechado = stats.leadsPorStatus['fechado'] ?? 0;
    final maxValue = [novo, qualificado, proposta, fechado].reduce((a, b) => a > b ? a : b).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Funil de Leads',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _FunnelBar(
                    label: 'Novo',
                    value: novo,
                    maxValue: maxValue,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  _FunnelBar(
                    label: 'Qualificado',
                    value: qualificado,
                    maxValue: maxValue,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 12),
                  _FunnelBar(
                    label: 'Proposta',
                    value: proposta,
                    maxValue: maxValue,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  _FunnelBar(
                    label: 'Fechado',
                    value: fechado,
                    maxValue: maxValue,
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FunnelBar extends StatelessWidget {
  const _FunnelBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percentage = maxValue > 0 ? (value / maxValue) * 100 : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 24,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
