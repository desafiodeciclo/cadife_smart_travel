import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cadife_smart_travel/config/dev/component_library_models.dart';
import 'package:cadife_smart_travel/config/dev/components/all_showcases.dart';
import 'package:cadife_smart_travel/config/dev/widgets/component_showcase.dart';
import 'package:cadife_smart_travel/design_system/theme/theme_provider.dart';

class ComponentLibraryPage extends ConsumerStatefulWidget {
  const ComponentLibraryPage({super.key});
  
  @override
  ConsumerState<ComponentLibraryPage> createState() =>
      _ComponentLibraryPageState();
}

class _ComponentLibraryPageState extends ConsumerState<ComponentLibraryPage> {
  late ComponentCategory selectedCategory;
  late String selectedComponent;
  
  final List<ComponentShowcaseData> _allShowcases = [
    ...buttonShowcases,
    ...inputShowcases,
    ...cardShowcases,
    ...feedbackShowcases,
    ...navigationShowcases,
    ...typographyShowcases,
    colorsShowcase,
  ];
  
  @override
  void initState() {
    super.initState();
    selectedCategory = ComponentCategory.buttons;
    final components = _getComponentsForCategory(selectedCategory);
    selectedComponent = components.isNotEmpty ? components.first.name : '';
  }
  
  List<ComponentShowcaseData> _getComponentsForCategory(
    ComponentCategory category,
  ) {
    return _allShowcases.where((c) => c.category == category).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final components = _getComponentsForCategory(selectedCategory);
    final selected = components.firstWhere(
      (c) => c.name == selectedComponent,
      orElse: () => components.isNotEmpty 
          ? components.first 
          : ComponentShowcaseData(
              name: 'None',
              description: 'No components in this category yet',
              category: selectedCategory,
              builder: (context) => const Center(child: Text('Coming soon')),
              codeSnippet: '// WIP',
            ),
    );
    
    final themeMode = ref.watch(themeModeProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Component Library'),
        actions: [
          // Dark mode toggle
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle();
            },
            tooltip: 'Toggle dark mode',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: ComponentCategory.values.indexOf(selectedCategory),
            onDestinationSelected: (index) {
              setState(() {
                selectedCategory = ComponentCategory.values[index];
                final categoryComponents = _getComponentsForCategory(selectedCategory);
                selectedComponent = categoryComponents.isNotEmpty 
                    ? categoryComponents.first.name 
                    : '';
              });
            },
            destinations: ComponentCategory.values
              .map((cat) => NavigationRailDestination(
                icon: Icon(cat.icon),
                label: Text(cat.displayName),
              ))
              .toList(),
            labelType: NavigationRailLabelType.all,
            extended: MediaQuery.of(context).size.width > 1200,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          
          // Content area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Component selector
                if (components.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: components
                        .map((comp) => FilterChip(
                          label: Text(comp.name),
                          selected: comp.name == selected.name,
                          onSelected: (isSelected) {
                            setState(() {
                              selectedComponent = comp.name;
                            });
                          },
                        ))
                        .toList(),
                    ),
                  ),
                if (components.isNotEmpty) const Divider(),
                
                // Component showcase
                Expanded(
                  child: ComponentShowcase(component: selected),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
