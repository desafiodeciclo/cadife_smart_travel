import 'package:cadife_smart_travel/config/theme/cadife_colors.dart';
import 'package:flutter/material.dart';

class CadifeTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: CadifeColors.lightColorScheme,
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: CadifeColors.lightColorScheme.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(
          color: CadifeColors.lightColorScheme.onSurface,
        ),
        titleTextStyle: const TextStyle(
          color: Color(0xFF1C1B1F),
          fontSize: 20,
          fontFamily: 'Bai Jamjuree',
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: CadifeColors.lightColorScheme.surface,
        selectedItemColor: CadifeColors.lightColorScheme.primary,
        unselectedItemColor: CadifeColors.lightColorScheme.onSurfaceVariant,
        elevation: 8,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: CadifeColors.lightColorScheme.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        fillColor: CadifeColors.lightColorScheme.surface, // Fallback
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: CadifeColors.lightColorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: CadifeColors.lightColorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: CadifeColors.lightColorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: CadifeColors.lightColorScheme.error,
          ),
        ),
        hintStyle: TextStyle(
          color: CadifeColors.lightColorScheme.onSurfaceVariant,
        ),
        labelStyle: TextStyle(
          color: CadifeColors.lightColorScheme.onSurface,
        ),
      ),
      
      // Text Theme
      textTheme: _buildTextTheme(CadifeColors.lightColorScheme),
      
      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: CadifeColors.lightColorScheme.primary,
        foregroundColor: CadifeColors.lightColorScheme.onPrimary,
        elevation: 6,
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: CadifeColors.lightColorScheme.surface, // Fallback
        selectedColor: CadifeColors.lightColorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: CadifeColors.lightColorScheme.onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          color: CadifeColors.lightColorScheme.primary,
        ),
      ),
      
      // Scaffold
      scaffoldBackgroundColor: CadifeColors.lightColorScheme.surface,
      
      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CadifeColors.lightColorScheme.primary,
          foregroundColor: CadifeColors.lightColorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CadifeColors.lightColorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: CadifeColors.lightColorScheme.onSurface, // Fallback
        ),
      ),
    );
  }
  
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: CadifeColors.darkColorScheme,
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: CadifeColors.darkColorScheme.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(
          color: CadifeColors.darkColorScheme.onSurface,
        ),
        titleTextStyle: const TextStyle(
          color: Color(0xFFE8E8E8),
          fontSize: 20,
          fontFamily: 'Bai Jamjuree',
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: CadifeColors.darkColorScheme.surface,
        selectedItemColor: CadifeColors.darkColorScheme.primary,
        unselectedItemColor: CadifeColors.darkColorScheme.onSurfaceVariant,
        elevation: 8,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: CadifeColors.darkColorScheme.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        fillColor: CadifeColors.darkColorScheme.surface, // Fallback
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: CadifeColors.darkColorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: CadifeColors.darkColorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: CadifeColors.darkColorScheme.error,
          ),
        ),
        hintStyle: TextStyle(
          color: CadifeColors.darkColorScheme.onSurfaceVariant,
        ),
        labelStyle: TextStyle(
          color: CadifeColors.darkColorScheme.onSurface,
        ),
      ),
      
      // Text Theme
      textTheme: _buildTextTheme(CadifeColors.darkColorScheme),
      
      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: CadifeColors.darkColorScheme.primary,
        foregroundColor: CadifeColors.darkColorScheme.onPrimary,
        elevation: 6,
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: CadifeColors.darkColorScheme.surface, // Fallback
        selectedColor: CadifeColors.darkColorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: CadifeColors.darkColorScheme.onSurface,
        ),
      ),
      
      // Scaffold
      scaffoldBackgroundColor: CadifeColors.darkColorScheme.surface,
      
      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CadifeColors.darkColorScheme.primary,
          foregroundColor: CadifeColors.darkColorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CadifeColors.darkColorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: CadifeColors.darkColorScheme.onSurface, // Fallback
        ),
      ),
    );
  }
  
  // Text Theme compartilhado
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        fontFamily: 'Bai Jamjuree',
        color: colorScheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        fontFamily: 'Bai Jamjuree',
        color: colorScheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        fontFamily: 'Bai Jamjuree',
        color: colorScheme.onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        fontFamily: 'Bai Jamjuree',
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        fontFamily: 'Bai Jamjuree',
        color: colorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFamily: 'Bai Jamjuree',
        color: colorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        fontFamily: 'Bai Jamjuree',
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
        color: colorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontFamily: 'Inter',
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontFamily: 'Inter',
        color: colorScheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontFamily: 'Inter',
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
        color: colorScheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
        color: colorScheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        fontFamily: 'Inter',
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
