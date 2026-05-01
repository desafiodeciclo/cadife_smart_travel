import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFFDD0B0E); // Vermelho Cadife
  static const Color primaryLight = Color(0xFFFFEAEA); // Vermelho Claro para gradientes
  static const Color primaryDark = Color(0xFFB00000); // Vermelho Escuro para gradientes
  static const Color deepGraphite = Color(0xFF393532); // Grafite Profundo
  static const Color darkWine = Color(0xFF53141C); // Vinho Escuro
  static const Color vibrantOrange = Color(0xFFFAA62A); // Laranja Vibrante

  // Backgrounds
  static const Color background = deepGraphite;
  static const Color scaffold = Color(0xFFFFFFFF);
  static const Color scaffoldIce = Color(0xFFF1F1F1);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF0F2F5);

  // Semantic
  static const Color success = Color(0xFF1E8449);
  static const Color warning = Color(0xFFD35400);
  static const Color error = primary; // CDS says error is Red Cadife below input
  static const Color info = Color(0xFF2980B9);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5D6D7E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Leads
  static const Color scoreQuente = success;
  static const Color scoreMorno = Color(0xFFFAA62A); // Using vibrant orange
  static const Color scoreFrio = Color(0xFF95A5A6);

  static const Color border = Color(0xFFDEE2E6);
  static const Color divider = Color(0xFFE9ECEF);

  static Color shadow = const Color(0xFF000000).withValues(alpha: 0.1);
  static Color premiumShadow = const Color(0xFF000000).withValues(alpha: 0.1);

  // Dark mode surfaces
  static const Color darkSurface = Color(0xFF1C1917);
  static const Color darkCard = Color(0xFF292524);
  static const Color darkTextHint = Color(0xFFB0BEC5);

  // Passaporte toggle states
  static const Color passaporteBgDark = Color(0xFF1E3A2F);
  static const Color passaporteBgLight = Color(0xFFE8F5E9);
  static const Color successTextDark = Color(0xFF81C784);

  static Color scoreColor(String score) => switch (score.toLowerCase()) {
    'quente' => success,
    'morno' => vibrantOrange,
    _ => textSecondary,
  };

  static Color statusColor(String status) => switch (status.toLowerCase()) {
    'qualificado' => success,
    'fechado' => success,
    'agendado' => const Color(0xFF1A5276),
    'proposta' => const Color(0xFF7D6608),
    'perdido' => textSecondary,
    _ => primary,
  };
}
