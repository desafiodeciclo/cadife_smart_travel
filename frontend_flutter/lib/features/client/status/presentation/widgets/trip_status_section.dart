import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/home_page_data.dart';
import 'package:flutter/material.dart';

class TripStatusSection extends StatelessWidget {
  const TripStatusSection({required this.data, super.key});

  final ClientHomeData data;

  String _statusLabel(String s) => switch (s) {
        'planejando' => 'Planejando',
        'confirmado' => 'Confirmado',
        'em_andamento' => 'Em Andamento',
        'concluido' => 'Concluído',
        _ => s,
      };

  Color _statusColor(String s) => switch (s) {
        'planejando' => AppColors.info,
        'confirmado' => AppColors.success,
        'em_andamento' => AppColors.warning,
        'concluido' => AppColors.primary,
        _ => AppColors.zinc500,
      };

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final statusColor = _statusColor(data.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Status da Viagem',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cadife.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                _statusLabel(data.status),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CadifeGlassCard(
          blur: 20,
          opacity: 0.07,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progresso',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cadife.textPrimary,
                    ),
                  ),
                  Text(
                    '${(data.progressPercentage * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cadife.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: data.progressPercentage,
                  minHeight: 8,
                  backgroundColor: cadife.muted,
                  valueColor: AlwaysStoppedAnimation<Color>(cadife.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CadifeGlassCard(
          blur: 20,
          opacity: 0.07,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: _VerticalTimeline(checkpoints: data.checkpoints),
        ),
      ],
    );
  }
}

class _VerticalTimeline extends StatelessWidget {
  const _VerticalTimeline({required this.checkpoints});

  final List<TripCheckpoint> checkpoints;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Column(
      children: List.generate(checkpoints.length, (index) {
        final cp = checkpoints[index];
        final isLast = index == checkpoints.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cp.completed
                            ? cadife.primary
                            : cp.isCurrent
                                ? cadife.primary.withValues(alpha: 0.25)
                                : cadife.muted,
                        border: Border.all(
                          color: cp.completed || cp.isCurrent
                              ? cadife.primary
                              : cadife.cardBorder,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: cp.completed
                            ? const Icon(Icons.check, size: 11, color: AppColors.white)
                            : cp.isCurrent
                                ? Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: cadife.primary,
                                    ),
                                  )
                                : null,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          color: cp.completed
                              ? cadife.primary.withValues(alpha: 0.35)
                              : cadife.cardBorder,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                  child: Text(
                    cp.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: cp.isCurrent ? FontWeight.w600 : FontWeight.w400,
                      color: cp.completed || cp.isCurrent
                          ? cadife.textPrimary
                          : cadife.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
