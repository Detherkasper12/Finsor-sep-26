import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsor/constants/app_constants.dart';

/// Basic smoke test for Finsor app
/// Tests that the app can build and render without crashing
void main() {
  testWidgets('App smoke test - renders without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(AppConstants.appName),
            ),
          ),
        ),
      ),
    );

    // Verify the app name is rendered
    expect(find.text(AppConstants.appName), findsOneWidget);
  });

  testWidgets('App structure smoke test', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Finsor'),
                Text('Personal Finance'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Finsor'), findsOneWidget);
    expect(find.text('Personal Finance'), findsOneWidget);
  });
}
