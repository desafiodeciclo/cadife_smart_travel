import 'package:cadife_smart_travel/core/analytics/analytics_service.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

class CadifeButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutline;
  final IconData? icon;
  final String? analyticsLabel;

  const CadifeButton({
    required this.text,
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.isOutline = false,
    this.icon,
    this.analyticsLabel,
  });

  void _handlePress() {
    if (onPressed != null) {
      sl<AnalyticsService>().logEvent('button_clicked', parameters: {
        'button_text': text,
        'button_label': analyticsLabel ?? text,
        'is_outline': isOutline,
      });
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.cadife;
    
    final child = Text(text);
    final leading = isLoading 
        ? SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isOutline ? theme.primary : Colors.white,
            ),
          )
        : (icon != null ? Icon(icon, size: 18) : null);

    if (isOutline) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ShadButton.outline(
          onPressed: onPressed != null ? _handlePress : null,
          leading: leading,
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ShadButton(
        onPressed: onPressed != null ? _handlePress : null,
        leading: leading,
        backgroundColor: theme.primary,
        child: child,
      ),
    );
  }
}


