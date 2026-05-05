import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

enum CardVariant {
  standard,
  elevated,
  outlined,
}

class CadifeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? color;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool showBorder;
  final CardVariant variant;

  const CadifeCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.color,
    this.onTap,
    this.borderRadius = 24,
    this.showBorder = true,
    this.variant = CardVariant.standard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.cadife;
    final isDark = context.isDark;

    final bool effectiveShowBorder = variant == CardVariant.outlined || (variant == CardVariant.standard && showBorder);
    final bool effectiveShowShadow = variant == CardVariant.elevated || (variant == CardVariant.standard && !isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ?? theme.cardBackground,
          borderRadius: BorderRadius.circular(borderRadius),
          border: effectiveShowBorder 
            ? Border.all(
                color: theme.cardBorder,
                width: 1.5,
              )
            : null,
          boxShadow: [
            if (effectiveShowShadow)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: child,
      ),
    );
  }
}
