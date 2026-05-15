// E2E integration test - disabled until integration_test package is added to pubspec.yaml
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:integration_test/integration_test.dart';
// import 'package:cadife_smart_travel/main.dart' as app;
// import 'package:cadife_smart_travel/services/api_service.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// void main() {
//   IntegrationTestWidgetsFlutterBinding.ensureInitialized();
//
//   group('Auth Flow E2E Test', () {
//     testWidgets('Login -> Home -> Profile Data Verification', (tester) async {
//       // 1. Start the app
//       app.main();
//       await tester.pumpAndSettle();
//
//       // 2. Verify we are on Login Screen (Looking for 'Smart Travel' text)
//       expect(find.text('Smart Travel'), findsOneWidget);
//
//       // 3. Enter credentials
//       final emailField = find.byKey(const ValueKey('email_field'));
//       final passwordField = find.byKey(const ValueKey('password_field'));
//       final loginButton = find.text('ENTRAR');
//
//       await tester.enterText(emailField, 'test@example.com');
//       await tester.enterText(passwordField, 'password123');
//       await tester.pumpAndSettle();
//
//       // 4. Tap login
//       await tester.tap(loginButton);
//
//       // Wait for navigation and API calls
//       // Note: In a real E2E we would hit the real backend or a mock server.
//       // For this test, we are ensuring the UI transitions and state management work.
//       await tester.pumpAndSettle(const Duration(seconds: 2));
//
//       // 5. Verify navigation to Home (assuming '/home' renders 'Bem-vindo')
//       // and that the current user data is fetched.
//       // expect(find.text('Bem-vindo'), findsOneWidget);
//
//       // 6. Check if token exists in Secure Storage via Provider
//       final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
//       final apiService = container.read(apiServiceProvider);
//       final token = await apiService.getToken();
//
//       expect(token, isNotNull, reason: 'Token should be saved after successful login');
//
//       // 7. Verify Logout
//       // (Navigate to settings and tap logout if implemented)
//     });
//   });
// }

void main() {
  // Placeholder to prevent empty file error
}
