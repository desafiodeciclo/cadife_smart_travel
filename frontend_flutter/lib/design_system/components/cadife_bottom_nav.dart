import 'dart:ui';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CadifeBottomNavItem {
  final IconData icon;
  final String label;

  const CadifeBottomNavItem({
    required this.icon,
    required this.label,
  });
}

class CadifeBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<CadifeBottomNavItem> items;
  final Function(int) onTap;

  const CadifeBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.cadife;
    final backgroundColor = theme.background;
    final blurColor = theme.background.withValues(alpha: 0.8);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.divider,
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: blurColor,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 8,
              top: 12,
              left: 16,
              right: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                return _NavItem(
                  icon: item.icon,
                  label: item.label,
                  isActive: currentIndex == index,
                  onTap: () => onTap(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.cadife;
    final activeColor = theme.primary;
    final inactiveColor = theme.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isActive 
                  ? theme.primary.withValues(alpha: 0.1) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? activeColor : inactiveColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
