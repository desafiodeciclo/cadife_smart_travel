import 'package:animations/animations.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AgencyShell extends ConsumerStatefulWidget {
  const AgencyShell({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  @override
  ConsumerState<AgencyShell> createState() => _AgencyShellState();
}

class _AgencyShellState extends ConsumerState<AgencyShell> {
  static const _baseTabs = [
    '/agency/dashboard',
    '/agency/leads',
    '/agency/agenda',
    '/agency/profile',
  ];

  static const _adminTabs = [
    '/agency/admin/overview',
    '/agency/admin/leads',
    '/agency/agenda',
    '/agency/admin/consultants',
    '/agency/profile',
  ];

  int _currentIndex = 0;
  int _previousIndex = 0;
  List<String> _tabs = _baseTabs;

  List<String> _getTabsList(bool isAdmin) {
    return isAdmin ? _adminTabs : _baseTabs;
  }

  int _indexFromPath(String path, bool isAdmin) {
    final tabs = _getTabsList(isAdmin);
    for (int i = 0; i < tabs.length; i++) {
      if (path.startsWith(tabs[i])) return i;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).valueOrNull;
    final isAdmin = user?.role == UserRole.admin;
    _currentIndex = _indexFromPath(widget.location, isAdmin);
    _previousIndex = _currentIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.read(authNotifierProvider).valueOrNull;
    final newTabs = user?.role == UserRole.admin ? _adminTabs : _baseTabs;
    if (newTabs.length != _tabs.length) {
      setState(() {
        _tabs = newTabs;
        _currentIndex = _indexFromPath(widget.location, user?.role == UserRole.admin);
      });
    }
  }

  @override
  void didUpdateWidget(AgencyShell old) {
    super.didUpdateWidget(old);
    final user = ref.read(authNotifierProvider).valueOrNull;
    final isAdmin = user?.role == UserRole.admin;
    final newIndex = _indexFromPath(widget.location, isAdmin);
    if (newIndex != _currentIndex) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = newIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final isAdmin = user?.role == UserRole.admin;
    /* Unused local variables tabs and items removed */

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
        items: [
          const CadifeBottomNavItem(icon: LucideIcons.layoutDashboard, label: 'Dashboard'),
          const CadifeBottomNavItem(icon: LucideIcons.users, label: 'Leads'),
          const CadifeBottomNavItem(icon: LucideIcons.calendarDays, label: 'Agenda'),
          if (isAdmin)
            const CadifeBottomNavItem(icon: LucideIcons.shieldCheck, label: 'Gestão'),
          const CadifeBottomNavItem(icon: LucideIcons.circleUser, label: 'Perfil'),
        ],
      ),
    );
  }
}
