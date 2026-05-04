import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final bool isPhone;
  final bool isCpf;
  final bool isNumeric;
  final IconData? prefixIcon;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.controller,
    this.onChanged,
    this.isPhone = false,
    this.isCpf = false,
    this.isNumeric = false,
    this.prefixIcon,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;
  String? _errorText;
  bool _touched = false;

  late final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  late final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  void _validate(String value) {
    if (widget.validator != null && _touched) {
      final error = widget.validator!(value);
      if (error != _errorText) setState(() => _errorText = error);
    } else if (_errorText != null) {
      setState(() => _errorText = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: (widget.isPhone || widget.isCpf || widget.isNumeric)
                ? TextInputType.number
                : widget.keyboardType,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            inputFormatters: [
              if (widget.isPhone) _phoneFormatter,
              if (widget.isCpf) _cpfFormatter,
              if (widget.isNumeric && !widget.isPhone && !widget.isCpf)
                FilteringTextInputFormatter.digitsOnly,
            ],
            style: TextStyle(color: context.cadife.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              errorText: _errorText,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: _errorText != null ? context.cadife.primary : context.cadife.primary,
                    )
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: context.cadife.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    )
                  : null,
            ),
            onChanged: (value) {
              if (!_touched) _touched = true;
              _validate(value);
              widget.onChanged?.call(value);
            },
          ),
        ],
      ),
    );
  }
}

class AppValidators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o e-mail';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'E-mail inválido';
    return null;
  }

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static String? minLength(String? value, int min) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    if (value.trim().length < min) return 'Mínimo de $min caracteres';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o telefone';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Telefone incompleto';
    return null;
  }

  static String? cpf(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o CPF';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return 'CPF inválido';
    return null;
  }
}
