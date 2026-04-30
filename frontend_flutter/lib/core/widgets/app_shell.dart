import 'package:cadife_smart_travel/core/widgets/cadife_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onNavTap;

  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavTap,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset(
          'assets/images/cadife_logo_negativo.svg',
          height: 24,
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, size: 20),
            onPressed: () {
              // Notification action
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: CadifeBottomNav(
        currentIndex: widget.currentIndex,
        onTap: widget.onNavTap,
      ),
    );
  }
}
