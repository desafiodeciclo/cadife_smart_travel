import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

class PipelineStatusSection extends StatelessWidget {
  const PipelineStatusSection({
    required this.leadsPorStatus,
    this.onStageTap,
    super.key,
  });

  final Map<String, int> leadsPorStatus;
  final ValueChanged<String>? onStageTap;

  static const _stages = [
    ('novo', 'Novo', Color(0xFF3B82F6)),
    ('emAtendimento', 'Em Atendimento', Color(0xFFF97316)),
    ('qualificado', 'Qualificado', Color(0xFF8B5CF6)),
    ('proposta', 'Proposta', Color(0xFF06B6D4)),
    ('fechado', 'Fechado', Color(0xFF22C55E)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status do Pipeline',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._stages.map((stage) {
            final count = leadsPorStatus[stage.$1] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PipelineRow(
                label: stage.$2,
                count: count,
                color: stage.$3,
                onTap: () => onStageTap?.call(stage.$1),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PipelineRow extends StatelessWidget {
  const _PipelineRow({
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CadifeCard(
      padding: EdgeInsets.zero,
      borderRadius: 12,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: color),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
