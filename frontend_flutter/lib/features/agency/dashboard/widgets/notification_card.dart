import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.leadName,
    required this.timeAgo,
    required this.onClose,
    this.onTap,
  });

  final String leadName;
  final String timeAgo;
  final VoidCallback onClose;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ShadCard(
        padding: const EdgeInsets.all(12),
        backgroundColor: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
        radius: BorderRadius.circular(8),
        border: ShadBorder.all(color: AppColors.primary, width: 1.5),
        child: Row(
          children: [
            const Icon(Icons.person_add, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Novo lead recebido',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$leadName • $timeAgo',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.cadife.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 20, color: context.cadife.textSecondary),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
