import 'package:flutter/material.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'empty_type.dart';

class AppEmptyState extends StatelessWidget {
  final EmptyType type;
  final String? customTitle;
  final String? customSubtitle;
  final VoidCallback? onAction;
  final String? customActionLabel;
  
  const AppEmptyState({
    required this.type,
    this.customTitle,
    this.customSubtitle,
    this.onAction,
    this.customActionLabel,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    final actionLabel = customActionLabel ?? type.actionButtonLabel;
    final showAction = actionLabel != null && onAction != null;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone
            Icon(
              type.icon,
              size: 80,
              color: context.cadife.textSecondary,
            ),
            const SizedBox(height: 24),
            
            // Título
            Text(
              customTitle ?? type.title,
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Subtítulo
            Text(
              customSubtitle ?? type.subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.cadife.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (showAction) ...[
              const SizedBox(height: 32),
              CadifeButton(
                label: actionLabel,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
