import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onNavTap;

  const AppShell({
    required this.child,
    required this.currentIndex,
    required this.onNavTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CadifeAppBar(
        title: 'Smart Travel',
        showProfile: true,
      ),
      body: child,
      bottomNavigationBar: CadifeBottomNav(
        currentIndex: currentIndex,
        onTap: onNavTap,
        items: const [
          CadifeBottomNavItem(icon: LucideIcons.house, label: 'Início'),
          CadifeBottomNavItem(icon: LucideIcons.map, label: 'Viagens'),
          CadifeBottomNavItem(icon: LucideIcons.fileText, label: 'Docs'),
          CadifeBottomNavItem(icon: LucideIcons.user, label: 'Perfil'),
        ],
      ),
    );
  }
}
