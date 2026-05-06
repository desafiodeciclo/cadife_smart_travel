import 'package:cadife_smart_travel/config/dev/component_library_models.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

final cardShowcases = [
  ComponentShowcaseData(
    name: 'CadifeCard — Standard',
    description: 'Card padrão com padding e border-radius.',
    category: ComponentCategory.cards,
    builder: (context) => const CadifeCard(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Card content aqui'),
      ),
    ),
    codeSnippet: '''CadifeCard(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text('Card content'),
  ),
)''',
  ),
  
  ComponentShowcaseData(
    name: 'CadifeCard — Elevated',
    description: 'Card com elevação e sombra.',
    category: ComponentCategory.cards,
    builder: (context) => const CadifeCard(
      variant: CardVariant.elevated,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Card elevado'),
      ),
    ),
    codeSnippet: '''CadifeCard(
  variant: CardVariant.elevated,
  child: Text('Card elevado'),
)''',
  ),
  
  ComponentShowcaseData(
    name: 'CadifeCard — Outlined',
    description: 'Card com apenas outline.',
    category: ComponentCategory.cards,
    builder: (context) => const CadifeCard(
      variant: CardVariant.outlined,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Card outlined'),
      ),
    ),
    codeSnippet: '''CadifeCard(
  variant: CardVariant.outlined,
  child: Text('Card outlined'),
)''',
  ),
];

final feedbackShowcases = [
  ComponentShowcaseData(
    name: 'ShimmerLoading',
    description: 'Animação de loading em skeleton.',
    category: ComponentCategory.feedback,
    builder: (context) => const SizedBox(
      height: 100,
      width: 300,
      child: ShimmerLoading(
        isLoading: true,
        child: Skeleton(width: 300, height: 100),
      ),
    ),
    codeSnippet: '''ShimmerLoading(
  isLoading: true,
  child: Skeleton(width: 300, height: 100),
)''',
  ),
  
  ComponentShowcaseData(
    name: 'CadifeSnackbar',
    description: 'Snackbar com variantes de tipo.',
    category: ComponentCategory.feedback,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Sucesso!'),
              backgroundColor: Colors.green,
            ),
          ),
          child: const Text('Show Success'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erro!'),
              backgroundColor: Colors.red,
            ),
          ),
          child: const Text('Show Error'),
        ),
      ],
    ),
    codeSnippet: '''ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('✅ Sucesso!'),
    backgroundColor: Colors.green,
  ),
)''',
  ),
  
  ComponentShowcaseData(
    name: 'CadifeDialog — Interactive',
    description: 'Clique no botão para abrir o dialog.',
    category: ComponentCategory.feedback,
    builder: (context) => ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar ação'),
            content: const Text('Tem certeza?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );
      },
      child: const Text('Abrir Dialog'),
    ),
    codeSnippet: '''showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Confirmar ação'),
    content: Text('Tem certeza?'),
    actions: [...],
  ),
)''',
  ),
];
