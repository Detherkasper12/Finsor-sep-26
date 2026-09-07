import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/premium/premium_features.dart';
import 'package:finsor/providers/insights_providers.dart';
import 'package:finsor/providers/premium_provider.dart';
import 'package:finsor/screens/insights/insights_screen.dart';

void main() {
  group('InsightsScreen error boundary', () {
    testWidgets('shows friendly error UI when insights fail - does not crash', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFeatureLockedProvider(PremiumFeature.aiInsights).overrideWith((ref) => false),
            insightsProvider.overrideWith((ref) => Future.error(Exception('Simulated failure'))),
          ],
          child: MaterialApp(
            home: const InsightsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not load insights'), findsOneWidget);
    });
  });
}
