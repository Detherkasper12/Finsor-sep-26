import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/premium/premium_features.dart';
import 'package:finsor/providers/insights_providers.dart';
import 'package:finsor/providers/premium_provider.dart';
import 'package:finsor/screens/insights/insights_screen.dart';
import 'package:finsor/services/insights_service.dart';

void main() {
  group('InsightsScreen', () {
    testWidgets('shows locked card when free user', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFeatureLockedProvider(PremiumFeature.aiInsights).overrideWith((ref) => true),
          ],
          child: MaterialApp(
            home: const InsightsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Upgrade to Premium'), findsOneWidget);
    });

    testWidgets('shows insights content when premium', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isFeatureLockedProvider(PremiumFeature.aiInsights).overrideWith((ref) => false),
            insightsProvider.overrideWith((ref) => Future.value([
              const Insight(text: 'Test insight.', impactScore: 1, reason: 'Test reason', category: 'test'),
            ])),
          ],
          child: MaterialApp(
            home: const InsightsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Test insight.'), findsOneWidget);
    });
  });
}
