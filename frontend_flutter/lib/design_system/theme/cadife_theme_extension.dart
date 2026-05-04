import 'package:cadife_smart_travel/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';

@immutable
class CadifeThemeExtension extends ThemeExtension<CadifeThemeExtension> {
  const CadifeThemeExtension({
    required this.primary,
    required this.background,
    required this.surface,
    required this.cardBackground,
    required this.cardBorder,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.muted,
    required this.success,
    required this.warning,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final Color primary;
  final Color background;
  final Color surface;
  final Color cardBackground;
  final Color cardBorder;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color muted;
  final Color success;
  final Color warning;
  final Color shimmerBase;
  final Color shimmerHighlight;

  static const light = CadifeThemeExtension(
    primary:          AppColors.primary,
    background:       AppColors.scaffoldLight,
    surface:          AppColors.white,
    cardBackground:   AppColors.white,
    cardBorder:       AppColors.zinc200,
    divider:          AppColors.zinc200,
    textPrimary:      AppColors.textPrimaryLight,
    textSecondary:    AppColors.textSecondaryLight,
    muted:            AppColors.zinc100,
    success:          AppColors.success,
    warning:          AppColors.warning,
    shimmerBase:      AppColors.zinc200,
    shimmerHighlight: AppColors.zinc100,
  );

  static const dark = CadifeThemeExtension(
    primary:          AppColors.primary,
    background:       AppColors.backgroundDark,
    surface:          AppColors.zinc900,
    cardBackground:   AppColors.zinc900,
    cardBorder:       AppColors.zinc800,
    divider:          AppColors.zinc800,
    textPrimary:      AppColors.textPrimaryDark,
    textSecondary:    AppColors.textSecondaryDark,
    muted:            AppColors.zinc800,
    success:          AppColors.success,
    warning:          AppColors.warning,
    shimmerBase:      AppColors.zinc900,
    shimmerHighlight: AppColors.zinc800,
  );

  @override
  CadifeThemeExtension copyWith({
    Color? primary, Color? background, Color? surface, Color? cardBackground,
    Color? cardBorder, Color? divider, Color? textPrimary, Color? textSecondary,
    Color? muted, Color? success, Color? warning, Color? shimmerBase, Color? shimmerHighlight,
  }) => CadifeThemeExtension(
    primary:          primary ?? this.primary,
    background:       background ?? this.background,
    surface:          surface ?? this.surface,
    cardBackground:   cardBackground ?? this.cardBackground,
    cardBorder:       cardBorder ?? this.cardBorder,
    divider:          divider ?? this.divider,
    textPrimary:      textPrimary ?? this.textPrimary,
    textSecondary:    textSecondary ?? this.textSecondary,
    muted:            muted ?? this.muted,
    success:          success ?? this.success,
    warning:          warning ?? this.warning,
    shimmerBase:      shimmerBase ?? this.shimmerBase,
    shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
  );

  @override
  CadifeThemeExtension lerp(CadifeThemeExtension? other, double t) {
    if (other == null) return this;
    return CadifeThemeExtension(
      primary:          Color.lerp(primary, other.primary, t)!,
      background:       Color.lerp(background, other.background, t)!,
      surface:          Color.lerp(surface, other.surface, t)!,
      cardBackground:   Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder:       Color.lerp(cardBorder, other.cardBorder, t)!,
      divider:          Color.lerp(divider, other.divider, t)!,
      textPrimary:      Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary:    Color.lerp(textSecondary, other.textSecondary, t)!,
      muted:            Color.lerp(muted, other.muted, t)!,
      success:          Color.lerp(success, other.success, t)!,
      warning:          Color.lerp(warning, other.warning, t)!,
      shimmerBase:      Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}

extension CadifeTheme on BuildContext {
  CadifeThemeExtension get cadife =>
      Theme.of(this).extension<CadifeThemeExtension>()!;
      
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
