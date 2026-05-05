import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cadife_smart_travel/config/dev/component_library_models.dart';

class ComponentShowcase extends StatelessWidget {
  final ComponentShowcaseData component;
  
  const ComponentShowcase({super.key, required this.component});
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              component.name,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            
            // Descrição
            Text(
              component.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            
            // Preview (container com border)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: component.builder(context),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Código
            CodeSnippet(code: component.codeSnippet),
            const SizedBox(height: 32),
            
            // Notas
            if (component.notes != null && component.notes!.isNotEmpty) ...[
              Text(
                'Notas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...component.notes!.map((note) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: Theme.of(context).textTheme.bodyMedium),
                    Expanded(
                      child: Text(
                        note,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class CodeSnippet extends StatelessWidget {
  final String code;
  
  const CodeSnippet({super.key, required this.code});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Código', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código copiado')),
                );
              },
              tooltip: 'Copiar código',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              code,
              style: const TextStyle(
                fontFamily: 'Courier New',
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
