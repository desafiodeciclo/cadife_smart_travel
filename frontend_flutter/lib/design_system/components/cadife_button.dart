import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class CadifeButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutline;
  final IconData? icon;

  const CadifeButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutline = false,
    this.icon,
  });

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
          onPressed: onPressed,
          leading: leading,
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ShadButton(
        onPressed: onPressed,
        leading: leading,
        backgroundColor: theme.primary,
        child: child,
      ),
    );
  }
}


