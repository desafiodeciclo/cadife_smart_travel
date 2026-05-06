import 'package:cadife_smart_travel/config/dev/component_library_models.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

            // Preview area — wrapped in Material so ShadButton / ShadTheme
            // descendants get the correct inherited theme from the widget tree.
            // Using a Builder here ensures the context used by component.builder
            // is rooted inside this Material, not above it.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: _SafePreview(builder: component.builder),
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
              ...component.notes!.map(
                (note) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Expanded(
                        child: Text(
                          note,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders a component builder inside a [SingleChildScrollView], catching any
/// synchronous build-time errors and showing a friendly error card instead of
/// a black / empty surface.
class _SafePreview extends StatefulWidget {
  final Widget Function(BuildContext) builder;

  const _SafePreview({required this.builder});

  @override
  State<_SafePreview> createState() => _SafePreviewState();
}

class _SafePreviewState extends State<_SafePreview> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorCard(error: _error!);
    }

    // Use a try/catch to surface synchronous builder errors as readable cards
    // instead of black surfaces.
    Widget preview;
    try {
      preview = widget.builder(context);
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _error = e);
      });
      return const SizedBox.shrink();
    }

    // NOTE: Do NOT wrap in a horizontal SingleChildScrollView here.
    // Components that use width: double.infinity (e.g. CadifeButton) will
    // crash with unbounded width constraints inside a horizontal scroll.
    // Each builder is responsible for its own sizing constraints.
    return preview;
  }
}

class _ErrorCard extends StatelessWidget {
  final Object error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Erro ao renderizar o componente',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontFamily: 'Courier New',
            ),
          ),
        ],
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
              style: const TextStyle(fontFamily: 'Courier New', fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
