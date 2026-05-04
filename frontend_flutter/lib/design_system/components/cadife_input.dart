import 'package:cadife_smart_travel/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CadifeInput extends StatefulWidget {
  final String label;
  final String? hint;
  final String? hintText; // Alias for hint
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final int? maxLines;

  const CadifeInput({
    super.key,
    required this.label,
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
  bool _touched = false;

  void _validate(String value) {
    if (widget.validator != null && _touched) {
      final error = widget.validator!(value);
      if (error != _errorText) {
        setState(() => _errorText = error);
      }
    } else if (_errorText != null) {
      setState(() => _errorText = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark ? AppColors.deepGraphite.withValues(alpha: 0.5) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _errorText != null
                  ? AppColors.primary
                  : _touched
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : Colors.grey.shade300,
              width: _errorText != null ? 2 : 1,
            ),
            boxShadow: [
              if (_errorText == null && _touched)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword && _obscureText,
            keyboardType: widget.keyboardType,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint ?? widget.hintText,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, size: 20, color: _errorText != null ? AppColors.primary : AppColors.textSecondary)
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (value) {
              if (!_touched) _touched = true;
              _validate(value);
              if (widget.onChanged != null) widget.onChanged!(value);
            },
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: _errorText != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        _errorText!,
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
