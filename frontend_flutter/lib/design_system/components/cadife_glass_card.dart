import 'package:cadife_smart_travel/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';

class CadifeGlassCard extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Border? border;
  final double? width;
  final double? height;

  // Kept for API compatibility — no longer applied
  final double blur;
  final double opacity;

  const CadifeGlassCard({
    required this.child,
    super.key,
    this.blur = 10,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
    this.border,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(24);
    final surface = isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground;
    final borderCol = isDark ? AppColors.borderColorDark : AppColors.borderColor;

    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: effectiveRadius,
        border: border ?? Border.all(color: borderCol, width: 1),
      ),
      child: child,
    );
  }
}
