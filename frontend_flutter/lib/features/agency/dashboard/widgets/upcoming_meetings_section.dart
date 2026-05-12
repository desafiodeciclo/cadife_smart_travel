import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UpcomingMeetingsSection extends StatelessWidget {
  const UpcomingMeetingsSection({required this.agendamentos, super.key});

  final List<Agendamento> agendamentos;

  @override
  Widget build(BuildContext context) {
    final upcoming = agendamentos
        .where(
          (a) =>
              a.dateTime.isAfter(DateTime.now()) && !a.isBloqueado,
        )
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final display = upcoming.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Próximas Reuniões',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (display.isEmpty)
            const _EmptyMeetings()
          else
            ...display.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MeetingRow(agendamento: a),
              ),
            ),
        ],
      ),
    );
  }
}

class _MeetingRow extends StatelessWidget {
  const _MeetingRow({required this.agendamento});

  final Agendamento agendamento;

  @override
  Widget build(BuildContext context) {
    final start = _fmt(agendamento.dateTime);
    final end = _fmt(
      agendamento.dateTime.add(
        Duration(minutes: agendamento.durationMinutes),
      ),
    );

    return GestureDetector(
      onTap: () => context.goNamed(
        'agency_lead_details',
        pathParameters: {'leadId': agendamento.leadId},
      ),
      child: CadifeCard(
        padding: const EdgeInsets.all(12),
        borderRadius: 12,
        child: Row(
          children: [
            // Time column
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    start,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    end,
                    style: AppTextStyles.caption.copyWith(
                      color: context.cadife.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agendamento.nomeCliente ?? 'Cliente',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    agendamento.statusEnum.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.cadife.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: context.cadife.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _EmptyMeetings extends StatelessWidget {
  const _EmptyMeetings();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'Nenhuma reunião agendada',
          style: AppTextStyles.bodySmall
              .copyWith(color: context.cadife.textSecondary),
        ),
      ),
    );
  }
}
