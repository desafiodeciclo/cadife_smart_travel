import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CadifeInput extends StatefulWidget {
  final String label;
  final String? hint;
  final String? hintText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final int? maxLines;

  const CadifeInput({
    required this.label,
    super.key,
    this.hint,
    this.hintText,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.controller,
    this.onChanged,
    this.prefixIcon,
    this.maxLines = 1,
  });

  @override
  State<CadifeInput> createState() => _CadifeInputState();
}

class _CadifeInputState extends State<CadifeInput> {
  bool _obscureText = true;
  String? _errorText;
  bool _isFocused = false;

  void _validate(String value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (error != _errorText) {
        setState(() => _errorText = error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.cadife;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              color: theme.textPrimary.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Focus(
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: theme.muted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _errorText != null
                    ? theme.primary
                    : _isFocused
                        ? theme.primary
                        : theme.cardBorder,
                width: 1.5,
              ),
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.isPassword && _obscureText,
              keyboardType: widget.keyboardType,
              maxLines: widget.isPassword ? 1 : widget.maxLines,
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
                suffixIcon: widget.isPassword
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
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _errorText!,
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
