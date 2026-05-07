import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/client_travel_status.dart';
import 'package:flutter/material.dart';

/// Horizontal 4-step timeline showing the AYA briefing collection progress:
/// Briefing Coletado → Em Curadoria → Proposta Enviada → Confirmado
class BriefingStatusTimeline extends StatelessWidget {
  const BriefingStatusTimeline({required this.status, super.key});

  final TravelStatus status;

  static const _steps = [
    _TimelineStep(
      label: 'Briefing\nColetado',
      icon: LucideIcons.clipboardCheck,
    ),
    _TimelineStep(
      label: 'Em\nCuradoria',
      icon: LucideIcons.search,
    ),
    _TimelineStep(
      label: 'Proposta\nEnviada',
      icon: LucideIcons.sendHorizontal,
    ),
    _TimelineStep(
      label: 'Confirmado',
      icon: LucideIcons.check,
    ),
  ];

  int get _currentIndex => switch (status) {
        TravelStatus.emAtendimento => 0,
        TravelStatus.qualificado   => 1,
        TravelStatus.agendado      => 1,
        TravelStatus.proposta      => 2,
        TravelStatus.confirmado    => 3,
      };

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final current = _currentIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        const circleSize = 32.0;
        final stepWidth = constraints.maxWidth / _steps.length;

        return SizedBox(
          height: 76,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Connector lines at vertical centre of circles
              Positioned(
                top: circleSize / 2 - 1,
                left: stepWidth / 2,
                right: stepWidth / 2,
                child: Row(
                  children: List.generate(
                    _steps.length - 1,
                    (i) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 2,
                        color: i < current
                            ? cadife.primary
                            : cadife.cardBorder,
                      ),
                    ),
                  ),
                ),
              ),
              // Step circles + labels
              Row(
                children: List.generate(
                  _steps.length,
                  (i) => SizedBox(
                    width: stepWidth,
                    child: Column(
                      children: [
                        _StepCircle(
                          icon: _steps[i].icon,
                          isCompleted: i < current,
                          isCurrent: i == current,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _steps[i].label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 9,
                            height: 1.3,
                            fontWeight: i <= current
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: i <= current
                                ? cadife.textPrimary
                                : cadife.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineStep {
  const _TimelineStep({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.icon,
    required this.isCompleted,
    required this.isCurrent,
  });

  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    if (isCompleted) {
      return _Circle(
        color: cadife.success,
        child: const Icon(LucideIcons.check, color: Colors.white, size: 15),
      );
    }
    if (isCurrent) {
      return _Circle(
        color: cadife.primary,
        child: Icon(icon, color: Colors.white, size: 15),
      );
    }
    return _Circle(
      color: Colors.transparent,
      border: Border.all(
        color: cadife.textSecondary.withValues(alpha: 0.3),
        width: 1.5,
      ),
      child: Icon(icon, color: cadife.textSecondary.withValues(alpha: 0.4), size: 14),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.color, this.child, this.border});

  final Color color;
  final Widget? child;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
