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
  int _previousIndex = 0;

  // Derivamos as abas, itens e o índice atual de forma reativa e centralizada
  (List<String>, List<CadifeBottomNavItem>, int) _getNavigationState(bool isAdmin, String path) {
    // Definimos as abas (URLs)
    final tabs = isAdmin 
      ? [
          '/agency/admin/overview',
          '/agency/admin/leads',
          '/agency/admin/consultants',
          '/agency/agenda',
          '/agency/profile',
        ]
      : [
          '/agency/dashboard',
          '/agency/leads',
          '/agency/agenda',
          '/agency/profile',
        ];

    // Definimos os itens da barra (Ícones e Labels)
    final items = isAdmin
      ? [
          const CadifeBottomNavItem(icon: LucideIcons.layoutDashboard, label: 'Dashboard'),
          const CadifeBottomNavItem(icon: LucideIcons.users, label: 'Leads'),
          const CadifeBottomNavItem(icon: LucideIcons.shieldCheck, label: 'Consultores'),
          const CadifeBottomNavItem(icon: LucideIcons.calendarDays, label: 'Agenda'),
          const CadifeBottomNavItem(icon: LucideIcons.circleUser, label: 'Perfil'),
        ]
      : [
          const CadifeBottomNavItem(icon: LucideIcons.layoutDashboard, label: 'Dashboard'),
          const CadifeBottomNavItem(icon: LucideIcons.users, label: 'Leads'),
          const CadifeBottomNavItem(icon: LucideIcons.calendarDays, label: 'Agenda'),
          const CadifeBottomNavItem(icon: LucideIcons.circleUser, label: 'Perfil'),
        ];

    // Calculamos o índice baseado no path e no papel (isAdmin)
    int index = 0;
    if (isAdmin) {
      if (path.startsWith('/agency/admin/overview')) {
        index = 0;
      } else if (path.startsWith('/agency/admin/leads')) {
        index = 1;
      } else if (path.startsWith('/agency/leads')) {
        index = 1;
      } else if (path.startsWith('/agency/admin/consultants')) {
        index = 2;
      } else if (path.startsWith('/agency/agenda')) {
        index = 3;
      } else if (path.startsWith('/agency/profile')) {
        index = 4;
      } else if (path.startsWith('/agency/admin')) {
        index = 0;
      }
    } else {
      if (path.startsWith('/agency/dashboard')) {
        index = 0;
      } else if (path.startsWith('/agency/leads')) {
        index = 1;
      } else if (path.startsWith('/agency/agenda')) {
        index = 2;
      } else if (path.startsWith('/agency/profile')) {
        index = 3;
      }
    }

    return (tabs, items, index);
  }

  @override
  void didUpdateWidget(AgencyShell old) {
    super.didUpdateWidget(old);
    if (old.location != widget.location) {
      // Usamos ref.read aqui apenas para capturar o índice anterior para a animação
      final user = ref.read(authNotifierProvider).valueOrNull;
      final isAdmin = user?.role == UserRole.admin;
      final (_, _, oldIndex) = _getNavigationState(isAdmin, old.location);
      final (_, _, newIndex) = _getNavigationState(isAdmin, widget.location);
      if (oldIndex != newIndex) {
        _previousIndex = oldIndex;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final isAdmin = user?.role == UserRole.admin;
    
    final (tabs, items, currentIndex) = _getNavigationState(isAdmin, widget.location);

    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 280),
        reverse: currentIndex < _previousIndex,
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
        currentIndex: currentIndex,
        onTap: (i) => context.go(tabs[i]),
        items: items,
      ),
    );
  }
}
