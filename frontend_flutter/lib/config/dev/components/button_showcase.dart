import 'package:cadife_smart_travel/config/dev/component_library_models.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

// CadifeButton uses width: double.infinity which conflicts with the showcase's
// horizontal-scroll preview. Wrapping each button in a fixed-width SizedBox
// gives the button a valid constraint while remaining visually representative.
const _kButtonPreviewWidth = 280.0;

final buttonShowcases = [
  ComponentShowcaseData(
    name: 'CadifeButton — Primary',
    description: 'Botão primary padrão com Red Cadife.',
    category: ComponentCategory.buttons,
    builder: (context) => SizedBox(
      width: _kButtonPreviewWidth,
      child: CadifeButton(
        label: 'Confirmar',
        onPressed: () {},
      ),
    ),
    codeSnippet: '''CadifeButton(
  label: 'Confirmar',
  onPressed: () {},
)''',
  ),

  ComponentShowcaseData(
    name: 'CadifeButton — Secondary',
    description: 'Botão secundário com contorno.',
    category: ComponentCategory.buttons,
    builder: (context) => SizedBox(
      width: _kButtonPreviewWidth,
      child: CadifeButton(
        label: 'Cancelar',
        onPressed: () {},
        variant: ButtonVariant.secondary,
      ),
    ),
    codeSnippet: '''CadifeButton(
  label: 'Cancelar',
  variant: ButtonVariant.secondary,
  onPressed: () {},
)''',
  ),

  ComponentShowcaseData(
    name: 'CadifeButton — Ghost',
    description: 'Botão ghost (sem fundo).',
    category: ComponentCategory.buttons,
    builder: (context) => SizedBox(
      width: _kButtonPreviewWidth,
      child: CadifeButton(
        label: 'Mais informações',
        onPressed: () {},
        variant: ButtonVariant.ghost,
      ),
    ),
    codeSnippet: '''CadifeButton(
  label: 'Mais informações',
  variant: ButtonVariant.ghost,
  onPressed: () {},
)''',
  ),

  ComponentShowcaseData(
    name: 'CadifeButton — Destructive',
    description: 'Botão destrutivo (vermelho de erro).',
    category: ComponentCategory.buttons,
    builder: (context) => SizedBox(
      width: _kButtonPreviewWidth,
      child: CadifeButton(
        label: 'Deletar',
        onPressed: () {},
        variant: ButtonVariant.destructive,
      ),
    ),
    codeSnippet: '''CadifeButton(
  label: 'Deletar',
  variant: ButtonVariant.destructive,
  onPressed: () {},
)''',
  ),

  ComponentShowcaseData(
    name: 'CadifeButton — Loading',
    description: 'Botão em estado de carregamento.',
    category: ComponentCategory.buttons,
    builder: (context) => const SizedBox(
      width: _kButtonPreviewWidth,
      child: CadifeButton(
        label: 'Salvando...',
        isLoading: true,
      ),
    ),
    codeSnippet: '''CadifeButton(
  label: 'Salvando...',
  isLoading: true,
)''',
  ),

  ComponentShowcaseData(
    name: 'CadifeButton — Disabled',
    description: 'Botão desabilitado (onPressed = null).',
    category: ComponentCategory.buttons,
    builder: (context) => const SizedBox(
      width: _kButtonPreviewWidth,
      child: CadifeButton(
        label: 'Indisponível',
        onPressed: null,
      ),
    ),
    codeSnippet: '''CadifeButton(
  label: 'Indisponível',
  onPressed: null,
)''',
  ),

  ComponentShowcaseData(
    name: 'CadifeButton — Interactive States',
    description: 'Clique no botão para ver transição de estados.',
    category: ComponentCategory.buttons,
    builder: (context) => const SizedBox(
      width: _kButtonPreviewWidth,
      child: _InteractiveButtonDemo(),
    ),
    codeSnippet: '''// Clique para ver loading
StatefulWidget com toggle de isLoading''',
  ),
];

class _InteractiveButtonDemo extends StatefulWidget {
  const _InteractiveButtonDemo();

  @override
  State<_InteractiveButtonDemo> createState() => _InteractiveButtonDemoState();
}

class _InteractiveButtonDemoState extends State<_InteractiveButtonDemo> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return CadifeButton(
      label: _isLoading ? 'Salvando...' : 'Clique para enviar',
      isLoading: _isLoading,
      onPressed: () async {
        setState(() => _isLoading = true);
        await Future.delayed(const Duration(seconds: 2));
        if (!context.mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enviado com sucesso!')),
        );
      },
    );
  }
}
