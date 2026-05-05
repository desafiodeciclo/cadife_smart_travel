import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

class CadifeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? color;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool showBorder;

  const CadifeCard({
    required this.child,
    super.key,
    this.padding,
    this.width,
    this.height,
    this.color,
    this.onTap,
    this.borderRadius = 24,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.cadife;
    final isDark = context.isDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color ?? theme.cardBackground,
          borderRadius: BorderRadius.circular(borderRadius),
          border: showBorder 
            ? Border.all(
                color: theme.cardBorder,
                width: 1.5,
              )
            : null,
          boxShadow: [
            if (!isDark)
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
