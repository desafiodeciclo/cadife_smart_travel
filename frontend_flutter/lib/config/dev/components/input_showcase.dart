import 'package:cadife_smart_travel/config/dev/component_library_models.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

final inputShowcases = [
  ComponentShowcaseData(
    name: 'CadifeInput — Default',
    description: 'Input padrão vazio.',
    category: ComponentCategory.inputs,
    builder: (context) => const CadifeInput(
      label: 'E-mail',
      hintText: 'seu@email.com',
    ),
    codeSnippet: '''CadifeInput(
  label: 'E-mail',
  hintText: 'seu@email.com',
)''',
  ),
  
  ComponentShowcaseData(
    name: 'CadifeInput — Initial Value',
    description: 'Input com valor inicial.',
    category: ComponentCategory.inputs,
    builder: (context) => const CadifeInput(
      label: 'Nome',
      initialValue: 'João Silva',
    ),
    codeSnippet: '''CadifeInput(
  label: 'Nome',
  initialValue: 'João Silva',
)''',
  ),
  
  ComponentShowcaseData(
    name: 'CadifeInput — Error',
    description: 'Input com erro de validação.',
    category: ComponentCategory.inputs,
    builder: (context) => const CadifeInput(
      label: 'E-mail',
      hintText: 'seu@email.com',
      errorText: 'Campo obrigatório',
    ),
    codeSnippet: '''CadifeInput(
  label: 'E-mail',
  errorText: 'Campo obrigatório',
)''',
  ),
  
  ComponentShowcaseData(
    name: 'CadifeInput — Disabled',
    description: 'Input desabilitado (leitura apenas).',
    category: ComponentCategory.inputs,
    builder: (context) => const CadifeInput(
      label: 'Status (read-only)',
      initialValue: 'Ativo',
      enabled: false,
    ),
    codeSnippet: '''CadifeInput(
  label: 'Status',
  initialValue: 'Ativo',
  enabled: false,
)''',
  ),
  
  ComponentShowcaseData(
    name: 'CadifeInput — Password',
    description: 'Input de senha com obscureText.',
    category: ComponentCategory.inputs,
    builder: (context) => const CadifeInput(
      label: 'Senha',
      hintText: '••••••••',
      isPassword: true,
    ),
    codeSnippet: '''CadifeInput(
  label: 'Senha',
  isPassword: true,
)''',
  ),
  
  ComponentShowcaseData(
    name: 'CadifeInput — Validation Demo',
    description: 'Validação em tempo real ao digitar.',
    category: ComponentCategory.inputs,
    builder: (context) => const _InteractiveInputDemo(),
    codeSnippet: '''Form com validação interativa
onChanged callback mostra erros em tempo real''',
  ),
];

class _InteractiveInputDemo extends StatefulWidget {
  const _InteractiveInputDemo();

  @override
  State<_InteractiveInputDemo> createState() =>
      _InteractiveInputDemoState();
}

class _InteractiveInputDemoState extends State<_InteractiveInputDemo> {
  final _controller = TextEditingController();
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _controller.addListener(_validate);
  }
  
  void _validate() {
    setState(() {
      if (_controller.text.isEmpty) {
        _error = 'Campo obrigatório';
      } else if (!_controller.text.contains('@')) {
        _error = 'E-mail inválido';
      } else {
        _error = null;
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return CadifeInput(
      label: 'E-mail',
      controller: _controller,
      hintText: 'seu@email.com',
      errorText: _error,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
