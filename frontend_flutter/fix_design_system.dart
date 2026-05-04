import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  final replacements = {
    // AppColors legacy getters
    r'AppColors\.textPrimary(?![a-zA-Z])': 'context.cadife.textPrimary',
    r'AppColors\.textSecondary(?![a-zA-Z])': 'context.cadife.textSecondary',
    r'AppColors\.background(?![a-zA-Z])': 'context.cadife.background',
    r'AppColors\.scaffold(?![a-zA-Z])': 'context.cadife.background',
    r'AppColors\.surface(?![a-zA-Z])': 'context.cadife.surface',
    r'AppColors\.border(?![a-zA-Z])': 'context.cadife.cardBorder',
    r'AppColors\.divider(?![a-zA-Z])': 'context.cadife.divider',
    r'AppColors\.cardBackground(?![a-zA-Z])': 'context.cadife.cardBackground',
    r'AppColors\.darkCard(?![a-zA-Z])': 'context.cadife.cardBackground',
    r'AppColors\.deepBlack(?![a-zA-Z])': 'context.cadife.background',
    r'AppColors\.progressBackground(?![a-zA-Z])': 'context.cadife.muted',
    r'AppColors\.scaffoldIce(?![a-zA-Z])': 'context.cadife.surface',
    r'AppColors\.cardBorder(?![a-zA-Z])': 'context.cadife.cardBorder',

    // Icons
    'package:lucide_icons_flutter/lucide_icons_flutter.dart': 'package:lucide_icons_flutter/lucide_icons.dart',
  };

  for (final file in files) {
    var content = file.readAsStringSync();
    var changed = false;

    replacements.forEach((pattern, replacement) {
      final regExp = RegExp(pattern);
      if (regExp.hasMatch(content)) {
        content = content.replaceAll(regExp, replacement);
        changed = true;
      }
    });

    if (changed) {
      // If we added context.cadife, ensure design_system is imported
      if (content.contains('context.cadife') && !content.contains('design_system.dart') && !content.contains('cadife_theme_extension.dart')) {
        // Find first import or start of file
        final firstImport = content.indexOf('import ');
        if (firstImport != -1) {
          content = content.replaceRange(firstImport, firstImport, "import 'package:cadife_smart_travel/design_system/design_system.dart';\n");
        } else {
          content = "import 'package:cadife_smart_travel/design_system/design_system.dart';\n$content";
        }
      }
      
      file.writeAsStringSync(content);
      // ignore: avoid_print
      print('Fixed: ${file.path}');
    }
  }
}
