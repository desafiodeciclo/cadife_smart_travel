import 'package:animations/animations.dart';
import 'package:cadife_smart_travel/config/responsive/adaptive_layout.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  static const _tabs = [
    '/client/status',
    '/client/interactions',
    '/client/documents',
    '/client/profile',
  ];

  int _currentIndex = 0;
  int _previousIndex = 0;

  int _indexFromPath(String path) {
    for (int i = 0; i < _tabs.length; i++) {
      if (path.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = _indexFromPath(widget.location);
    _previousIndex = _currentIndex;
  }

  @override
  void didUpdateWidget(ClientShell old) {
    super.didUpdateWidget(old);
    final newIndex = _indexFromPath(widget.location);
    if (newIndex != _currentIndex) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = newIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: _currentIndex,
      onNavigationChanged: (i) => context.go(_tabs[i]),
      navigationDestinations: const [
        NavigationDestination(icon: Icon(LucideIcons.house), label: 'Início'),
        NavigationDestination(icon: Icon(LucideIcons.history), label: 'Histórico'),
        NavigationDestination(icon: Icon(LucideIcons.fileText), label: 'Docs'),
        NavigationDestination(icon: Icon(LucideIcons.user), label: 'Perfil'),
      ],
      body: (context, deviceType) => PageTransitionSwitcher(
        duration: const Duration(milliseconds: 280),
        reverse: _currentIndex < _previousIndex,
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) =>
            SharedAxisTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              fillColor: Colors.transparent,
              child: child,
            ),
        child: widget.child,
      ),
    );
  }
}
