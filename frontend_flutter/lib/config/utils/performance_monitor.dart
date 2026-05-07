import 'package:flutter/foundation.dart';

class PerformanceMonitor {
  static Future<void> measureTransition({
    required Future<void> Function() action,
    required String label,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    await action();
    
    stopwatch.stop();
    final durationMs = stopwatch.elapsedMilliseconds;
    
    debugPrint(
      '⏱️ $label: ${durationMs}ms '
      '${durationMs > 350 ? '⚠️ SLOW' : '✅ OK'}',
    );
  }
}
