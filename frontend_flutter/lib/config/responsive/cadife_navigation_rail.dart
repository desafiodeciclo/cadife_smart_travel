import 'package:cadife_smart_travel:config/responsive/responsive_breakpoints.dart';
import 'package:flutter/material.dart';

class CadifeNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationRailDestination> destinations;
  final bool extended;
  
  const CadifeNavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.extended = false,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
      extended: extended,
      labelType: extended
        ? NavigationRailLabelType.none
        : NavigationRailLabelType.all, // Sempre mostrar labels se não estendido
      backgroundColor: context.colorScheme.surface,
      elevation: 1,
      
      // Header customizado (ex: logo Cadife)
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Icon(
          Icons.public,
          color: context.colorScheme.primary,
          size: 32,
        ),
      ),
      
      // Trailing customizado (ex: perfil do consultor)
      trailing: Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: context.colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                color: context.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
