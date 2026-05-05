import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WCAG AA Contrast Validation', () {
    double getRelativeLuminance(Color color) {
      final r = color.r;
      final g = color.g;
      final b = color.b;
      
      final rLin = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2).toDouble();
      final gLin = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2).toDouble();
      final bLin = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2).toDouble();
      
      return 0.2126 * rLin + 0.7152 * gLin + 0.0722 * bLin;
    }
    
    double getContrastRatio(Color foreground, Color background) {
      final l1 = getRelativeLuminance(foreground);
      final l2 = getRelativeLuminance(background);
      
      final lighter = max(l1, l2);
      final darker = min(l1, l2);
      
      return (lighter + 0.05) / (darker + 0.05);
    }
    
    test('Text on surface em modo dark tem contraste >= 4.5 (AA)', () {
      const onSurface = Color(0xFFE8E8E8);
      const surface = Color(0xFF393532);
      
      final contrast = getContrastRatio(onSurface, surface);
      expect(contrast, greaterThanOrEqualTo(4.5));
    });
    
    test('Primary text em modo light tem contraste >= 4.5', () {
      const onSurface = Color(0xFF1C1B1F);
      const surface = Color(0xFFFAFAFA);
      
      final contrast = getContrastRatio(onSurface, surface);
      expect(contrast, greaterThanOrEqualTo(4.5));
    });
    
    test('Button text em modo dark tem contraste >= 4.5', () {
      const onPrimary = Color(0xFFFFFFFF); // White on Red Cadife
      const primary = Color(0xFFDD0B0E);
      
      final contrast = getContrastRatio(onPrimary, primary);
      expect(contrast, greaterThanOrEqualTo(4.5),
        reason: 'Dark mode button contrast deve ser AA compliant');
    });
  });
}
