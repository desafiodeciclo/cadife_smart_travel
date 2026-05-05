import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static String? get fontFamily => GoogleFonts.inter().fontFamily;

  // Headings (Bai Jamjuree)
  static TextStyle get h1 => GoogleFonts.baiJamjuree(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static TextStyle get h2 => GoogleFonts.baiJamjuree(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3);
  static TextStyle get h3 => GoogleFonts.baiJamjuree(fontSize: 20, fontWeight: FontWeight.w600);
  static TextStyle get h4 => GoogleFonts.baiJamjuree(fontSize: 18, fontWeight: FontWeight.w600);

  // Body (Inter)
  static TextStyle get bodyLarge   => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle get bodyMedium  => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle get bodySmall   => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400);

  // Labels (Inter)
  static TextStyle get labelLarge  => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600);
  static TextStyle get labelMedium => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600);
  static TextStyle get labelSmall  => GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5);

  // Button / Caption / Overline
  static TextStyle get button   => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3);
  static TextStyle get caption  => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400);
  static TextStyle get overline => GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 1.5);
}
