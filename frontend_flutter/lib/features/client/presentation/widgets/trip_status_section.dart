// lib/features/client/presentation/widgets/trip_status_section.dart

import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/home/domain/entities/client_trip.dart';
import 'package:flutter/material.dart';

class TripStatusSection extends StatelessWidget {
  final ClientTrip trip;

  const TripStatusSection({required this.trip, super.key});

  String get _statusLabel => switch (trip.status) {
        'planejando' => 'Planejando',
        'confirmado' => 'Confirmado',
        'em_andamento' => 'Em Andamento',
        'concluido' => 'Concluído',
        _ => trip.status,
      };

  Color get _statusColor => switch (trip.status) {
        'planejando' => Colors.blue,
        'confirmado' => AppColors.success,
        'em_andamento' => AppColors.warning,
        'concluido' => Colors.purple,
        _ => AppColors.zinc500,
      };

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho com badge de status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STATUS DA VIAGEM',
              style: TextStyle(
                color: cadife.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor),
              ),
              child: Text(
                _statusLabel,
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Componente Unificado: Progresso e Checklist
        CadifeGlassCard(
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção de Progresso
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progresso Geral',
                    style: TextStyle(
                      color: cadife.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(trip.progressPercentage * 100).toInt()}%',
                    style: TextStyle(
                      color: cadife.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: trip.progressPercentage,
                  minHeight: 8,
                  backgroundColor: cadife.muted,
                  valueColor: AlwaysStoppedAnimation<Color>(cadife.primary),
                ),
              ),
              const SizedBox(height: 20),
              
              // Divisor sutil
              Divider(
                color: cadife.cardBorder.withValues(alpha: 0.1),
                height: 1,
              ),
              const SizedBox(height: 20),

              // Checklist/Timeline
              TripProgressTimeline(trip: trip),
            ],
          ),
        ),
      ],
    );
  }
}

class TripProgressTimeline extends StatelessWidget {
  final ClientTrip trip;

  const TripProgressTimeline({required this.trip, super.key});

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final checkpoints = trip.checkpoints;

    return Column(
      children: List.generate(checkpoints.length, (index) {
        final cp = checkpoints[index];
        final isLast = index == checkpoints.length - 1;

        return Column(
          children: [
            Row(
              children: [
                // Bullet indicador
                Container(
                  width: 24,
                  height: 24,
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
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : cp.isCurrent
                            ? Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cadife.primary,
                                ),
                              )
                            : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Nome do checkpoint
                Expanded(
                  child: Text(
                    cp.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          cp.isCurrent ? FontWeight.w600 : FontWeight.normal,
                      color: cp.completed || cp.isCurrent
                          ? cadife.textPrimary
                          : cadife.textSecondary,
                    ),
                  ),
                ),

                // Ícone de concluído
                if (cp.completed)
                  Icon(Icons.check_circle, size: 16, color: cadife.success),
              ],
            ),
            // Linha conectora (exceto após o último item)
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 11, top: 2, bottom: 2),
                child: Container(
                  width: 2,
                  height: 14,
                  color: cadife.cardBorder,
                ),
              ),
          ],
        );
      }),
    );
  }
}
