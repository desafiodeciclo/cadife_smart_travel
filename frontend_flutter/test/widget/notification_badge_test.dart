import 'package:cadife_smart_travel/widgets/notification_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationBadge', () {
    testWidgets('renders correctly without unread messages', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBadge(
              unreadCount: 0,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      // The badge container is only rendered if unreadCount > 0
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('shows correct count when unreadCount > 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBadge(
              unreadCount: 5,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows 9+ when unreadCount > 9', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBadge(
              unreadCount: 15,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('triggers onTap when clicked', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBadge(
              unreadCount: 0,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      expect(tapped, isTrue);
    });
  });
}
