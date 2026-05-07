import 'package:cadife_smart_travel/features/notifications/application/providers/notification_providers.dart';
import 'package:cadife_smart_travel/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe badge com contador quando há não lidas', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadCountStreamProvider.overrideWith(
            (ref) => Stream.value(3),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NotificationBell(),
          ),
        ),
      ),
    );
    
    await tester.pump();
    
    expect(find.text('3'), findsOneWidget);
  });
  
  testWidgets('não exibe badge quando unreadCount = 0', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadCountStreamProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NotificationBell(),
          ),
        ),
      ),
    );
    
    await tester.pump();
    
    expect(find.text('0'), findsNothing);
  });
}
