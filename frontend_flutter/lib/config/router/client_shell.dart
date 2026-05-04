import 'package:animations/animations.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  static const _tabs = [
    '/client/status',
    '/client/historico',
    '/client/documentos',
    '/client/perfil',
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
    return Scaffold(
      body: PageTransitionSwitcher(
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
      bottomNavigationBar: CadifeBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => context.go(_tabs[i]),
        items: const [
          CadifeBottomNavItem(icon: LucideIcons.house, label: 'Início'),
          CadifeBottomNavItem(icon: LucideIcons.history, label: 'Histórico'),
          CadifeBottomNavItem(icon: LucideIcons.fileText, label: 'Docs'),
          CadifeBottomNavItem(icon: LucideIcons.user, label: 'Perfil'),
        ],
      ),
    );
  }
}
