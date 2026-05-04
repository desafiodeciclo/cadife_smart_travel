import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

class StatusStepperItem extends StatelessWidget {
  final String label;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;

  const StatusStepperItem({
    super.key,
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? AppColors.success
        : isCurrent
            ? AppColors.primary
            : AppColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color,
              child: Icon(
                isCompleted
                    ? Icons.check
                    : (isCurrent ? Icons.circle : Icons.radio_button_unchecked),
                size: 16,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isCompleted ? AppColors.success : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
