import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:finsor/main.dart' as app;

/// Critical navigation smoke test.
///
/// Run on a real/simulated target:
///   flutter test integration_test/app_test.dart -d <device_id>
///
/// Required UI is asserted rather than silently skipped. If startup no longer
/// reaches the main application in the debug test configuration, this test must
/// fail and explain which contract changed.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches main app and opens critical navigation destinations',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 15));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Home'), findsWidgets,
        reason: 'Debug startup must reach the main navigation.');
    expect(find.text('Analytics'), findsWidgets);
    expect(find.text('AI'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    await tester.tap(find.text('Analytics').last);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('Analytics'), findsWidgets);

    await tester.tap(find.text('AI').last);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('AI'), findsWidgets);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('Settings'), findsWidgets);

    final menuButton = find.byIcon(Icons.menu);
    expect(menuButton, findsWidgets,
        reason: 'The main shell must expose the application drawer.');
    await tester.tap(menuButton.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Recurring Transactions'), findsOneWidget);
    expect(find.text('Goals & Debts'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Backup'), findsOneWidget);
    expect(find.text('Import / Restore'), findsOneWidget);
  });
}
