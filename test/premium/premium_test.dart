import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsor/providers/premium_provider.dart';
import 'package:finsor/premium/premium_features.dart';
import 'package:finsor/premium/premium_state.dart';
import 'package:finsor/services/iap_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Premium State Tests', () {
    test('free tier has no premium features', () {
      const state = PremiumState.free;
      expect(state.isPremium, isFalse);
      expect(state.enabledFeatures, isEmpty);
    });

    test('full premium has all features', () {
      final state = PremiumState.fullPremium();
      expect(state.isPremium, isTrue);
      expect(state.enabledFeatures, equals(premiumFeatures));
    });

    test('isFeatureLocked returns true for gated features on free', () {
      const state = PremiumState.free;
      expect(state.isFeatureLocked(PremiumFeature.advancedAnalytics), isTrue);
      expect(state.isFeatureLocked(PremiumFeature.aiInsights), isTrue);
    });

    test('isFeatureLocked returns false for premium users', () {
      final state = PremiumState.fullPremium();
      expect(state.isFeatureLocked(PremiumFeature.advancedAnalytics), isFalse);
      expect(state.isFeatureLocked(PremiumFeature.aiInsights), isFalse);
    });

    test('expired premium is not effectively premium', () {
      final expiredState = PremiumState(
        isPremium: true,
        enabledFeatures: premiumFeatures,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expiredState.isExpired, isTrue);
      expect(expiredState.isEffectivelyPremium, isFalse);
    });

    test('valid premium is effectively premium', () {
      final validState = PremiumState(
        isPremium: true,
        enabledFeatures: premiumFeatures,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      expect(validState.isExpired, isFalse);
      expect(validState.isEffectivelyPremium, isTrue);
    });
  });

  group('Premium Provider Tests', () {
    testWidgets('isPremiumProvider returns false by default', (tester) async {
      bool? isPremium;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              isPremium = ref.watch(isPremiumProvider);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isPremium, isFalse);
    });

    testWidgets('isFeatureLockedProvider returns true for gated features', (tester) async {
      bool? isLocked;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              isLocked = ref.watch(isFeatureLockedProvider(PremiumFeature.advancedAnalytics));
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isLocked, isTrue);
    });

    test('PremiumStateNotifier togglePremium changes state', () {
      final notifier = PremiumStateNotifier(IapService());
      
      expect(notifier.state.isPremium, isFalse);
      
      notifier.togglePremium();
      expect(notifier.state.isPremium, isTrue);
      
      notifier.togglePremium();
      expect(notifier.state.isPremium, isFalse);
    });
  });

  group('Premium Feature Info Tests', () {
    test('all features have info', () {
      for (final feature in PremiumFeature.values) {
        final info = PremiumFeatureInfo.getInfo(feature);
        expect(info.title, isNotEmpty);
        expect(info.description, isNotEmpty);
        expect(info.iconName, isNotEmpty);
      }
    });
  });

  group('Premium Screen Widget Tests', () {
    testWidgets('paywall renders for free users', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                final isPremium = ref.watch(isPremiumProvider);
                return Scaffold(
                  body: isPremium
                      ? const Text('Premium Active')
                      : const Column(
                          children: [
                            Text('FINSOR PREMIUM'),
                            Text('Upgrade to Premium'),
                            Text('Restore Purchases'),
                          ],
                        ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('FINSOR PREMIUM'), findsOneWidget);
      expect(find.text('Upgrade to Premium'), findsOneWidget);
      expect(find.text('Restore Purchases'), findsOneWidget);
    });

    testWidgets('premium active shows for premium users', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            premiumStateProvider.overrideWith((ref) => _MockPremiumNotifier()),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                final isPremium = ref.watch(isPremiumProvider);
                return Scaffold(
                  body: isPremium
                      ? const Text('Premium Active')
                      : const Text('Not Premium'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Premium Active'), findsOneWidget);
    });
  });

  group('Feature Gating Tests', () {
    testWidgets('gated content shows locked for free users', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                final isLocked = ref.watch(
                  isFeatureLockedProvider(PremiumFeature.advancedAnalytics),
                );
                return Scaffold(
                  body: isLocked
                      ? const Text('Feature Locked')
                      : const Text('Feature Unlocked'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Feature Locked'), findsOneWidget);
    });

    testWidgets('gated content shows unlocked for premium users', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            premiumStateProvider.overrideWith((ref) => _MockPremiumNotifier()),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                final isLocked = ref.watch(
                  isFeatureLockedProvider(PremiumFeature.advancedAnalytics),
                );
                return Scaffold(
                  body: isLocked
                      ? const Text('Feature Locked')
                      : const Text('Feature Unlocked'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Feature Unlocked'), findsOneWidget);
    });
  });
}

class _MockPremiumNotifier extends PremiumStateNotifier {
  _MockPremiumNotifier() : super(IapService()) {
    grantPremium();
  }
}
