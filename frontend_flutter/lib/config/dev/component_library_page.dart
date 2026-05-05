import 'package:cadife_smart_travel/config/dev/component_library_models.dart';
import 'package:cadife_smart_travel/config/dev/components/all_showcases.dart';
import 'package:cadife_smart_travel/config/dev/widgets/component_showcase.dart';
import 'package:cadife_smart_travel/design_system/theme/theme_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      orElse: () =>
          components.isNotEmpty
              ? components.first
              : ComponentShowcaseData(
                name: 'None',
                description: 'No components in this category yet',
                category: selectedCategory,
                builder: (context) =>
                    const Center(child: Text('Coming soon')),
                codeSnippet: '// WIP',
              ),
    );

    final themeMode = ref.watch(themeModeProvider);
    final isWide = MediaQuery.sizeOf(context).width > 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Component Library'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            tooltip: 'Toggle dark mode',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Sidebar ──────────────────────────────────────────────
          Container(
            width: isWide ? 250 : 72,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: ListView(
              children: [
                const SizedBox(height: 16),
                ...ComponentCategory.values.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return ListTile(
                    leading: Icon(
                      cat.icon,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: isWide
                        ? Text(
                          cat.displayName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : null,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        )
                        : null,
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        selectedCategory = cat;
                        final next = _getComponentsForCategory(cat);
                        selectedComponent =
                            next.isNotEmpty ? next.first.name : '';
                      });
                    },
                  );
                }),
              ],
            ),
          ),

          // ── Main Content ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Variant chip selector
                if (components.isNotEmpty)
                  Material(
                    elevation: 1,
                    child: SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: components.length,
                        itemBuilder: (context, index) {
                          final comp = components[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Center(
                              child: FilterChip(
                                label: Text(comp.name),
                                selected: comp.name == selected.name,
                                onSelected: (_) => setState(
                                  () => selectedComponent = comp.name,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Showcase area
                Expanded(
                  child: ComponentShowcase(
                    key: ValueKey(
                      '${selectedCategory.name}_${selected.name}',
                    ),
                    component: selected,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
