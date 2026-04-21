import 'package:flutter/material.dart';

/// Tokens de cor da Cadife Tour — TODOS os hexadecimais ficam aqui.
/// Nunca use Color(0xff...) diretamente em widgets.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────
  static const Color primary = Color(0xFFdd0b0e);
  static const Color primaryDark = Color(0xFFb0090b);
  static const Color primaryLight = Color(0xFFe83c3e);

  // ── Backgrounds ────────────────────────────────────────
  static const Color background = Color(0xFF393532);
  static const Color scaffold = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFF0F2F5);

  // ── Semantic ───────────────────────────────────────────
  static const Color success = Color(0xFF1E8449);
  static const Color warning = Color(0xFFD35400);
  static const Color error = Color(0xFFC0392B);
  static const Color info = Color(0xFF2980B9);

  // ── Text ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5D6D7E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ── Lead Score ─────────────────────────────────────────
  static const Color scoreQuente = Color(0xFF1E8449);
  static const Color scoreMorno = Color(0xFFD35400);
  static const Color scoreFrio = Color(0xFF95A5A6);

  // ── Borders & Dividers ─────────────────────────────────
  static const Color border = Color(0xFFDEE2E6);
  static const Color divider = Color(0xFFE9ECEF);

  // ── Shadow ─────────────────────────────────────────────
  static Color shadow = const Color(0xFF000000).withValues(alpha: 0.08);
}
