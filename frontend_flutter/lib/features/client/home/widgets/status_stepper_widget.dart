import 'package:cadife_smart_travel/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Horizontal trip-status stepper.
/// [currentStep]: 0 = Em análise, 1 = Proposta enviada, 2 = Confirmado, 3 = Emitido
class StatusStepperWidget extends StatelessWidget {
  const StatusStepperWidget({super.key, required this.currentStep});

  final int currentStep;

  static const _labels = [
    'Em análise',
    'Proposta\nenviada',
    'Confirmado',
    'Emitido',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUS DA VIAGEM',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const circleSize = 28.0;
              final stepWidth = constraints.maxWidth / 4;

              return SizedBox(
                height: 68,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Connector lines sit at vertical center of circles
                    Positioned(
                      top: circleSize / 2 - 1,
                      left: stepWidth / 2,
                      right: stepWidth / 2,
                      child: Row(
                        children: List.generate(
                          3,
                          (i) => Expanded(
                            child: Container(
                              height: 2,
                              color: i < currentStep
                                  ? AppColors.primary
                                  : AppColors.textSecondary.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Step circles + labels, each occupying equal width
                    Row(
                      children: List.generate(
                        4,
                        (i) => SizedBox(
                          width: stepWidth,
                          child: Column(
                            children: [
                              _StepCircle(
                                isCompleted: i < currentStep,
                                isCurrent: i == currentStep,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _labels[i],
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 9,
                                  height: 1.3,
                                  fontWeight: i == currentStep
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: i <= currentStep
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
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
          ),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.isCompleted, required this.isCurrent});

  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return const _Circle(
        color: AppColors.primary,
        child: Icon(Icons.check, color: Colors.white, size: 15),
      );
    }
    if (isCurrent) {
      return const _Circle(
        color: AppColors.primary,
        child: Icon(Icons.flight, color: Colors.white, size: 15),
      );
    }
    return _Circle(
      color: Colors.transparent,
      border: Border.all(
        color: AppColors.textSecondary.withValues(alpha: 0.35),
        width: 2,
      ),
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
    return Container(
      width: 28,
      height: 28,
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
