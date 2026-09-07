import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:finsor/main.dart' as app;

/// Full app crashtest: launch app, open key screens, catch crashes/timeouts.
/// Run: flutter test integration_test/app_test.dart -d chrome
///   or: flutter test integration_test/app_test.dart -d <device_id>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full app crashtest — home, drawer, tabs, settings, AI',
      (WidgetTester tester) async {
    app.main();
    await Future.delayed(const Duration(seconds: 8));
    await tester.pumpAndSettle(const Duration(seconds: 15));

    if (find.byIcon(Icons.menu).evaluate().isEmpty) {
      return;
    }
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final settingsIcon = find.byIcon(Icons.settings);
    if (settingsIcon.evaluate().isNotEmpty) {
      await tester.tap(settingsIcon.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    final aiNav = find.text('AI');
    if (aiNav.evaluate().isNotEmpty) {
      await tester.tap(aiNav);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    final accountsNav = find.text('Accounts');
    if (accountsNav.evaluate().isNotEmpty) {
      await tester.tap(accountsNav);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
