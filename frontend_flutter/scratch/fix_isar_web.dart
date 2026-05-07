
import 'dart:io';

void main() async {
  final directory = Directory('lib');
  if (!directory.existsSync()) {
    stdout.writeln('Directory lib not found');
    return;
  }

  final files = directory.listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.g.dart'));

  final largeIntRegex = RegExp(r'id:\s*(-?\d+),');
  const maxSafeInt = 9007199254740991;

  for (final file in files) {
    final content = await file.readAsString();
    bool changed = false;
    
    final newContent = content.replaceAllMapped(largeIntRegex, (match) {
      final valueStr = match.group(1)!;
      final value = int.tryParse(valueStr);
      
      if (value != null && (value.abs() > maxSafeInt)) {
        // Convert to closest JS representation manually by rounding
        // or just use the string the compiler suggested.
        // Actually, easiest is to just use the value as is but wrap it or 
        // replace it with the rounded version.
        // The error message from Flutter gives the exact nearest value.
        // Since we are doing this programmatically, we can use double to round it.
        final rounded = value.toDouble().toInt();
        if (rounded.toString() != valueStr) {
          changed = true;
          stdout.writeln('Fixing ${file.path}: $valueStr -> $rounded');
          return 'id: $rounded,';
        }
      }
      return match.group(0)!;
    });

    if (changed) {
      await file.writeAsString(newContent);
    }
  }
}
