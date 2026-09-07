import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsor/screens/onboarding/onboarding_screen.dart';
import 'package:finsor/screens/export/export_screen.dart';
import 'package:finsor/screens/legal/about_screen.dart';
import 'package:finsor/screens/legal/privacy_policy_screen.dart';
import 'package:finsor/screens/legal/terms_screen.dart';
import 'package:finsor/screens/premium/premium_screen.dart';
import 'package:finsor/services/export_service.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/wallet.dart';
import 'package:finsor/models/category.dart' as models;
import 'package:finsor/providers/premium_provider.dart';
import 'package:finsor/premium/premium_features.dart';
import 'package:finsor/services/iap_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  IapService.enableTestMode();

  group('Onboarding Tests', () {
    testWidgets('renders onboarding screen with all pages', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );

      expect(find.text('Welcome to Finsor'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('can navigate through pages', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );

      expect(find.text('Welcome to Finsor'), findsOneWidget);

      // Tap continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Track Expenses & Income'), findsOneWidget);
    });

    testWidgets('last page shows Get Started button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );

      // Navigate to last page
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Gain Insights'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });
  });

  group('Export Service Tests', () {
    test('exports transactions to CSV with correct headers', () {
      final transactions = [
        Transaction(
          id: 't1',
          amount: 100.0,
          type: TransactionType.expense,
          categoryId: 'cat1',
          walletId: 'wallet1',
          description: 'Test expense',
          createdAt: DateTime(2026, 2, 1, 10, 30),
          updatedAt: DateTime(2026, 2, 1, 10, 30),
        ),
        Transaction(
          id: 't2',
          amount: 500.0,
          type: TransactionType.income,
          categoryId: 'cat2',
          walletId: 'wallet1',
          description: 'Test income',
          createdAt: DateTime(2026, 2, 2, 14, 0),
          updatedAt: DateTime(2026, 2, 2, 14, 0),
        ),
      ];

      final wallets = [
        Wallet(
          id: 'wallet1',
          name: 'Main Wallet',
          type: WalletType.cash,
          currency: 'USD',
          initialBalance: 0,
          currentBalance: 400,
          createdAt: DateTime.now(),
        ),
      ];

      final categories = [
        models.Category(
          id: 'cat1',
          name: 'Food',
          type: TransactionType.expense,
          color: '#FF0000',
          iconName: 'restaurant',
          createdAt: DateTime.now(),
        ),
        models.Category(
          id: 'cat2',
          name: 'Salary',
          type: TransactionType.income,
          color: '#00FF00',
          iconName: 'work',
          createdAt: DateTime.now(),
        ),
      ];

      final result = ExportService.exportTransactionsToCsv(
        transactions: transactions,
        wallets: wallets,
        categories: categories,
      );

      expect(result.transactionCount, 2);
      expect(result.csv.contains('Date,Type,Amount,Category,Wallet,Description'), isTrue);
      expect(result.csv.contains('EXPENSE'), isTrue);
      expect(result.csv.contains('INCOME'), isTrue);
      expect(result.csv.contains('Food'), isTrue);
      expect(result.csv.contains('Salary'), isTrue);
      expect(result.csv.contains('Main Wallet'), isTrue);
    });

    test('filters transactions by date range', () {
      final transactions = [
        Transaction(
          id: 't1',
          amount: 100.0,
          type: TransactionType.expense,
          categoryId: 'cat1',
          walletId: 'wallet1',
          createdAt: DateTime(2026, 1, 15),
          updatedAt: DateTime(2026, 1, 15),
        ),
        Transaction(
          id: 't2',
          amount: 200.0,
          type: TransactionType.expense,
          categoryId: 'cat1',
          walletId: 'wallet1',
          createdAt: DateTime(2026, 2, 15),
          updatedAt: DateTime(2026, 2, 15),
        ),
      ];

      final result = ExportService.exportTransactionsToCsv(
        transactions: transactions,
        wallets: [],
        categories: [],
        options: ExportOptions(
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 28),
        ),
      );

      expect(result.transactionCount, 1);
    });

    test('escapes CSV special characters', () {
      final transactions = [
        Transaction(
          id: 't1',
          amount: 100.0,
          type: TransactionType.expense,
          categoryId: 'cat1',
          walletId: 'wallet1',
          description: 'Test, with comma',
          createdAt: DateTime(2026, 2, 1),
          updatedAt: DateTime(2026, 2, 1),
        ),
      ];

      final result = ExportService.exportTransactionsToCsv(
        transactions: transactions,
        wallets: [],
        categories: [],
      );

      expect(result.csv.contains('"Test, with comma"'), isTrue);
    });
  });

  group('Premium Gating Tests', () {
    tearDown(() => IapService.disableTestMode());

    test('free user cannot access export feature', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isLocked = container.read(isFeatureLockedProvider(PremiumFeature.exportData));
      expect(isLocked, isTrue);
    });

    test('premium user can access export feature', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(premiumStateProvider.notifier).togglePremium();
      final isLocked = container.read(isFeatureLockedProvider(PremiumFeature.exportData));
      expect(isLocked, isFalse);
    });

    test('premium state toggle works correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isPremiumProvider), isFalse);

      container.read(premiumStateProvider.notifier).togglePremium();
      expect(container.read(isPremiumProvider), isTrue);

      container.read(premiumStateProvider.notifier).togglePremium();
      expect(container.read(isPremiumProvider), isFalse);
    });
  });

  group('Legal Screens Tests', () {
    testWidgets('About screen renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AboutScreen()),
      );

      expect(find.text('About Finsor'), findsOneWidget);
      expect(find.textContaining('Version'), findsOneWidget);
    });

    testWidgets('Privacy Policy screen renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PrivacyPolicyScreen()),
      );

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Data Collection'), findsOneWidget);
      expect(find.text('Data Storage'), findsOneWidget);
    });

    testWidgets('Terms screen renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TermsScreen()),
      );

      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.text('Acceptance of Terms'), findsOneWidget);
    });
  });

  group('Dev Mode UI Tests', () {
    test('kDebugMode is true in test environment', () {
      // This confirms tests run in debug mode
      // In release builds, kDebugMode will be false
      expect(kDebugMode, isTrue);
    });
  });

  group('Premium Screen Tests', () {
    testWidgets('renders premium screen correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PremiumScreen()),
        ),
      );

      // Should show paywall content for free users
      expect(find.textContaining('Premium'), findsWidgets);
    });
  });

  group('Export Screen Tests', () {
    testWidgets('export screen shows locked state for free users', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ExportScreen()),
        ),
      );

      // Should show premium locked card
      expect(find.textContaining('Premium'), findsWidgets);
    });
  });
}
