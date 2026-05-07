import 'package:cadife_smart_travel/config/dev/component_library_models.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

final colorsShowcase = ComponentShowcaseData(
  name: 'Paleta de Cores — CDS v3.0',
  description: 'Cores base e tokens do Design System.',
  category: ComponentCategory.colors,
  builder: (context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = context.cadife;
    
    return SingleChildScrollView(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _ColorSwatch(
            name: 'Primary (Red Cadife)',
            color: theme.primary,
            hex: '#${theme.primary.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
          ),
          _ColorSwatch(
            name: 'Surface',
            color: colorScheme.surface,
            hex: '#${colorScheme.surface.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
          ),
          _ColorSwatch(
            name: 'On Surface',
            color: colorScheme.onSurface,
            hex: '#${colorScheme.onSurface.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
          ),
          _ColorSwatch(
            name: 'Error',
            color: colorScheme.error,
            hex: '#${colorScheme.error.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
          ),
          _ColorSwatch(
            name: 'Outline',
            color: colorScheme.outline,
            hex: '#${colorScheme.outline.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
          ),
          _ColorSwatch(
            name: 'Card Background',
            color: theme.cardBackground,
            hex: '#${theme.cardBackground.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
          ),
        ],
      ),
    );
  },
  codeSnippet: '''// Acessar cores via ColorScheme ou CadifeThemeExtension
Theme.of(context).colorScheme.primary
context.cadife.primary''',
);

class _ColorSwatch extends StatelessWidget {
  final String name;
  final Color color;
  final String hex;
  
  const _ColorSwatch({
    required this.name,
    required this.color,
    required this.hex,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: Theme.of(context).textTheme.labelMedium,
          textAlign: TextAlign.center,
        ),
        Text(
          hex,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
