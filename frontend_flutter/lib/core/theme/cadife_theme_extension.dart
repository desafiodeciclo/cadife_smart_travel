import 'package:flutter/material.dart';

@immutable
class CadifeThemeExtension extends ThemeExtension<CadifeThemeExtension> {
  const CadifeThemeExtension({
    required this.primary,
    required this.darkBackground,
    required this.success,
    required this.warning,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBackground,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final Color primary;
  final Color darkBackground;
  final Color success;
  final Color warning;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBackground;
  final Color shimmerBase;
  final Color shimmerHighlight;

  static const light = CadifeThemeExtension(
    primary: Color(0xFFdd0b0e),
    darkBackground: Color(0xFF393532),
    success: Color(0xFF1E8449),
    warning: Color(0xFFD35400),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF5D6D7E),
    cardBackground: Color(0xFFF8F9FA),
    shimmerBase: Color(0xFFE0E0E0),
    shimmerHighlight: Color(0xFFF5F5F5),
  );

  static const dark = CadifeThemeExtension(
    primary: Color(0xFFFF4447),
    darkBackground: Color(0xFF1E1B19),
    success: Color(0xFF27AE60),
    warning: Color(0xFFE67E22),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFFB0BEC5),
    cardBackground: Color(0xFF2C2C2C),
    shimmerBase: Color(0xFF2C2C2C),
    shimmerHighlight: Color(0xFF3D3D3D),
  );

  @override
  CadifeThemeExtension copyWith({
    Color? primary,
    Color? darkBackground,
    Color? success,
    Color? warning,
    Color? textPrimary,
    Color? textSecondary,
    Color? cardBackground,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return CadifeThemeExtension(
      primary: primary ?? this.primary,
      darkBackground: darkBackground ?? this.darkBackground,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      cardBackground: cardBackground ?? this.cardBackground,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  CadifeThemeExtension lerp(CadifeThemeExtension? other, double t) {
    if (other == null) return this;
    return CadifeThemeExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      darkBackground: Color.lerp(darkBackground, other.darkBackground, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(
        shimmerHighlight,
        other.shimmerHighlight,
        t,
      )!,
    );
  }
}

extension CadifeTheme on BuildContext {
  CadifeThemeExtension get cadife =>
      Theme.of(this).extension<CadifeThemeExtension>()!;
}
