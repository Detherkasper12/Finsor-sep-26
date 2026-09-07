import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/screens/auth/auth_callback_screen.dart';

void main() {
  group('AuthCallbackScreen', () {
    test('widget can be instantiated', () {
      const screen = AuthCallbackScreen();
      expect(screen, isNotNull);
    });

    testWidgets('shows error state when Supabase not initialized', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthCallbackScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Back to app'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('back-to-app button is tappable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/auth-callback',
          routes: {
            '/': (_) => const Scaffold(body: Text('Home')),
            '/auth-callback': (_) => const AuthCallbackScreen(),
          },
        ),
      );

      await tester.pumpAndSettle();

      final backBtn = find.text('Back to app');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
