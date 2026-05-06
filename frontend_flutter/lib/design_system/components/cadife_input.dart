import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CadifeInput extends StatefulWidget {
  final String label;
  final String? hint;
  final String? hintText;
  final String? initialValue;
  final bool isPassword;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final int? maxLines;
  final String? errorText;

  const CadifeInput({
    super.key,
    required this.label,
    this.hint,
    this.hintText,
    this.initialValue,
    this.isPassword = false,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.validator,
    this.controller,
    this.onChanged,
    this.prefixIcon,
    this.maxLines = 1,
    this.errorText,
  });

  @override
  State<CadifeInput> createState() => _CadifeInputState();
}

class _CadifeInputState extends State<CadifeInput> {
  late bool _obscureText;
  String? _internalErrorText;
  bool _isFocused = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword || widget.obscureText;
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(CadifeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  void _validate(String value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (error != _internalErrorText) {
        setState(() => _internalErrorText = error);
      }
    }
  }

  String? get _effectiveErrorText => widget.errorText ?? _internalErrorText;

  @override
  Widget build(BuildContext context) {
    final theme = context.cadife;
    final isEffectiveObscure = (widget.isPassword || widget.obscureText) && _obscureText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              color: widget.enabled 
                ? theme.textPrimary.withValues(alpha: 0.8)
                : theme.textSecondary.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Focus(
          onFocusChange: (focused) {
            if (widget.enabled) {
              setState(() => _isFocused = focused);
            }
          },
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.6,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: theme.muted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _effectiveErrorText != null
                      ? theme.primary
                      : _isFocused
                          ? theme.primary
                          : theme.cardBorder,
                  width: 1.5,
                ),
              ),
              child: TextFormField(
                controller: _controller,
                obscureText: isEffectiveObscure,
                enabled: widget.enabled,
                keyboardType: widget.keyboardType,
                maxLines: isEffectiveObscure ? 1 : widget.maxLines,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                style: GoogleFonts.inter(
                  color: theme.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint ?? widget.hintText,
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon, 
                          size: 18, 
                          color: _isFocused ? theme.primary : theme.textSecondary
                        )
                      : null,
                  suffixIcon: (widget.isPassword || widget.obscureText)
                      ? IconButton(
                          icon: Icon(
                            _obscureText ? LucideIcons.eye : LucideIcons.eyeOff,
                            color: theme.textSecondary,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) {
                  _validate(value);
                  if (widget.onChanged != null) widget.onChanged!(value);
                },
              ),
            ),
          ),
        ),
        if (_effectiveErrorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _effectiveErrorText!,
              style: GoogleFonts.inter(
                color: theme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
