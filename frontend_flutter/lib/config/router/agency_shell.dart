import 'package:animations/animations.dart';
import 'package:cadife_smart_travel/config/responsive/adaptive_layout.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AgencyShell extends StatefulWidget {
  const AgencyShell({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  @override
  State<AgencyShell> createState() => _AgencyShellState();
}

class _AgencyShellState extends State<AgencyShell> {
  static const _tabs = ['/agency/dashboard', '/agency/leads', '/agency/agenda', '/agency/profile'];

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
  void didUpdateWidget(AgencyShell old) {
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
        NavigationDestination(icon: Icon(LucideIcons.layoutDashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(LucideIcons.users), label: 'Leads'),
        NavigationDestination(icon: Icon(LucideIcons.calendarDays), label: 'Agenda'),
        NavigationDestination(icon: Icon(LucideIcons.circleUser), label: 'Perfil'),
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
