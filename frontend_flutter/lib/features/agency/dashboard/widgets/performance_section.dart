import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/dashboard/dashboard_provider.dart';
import 'package:flutter/material.dart';

class PerformanceSection extends StatelessWidget {
  const PerformanceSection({
    super.key,
    required this.stats,
  });

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QualificationRateCard(
                  taxa: stats.taxaQualificacao,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ConversionRateCard(
                  taxa: stats.taxaConversao,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QualificationRateCard extends StatelessWidget {
  const _QualificationRateCard({required this.taxa});

  final double taxa;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      radius: BorderRadius.circular(12),
      border: ShadBorder.all(color: context.cadife.cardBorder),
      child: Column(
        children: [
          Text(
            'Taxa de Qualificação',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.cadife.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth * 0.7;
              final strokeWidth = size * 0.08;
              final fontSize = size * 0.22;
              return SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: taxa / 100,
                      strokeWidth: strokeWidth,
                      backgroundColor: context.cadife.muted,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        taxa >= 70 ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    Text(
                      '${taxa.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ConversionRateCard extends StatelessWidget {
  const _ConversionRateCard({required this.taxa});

  final double taxa;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      radius: BorderRadius.circular(12),
      border: ShadBorder.all(color: context.cadife.cardBorder),
      child: Column(
        children: [
          Text(
            'Taxa de Conversão',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.cadife.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up,
                color: taxa >= 30 ? AppColors.success : AppColors.warning,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '${taxa.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: taxa >= 30 ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
