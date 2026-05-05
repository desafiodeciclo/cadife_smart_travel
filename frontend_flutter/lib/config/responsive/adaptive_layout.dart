import 'package:cadife_smart_travel/config/responsive/cadife_navigation_rail.dart';
import 'package:cadife_smart_travel/config/responsive/responsive_breakpoints.dart';
import 'package:flutter/material.dart';

class AdaptiveLayout extends StatelessWidget {
  final Widget Function(BuildContext, DeviceType)? builder;
  final Widget? mobileBuilder;
  final Widget? tabletBuilder;
  final Widget? desktopBuilder;
  
  const AdaptiveLayout({
    this.builder,
    this.mobileBuilder,
    this.tabletBuilder,
    this.desktopBuilder,
    super.key,
  }) : assert(builder != null || (mobileBuilder != null && tabletBuilder != null && desktopBuilder != null));
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveBreakpoints.getDeviceType(
          constraints.maxWidth,
        );
        
        // Use specific builder if provided, fallback to generic
        return switch (deviceType) {
          DeviceType.mobile => mobileBuilder ?? builder!(context, deviceType),
          DeviceType.tablet => tabletBuilder ?? builder!(context, deviceType),
          DeviceType.desktop => desktopBuilder ?? builder!(context, deviceType),
        };
      },
    );
  }
}

// Convenience widget para layouts adaptivos simples
class AdaptiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget Function(BuildContext, DeviceType) body;
  final Widget Function(BuildContext)? floatingActionButton;
  final int selectedIndex;
  final ValueChanged<int>? onNavigationChanged;
  final List<NavigationDestination> navigationDestinations;
  
  const AdaptiveScaffold({
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.selectedIndex = 0,
    this.onNavigationChanged,
    required this.navigationDestinations,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveBreakpoints.getDeviceType(
          constraints.maxWidth,
        );
        final isMobile = deviceType == DeviceType.mobile;
        
        return Scaffold(
          appBar: appBar,
          
          // Mobile: BottomNavigationBar (or custom) | Tablet/Desktop: NavigationRail
          body: Row(
            children: [
              if (!isMobile)
                CadifeNavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onNavigationChanged ?? (_) {},
                  destinations: navigationDestinations
                    .map((dest) => NavigationRailDestination(
                      icon: dest.icon,
                      selectedIcon: dest.selectedIcon,
                      label: Text(dest.label),
                    ))
                    .toList(),
                ),
              Expanded(child: body(context, deviceType)),
            ],
          ),
          
          bottomNavigationBar: isMobile
            ? NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: onNavigationChanged,
                destinations: navigationDestinations,
              )
            : null,
          
          floatingActionButton: floatingActionButton?.call(context),
        );
      },
    );
  }
}
