import 'package:flutter/material.dart';

class CadifeColors {
  // Light Mode
  static const ColorScheme lightColorScheme = ColorScheme.light(
    // Primária
    primary: Color(0xFFDD0B0E),           // Red Cadife
    onPrimary: Color(0xFFFFFFFF),         // White
    
    // Secundária
    secondary: Color(0xFF625B71),         // Mauve
    onSecondary: Color(0xFFFFFFFF),       // White
    
    // Superfícies
    surface: Color(0xFFFAFAFA),           // Almost white
    onSurface: Color(0xFF1C1B1F),         // Deep black
    
    // Erro
    error: Color(0xFFB3261E),             // Red error
    onError: Color(0xFFFFFFFF),
  );
  
  // Dark Mode
  static const ColorScheme darkColorScheme = ColorScheme.dark(
    // Primária (mantém Red Cadife)
    primary: Color(0xFFDD0B0E),           // Red Cadife
    onPrimary: Color(0xFF5C0D0F),         // Dark red
    
    // Secundária
    secondary: Color(0xFFCCC7D8),         // Mauve light
    onSecondary: Color(0xFF332D41),       // Dark mauve
    
    // Superfícies (Deep Graphite base)
    surface: Color(0xFF393532),           // Deep Graphite base
    onSurface: Color(0xFFE8E8E8),         // Almost white
    
    // Erro
    error: Color(0xFFF2B8B5),             // Light red error
    onError: Color(0xFF601410),           // Dark red
  );
}
