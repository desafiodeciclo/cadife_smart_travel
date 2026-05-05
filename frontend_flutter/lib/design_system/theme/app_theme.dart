import 'package:cadife_smart_travel/config/theme/android_slide_page_transitions_builder.dart';
import 'package:cadife_smart_travel/design_system/theme/cadife_theme_extension.dart';
import 'package:cadife_smart_travel/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark  => _build(Brightness.dark);

  static ShadThemeData shadTheme(BuildContext context, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ShadThemeData(
      brightness: brightness,
      colorScheme: isDark 
        ? const ShadZincColorScheme.dark(
            background: AppColors.backgroundDark,
            primary: AppColors.primary,
          )
        : const ShadZincColorScheme.light(
            primary: AppColors.primary,
          ),
      textTheme: ShadTextTheme.fromGoogleFont(GoogleFonts.inter),

    );
  }

  static ThemeData _build(Brightness brightness) {
    final ext = brightness == Brightness.dark ? CadifeThemeExtension.dark : CadifeThemeExtension.light;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary:   ext.primary,
      onPrimary: AppColors.white,
      surface:   ext.background,
      onSurface: ext.textPrimary,
      error:     AppColors.primary,
      outline:   ext.cardBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ext.background,
      extensions: [ext],
      textTheme: _buildTextTheme(brightness, ext),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AndroidSlidePageTransitionsBuilder(),
          TargetPlatform.iOS:     const CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: const FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS:   const CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ext.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, 
          fontWeight: FontWeight.w900, 
          color: ext.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ext.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: ext.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: ext.cardBorder,
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ext.muted.withValues(alpha: 0.5),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ext.primary, width: 1)),
        errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ext.primary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.inter(color: ext.textSecondary),
        hintStyle:  GoogleFonts.inter(color: ext.textSecondary.withValues(alpha: 0.5)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ext.background,
        selectedItemColor: ext.primary,
        unselectedItemColor: ext.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
      ),
      dividerTheme: DividerThemeData(
        color: ext.divider,
        thickness: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness, CadifeThemeExtension ext) {
    final color = ext.textPrimary;
    return TextTheme(
      displayLarge:   GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900,   color: color, letterSpacing: -1),
      displayMedium:  GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800,   color: color, letterSpacing: -1),
      displaySmall:   GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800,   color: color, letterSpacing: -0.5),
      headlineLarge:  GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700,   color: color),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700,   color: color),
      headlineSmall:  GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700,   color: color),
      titleLarge:     GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600,   color: color),
      titleMedium:    GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600,   color: color),
      titleSmall:     GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,   color: color),
      bodyLarge:      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: color),
      bodyMedium:     GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: color),
      bodySmall:      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal, color: color),
      labelLarge:     GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,   color: color),
      labelMedium:    GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,   color: color),
      labelSmall:     GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,   color: color),
    );
  }
}
