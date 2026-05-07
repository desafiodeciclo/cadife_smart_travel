import 'package:cadife_smart_travel/core/analytics/analytics_service.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

enum ButtonVariant {
  primary,
  secondary,
  ghost,
  destructive,
}

class CadifeButton extends StatelessWidget {
  final String? text;
  final String? label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutline;
  final ButtonVariant variant;
  final IconData? icon;
  final String? analyticsLabel;

  const CadifeButton({
    super.key,
    this.text,
    this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutline = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.analyticsLabel,
  });

  String get _displayText => label ?? text ?? '';

  void _handlePress() {
    if (onPressed != null) {
      sl<AnalyticsService>().logEvent('button_clicked', parameters: {
        'button_text': _displayText,
        'button_label': analyticsLabel ?? _displayText,
        'variant': variant.name,
        'is_outline': isOutline,
      });
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.cadife;
    
    final child = Text(_displayText);
    final leading = isLoading 
        ? SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: (variant == ButtonVariant.secondary || variant == ButtonVariant.ghost || isOutline) 
                  ? theme.primary 
                  : Colors.white,
            ),
          )
        : (icon != null ? Icon(icon, size: 18) : null);

    final buttonOnPressed = onPressed != null ? _handlePress : null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: switch (variant) {
        ButtonVariant.primary => isOutline 
            ? ShadButton.outline(
                onPressed: buttonOnPressed,
                leading: leading,
                child: child,
              )
            : ShadButton(
                onPressed: buttonOnPressed,
                leading: leading,
                backgroundColor: theme.primary,
                child: child,
              ),
        ButtonVariant.secondary => ShadButton.secondary(
            onPressed: buttonOnPressed,
            leading: leading,
            child: child,
          ),
        ButtonVariant.ghost => ShadButton.ghost(
            onPressed: buttonOnPressed,
            leading: leading,
            child: child,
          ),
        ButtonVariant.destructive => ShadButton.destructive(
            onPressed: buttonOnPressed,
            leading: leading,
            child: child,
          ),
      },
    );
  }
}
