import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Brand ---
  static const Color primary      = Color(0xFFDD0B0E);
  static const Color primaryLight = Color(0xFFFFEAEA);
  static const Color primaryDark  = Color(0xFFB00000);
  
  // --- Modern Black & Zinc Palette (Premium Contrast) ---
  static const Color black      = Color(0xFF000000);
  static const Color zinc950    = Color(0xFF09090B); // Background / Darkest
  static const Color zinc900    = Color(0xFF18181B); // Card / Surface Dark
  static const Color zinc800    = Color(0xFF27272A); // Border Dark
  static const Color zinc700    = Color(0xFF3F3F46); // Muted Dark
  static const Color zinc600    = Color(0xFF52525B); // Secondary Dark
  static const Color zinc500    = Color(0xFF71717A); // Gray
  static const Color zinc400    = Color(0xFFA1A1AA); // Muted Light
  static const Color zinc300    = Color(0xFFD4D4D8); // Border Light
  static const Color zinc200    = Color(0xFFE4E4E7); // Divider Light
  static const Color zinc100    = Color(0xFFF4F4F5); // Surface Light
  static const Color zinc50     = Color(0xFFFAFAFA); // Background Light
  static const Color white      = Color(0xFFFFFFFF);

  // --- Backgrounds ---
  static const Color backgroundDark    = zinc950;
  static const Color backgroundLight   = white;
  static const Color scaffoldLight     = zinc50;
  static const Color scaffoldDark      = black;

  // --- Semantic ---
  static const Color success = Color(0xFF1E8449);
  static const Color warning = Color(0xFFD35400);
  static const Color error   = primary;
  static const Color info    = Color(0xFF2980B9);

  // --- Card System (CDS — solid, sem glassmorphism) ---
  static const Color cardBackground     = Color(0xFFF8F9FA); // light surface
  static const Color cardBackgroundDark = Color(0xFF2D2D2D); // dark surface
  static const Color borderColor        = Color(0xFFE8EAED); // light border
  static const Color borderColorDark    = Color(0xFF3F3F46); // dark border
  static const Color textPrimary        = Color(0xFF1A1A1A); // light text primary
  static const Color textSecondary      = Color(0xFF5D6D7E); // light text secondary

  // --- Glassmorphism (legado — não usar em novos widgets) ---
  static const Color glassBase     = Color(0x1AFFFFFF);
  static const Color glassBorder   = Color(0x33FFFFFF);
  static const Color glassBlur     = Color(0x0DFFFFFF);

  // --- Text ---
  static const Color textPrimaryLight   = zinc950;
  static const Color textSecondaryLight = zinc600;
  static const Color textPrimaryDark    = zinc50;
  static const Color textSecondaryDark  = zinc400;

  // --- Lead score ---
  static const Color scoreQuente = success;
  static const Color scoreMorno  = Color(0xFFFAA62A);
  static const Color scoreFrio   = zinc500;

  // --- Google brand colors ---
  static const Color googleBlue   = Color(0xFF4285F4);
  static const Color googleGreen  = Color(0xFF34A853);
  static const Color googleYellow = Color(0xFFFBBC05);
  static const Color googleRed    = Color(0xFFEA4335);

  // --- Overlays ---
  static const Color overlayDark    = Color(0xCC000000); 
  static const Color whiteOverlay15 = Color(0x26FFFFFF);

  // --- Legacy / Missing Getters (for compatibility) ---
  static const Color textOnPrimary = white;
  static const Color textOnDark    = white;
  static const Color darkSurface   = zinc900;
  static const Color fallbackNavyLight = Color(0xFF1A5276);
  static const Color fallbackNavyDark  = Color(0xFF0D2B3E);

  // --- Feature Specific ---
  static const Color bubbleConsultantLight = Color(0xFFDCEEFA);
  static const Color bubbleConsultantDark  = Color(0xFF154360);
  static const Color passaporteBgDark      = Color(0xFF1E3A2F);
  static const Color passaporteBgLight     = Color(0xFFE8F5E9);

  static Color scoreColor(String score) => switch (score.toLowerCase()) {
    'quente' => success,
    'morno'  => const Color(0xFFFAA62A),
    _        => zinc500,
  };

  static Color statusColor(String status) => switch (status.toLowerCase()) {
    'qualificado' => success,
    'fechado'     => success,
    'agendado'    => const Color(0xFF1A5276),
    'proposta'    => const Color(0xFF7D6608),
    'perdido'     => zinc500,
    _             => primary,
  };
}
