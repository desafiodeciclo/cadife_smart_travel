import 'package:cadife_smart_travel/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ciclo de vida: NOVO → EM_ATENDIMENTO → QUALIFICADO → AGENDADO → PROPOSTA → FECHADO
enum LeadStatusStep { novo, emAtendimento, qualificado, agendado, proposta, fechado, perdido }

class LeadStatusStepper extends StatelessWidget {
  final LeadStatusStep currentStatus;

  const LeadStatusStepper({required this.currentStatus, super.key});

  static const _steps = [
    LeadStatusStep.novo,
    LeadStatusStep.emAtendimento,
    LeadStatusStep.qualificado,
    LeadStatusStep.agendado,
    LeadStatusStep.proposta,
    LeadStatusStep.fechado,
  ];

  static const _labels = {
    LeadStatusStep.novo:          'Novo',
    LeadStatusStep.emAtendimento: 'Atendimento',
    LeadStatusStep.qualificado:   'Qualificado',
    LeadStatusStep.agendado:      'Agendado',
    LeadStatusStep.proposta:      'Proposta',
    LeadStatusStep.fechado:       'Fechado',
    LeadStatusStep.perdido:       'Perdido',
  };

  @override
  Widget build(BuildContext context) {
    if (currentStatus == LeadStatusStep.perdido) {
      return _PerdidoBadge();
    }

    final currentIndex = _steps.indexOf(currentStatus);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            final isDone = stepIndex < currentIndex;
            return Container(
              width: 24,
              height: 2,
              color: isDone ? AppColors.primary : Colors.grey.shade300,
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < currentIndex;
          final isCurrent = stepIndex == currentIndex;
          return _StepDot(
            label: _labels[_steps[stepIndex]]!,
            isDone: isDone,
            isCurrent: isCurrent,
          );
        }),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isCurrent;

  const _StepDot({
    required this.label,
    required this.isDone,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone || isCurrent ? AppColors.primary : Colors.grey.shade400;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isCurrent ? 16 : 12,
          height: isCurrent ? 16 : 12,
          decoration: BoxDecoration(
            color: isDone ? AppColors.primary : (isCurrent ? Colors.white : Colors.grey.shade300),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isCurrent ? 2 : 0),
          ),
          child: isDone
              ? const Icon(Icons.check, size: 8, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PerdidoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cancel_outlined, size: 14, color: Colors.red.shade600),
          const SizedBox(width: 6),
          Text(
            'Perdido',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
