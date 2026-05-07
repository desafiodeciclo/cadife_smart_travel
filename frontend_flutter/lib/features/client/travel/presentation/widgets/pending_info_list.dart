import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Shows a list of fields that the AYA still needs to collect.
///
/// Renders an empty-state message when [pendingFields] is empty.
class PendingInfoList extends StatelessWidget {
  const PendingInfoList({required this.pendingFields, super.key});

  final List<String> pendingFields;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    if (pendingFields.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(LucideIcons.circleCheck, size: 16, color: cadife.success),
            const SizedBox(width: 8),
            Text(
              'Todas as informações foram coletadas.',
              style: TextStyle(
                fontSize: 13,
                color: cadife.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'A AYA ainda precisa dessas informações:',
            style: TextStyle(
              fontSize: 12,
              color: cadife.textSecondary,
            ),
          ),
        ),
        ...pendingFields.map((field) => _PendingItem(label: field)),
      ],
    );
  }
}

class _PendingItem extends StatelessWidget {
  const _PendingItem({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.circleAlert,
              size: 12,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: cadife.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
