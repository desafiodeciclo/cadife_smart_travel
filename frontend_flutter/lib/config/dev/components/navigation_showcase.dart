import 'package:cadife_smart_travel/config/dev/component_library_models.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

final navigationShowcases = [
  ComponentShowcaseData(
    name: 'CadifeAppBar',
    description: 'Custom AppBar for Cadife.',
    category: ComponentCategory.navigation,
    builder: (context) => const SizedBox(
      height: 100,
      child: CadifeAppBar(
        title: 'Título da Página',
        showBackButton: true,
      ),
    ),
    codeSnippet: '''CadifeAppBar(
  title: 'Título da Página',
  showBackButton: true,
)''',
  ),

  ComponentShowcaseData(
    name: 'CadifeBottomNav',
    description: 'Custom Bottom Navigation Bar.',
    category: ComponentCategory.navigation,
    // Rendered directly (no wrapping Scaffold) to avoid layout assertion
    // errors when constrained to a small height in the showcase container.
    builder: (context) => CadifeBottomNav(
      currentIndex: 0,
      onTap: (_) {},
      items: const [
        CadifeBottomNavItem(icon: Icons.home, label: 'Home'),
        CadifeBottomNavItem(icon: Icons.search, label: 'Search'),
        CadifeBottomNavItem(icon: Icons.person, label: 'Profile'),
      ],
    ),
    codeSnippet: '''CadifeBottomNav(
  currentIndex: 0,
  onTap: (index) {},
  items: [...],
)''',
  ),
];
