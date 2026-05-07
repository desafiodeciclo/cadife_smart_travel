import 'package:cadife_smart_travel/features/settings/domain/entities/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> configureSystemChrome(ThemePreference theme) async {
  final isDark = theme == ThemePreference.dark;
  
  // Status bar (top)
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark
          ? const Color(0xFF1C1B1F)  // Deep Black
          : const Color(0xFFFAFAFA), // Almost white
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
}
