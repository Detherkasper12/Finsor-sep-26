import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsor/screens/auth/reset_password_screen.dart';

void main() {
  group('ResetPasswordScreen (Sprint 19.1)', () {
    testWidgets('instantiates and shows set new password UI', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ResetPasswordScreen(),
          ),
        ),
      );
      expect(find.text('Set new password'), findsOneWidget);
      expect(find.text('Choose a new password'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Update password'), findsOneWidget);
    });
  });
}
