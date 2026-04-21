import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFdd0b0e);
  static const Color background = Color(0xFF393532);
  static const Color scaffold = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFFdd0b0e);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5D6D7E);
  static const Color cardBackground = Color(0xFFF8F9FA);
  static const Color success = Color(0xFF1E8449);
  static const Color warning = Color(0xFFD35400);
  static const Color error = Color(0xFFdd0b0e);

  static Color scoreColor(String score) => switch (score) {
        'quente' => success,
        'morno' => warning,
        _ => textSecondary,
      };

  static Color statusColor(String status) => switch (status) {
        'qualificado' => success,
        'fechado' => success,
        'agendado' => const Color(0xFF1A5276),
        'proposta' => const Color(0xFF7D6608),
        'perdido' => textSecondary,
        _ => primary,
      };
}
