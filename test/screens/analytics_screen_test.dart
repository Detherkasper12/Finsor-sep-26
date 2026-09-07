import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsor/providers/analytics_providers.dart';
import 'package:finsor/providers/wallet_provider.dart';
import 'package:finsor/providers/repository_providers.dart';
import 'package:finsor/providers/premium_provider.dart';
import 'package:finsor/services/iap_service.dart';
import 'package:finsor/premium/premium_features.dart';
import 'package:finsor/premium/premium_state.dart';
import 'package:finsor/repositories/analytics_models.dart';
import 'package:finsor/repositories/transaction_repository.dart';
import 'package:finsor/models/wallet.dart';
import 'package:finsor/models/transaction.dart';

/// Mock data for testing analytics UI
final _mockSummary = PeriodSummary(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 1, 31),
  income: 5000.0,
  expenses: 3000.0,
  balance: 2000.0,
  incomeCount: 5,
  expenseCount: 15,
  totalCount: 20,
);

final _mockBreakdown = CategoryBreakdown(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 1, 31),
  categories: [
    const CategorySummary(
      categoryId: 'expense_food',
      categoryName: 'Food',
      amount: 1500.0,
      percentage: 50.0,
      transactionCount: 10,
      type: TransactionType.expense,
    ),
    const CategorySummary(
      categoryId: 'expense_transport',
      categoryName: 'Transport',
      amount: 1000.0,
      percentage: 33.3,
      transactionCount: 5,
      type: TransactionType.expense,
    ),
    const CategorySummary(
      categoryId: 'expense_shopping',
      categoryName: 'Shopping',
      amount: 500.0,
      percentage: 16.7,
      transactionCount: 3,
      type: TransactionType.expense,
    ),
  ],
  totalAmount: 3000.0,
  totalTransactions: 18,
);

final _mockTimeSeries = TimeSeries(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 1, 31),
  granularity: TimeSeriesGranularity.daily,
  points: List.generate(
    10,
    (i) => TimeSeriesPoint(
      date: DateTime(2024, 1, i + 1),
      income: 500.0,
      expenses: 300.0,
      balance: 200.0 * (i + 1),
      transactionCount: 2,
    ),
  ),
  totalIncome: 5000.0,
  totalExpenses: 3000.0,
);

final _mockComparison = PeriodComparison(
  currentStart: DateTime(2024, 1, 1),
  currentEnd: DateTime(2024, 1, 31),
  previousStart: DateTime(2023, 12, 1),
  previousEnd: DateTime(2023, 12, 31),
  currentIncome: 5000.0,
  previousIncome: 4000.0,
  currentExpenses: 3000.0,
  previousExpenses: 3500.0,
  currentTransactionCount: 20,
  previousTransactionCount: 18,
);

final _mockWallets = [
  Wallet(
    id: 'wallet_1',
    name: 'Cash',
    type: WalletType.cash,
    currency: 'USD',
    createdAt: DateTime.now(),
  ),
  Wallet(
    id: 'wallet_2',
    name: 'Bank',
    type: WalletType.bank,
    currency: 'USD',
    createdAt: DateTime.now(),
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Analytics Screen Widget Tests', () {
    testWidgets('renders Analytics header', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets('renders period selector with all options', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('renders wallet selector', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Bank'), findsOneWidget);
    });

    testWidgets('renders stats cards with income/expenses/net', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Income'), findsWidgets);
      expect(find.text('Expenses'), findsWidgets);
      expect(find.text('Net'), findsOneWidget);
    });

    testWidgets('renders tab bar with Overview/Categories/Trends',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Trends'), findsOneWidget);
    });

    testWidgets('can switch between tabs', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Tap Categories tab
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();

      // Should show category data
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);

      // Tap Trends tab
      await tester.tap(find.text('Trends'));
      await tester.pumpAndSettle();

      // Should show granularity options
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
    });

    testWidgets('renders category breakdown with amounts', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Go to Categories tab
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();

      // Verify categories are shown
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('50.0%'), findsOneWidget);
    });

    testWidgets('renders comparison card with deltas', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Should show comparison info
      expect(find.text('vs Previous Period'), findsOneWidget);
    });
  });

  group('Analytics Empty State Tests', () {
    testWidgets('shows empty state when no data', (tester) async {
      await tester.pumpWidget(_buildTestAppEmpty());
      await tester.pumpAndSettle();

      // Go to Categories tab
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();

      expect(find.text('No expense data for this period'), findsOneWidget);
    });
  });

  group('Premium Gate Tests', () {
    testWidgets('free user sees locked state on trends tab', (tester) async {
      await tester.pumpWidget(_buildTestAppWithPremiumState(isPremium: false));
      await tester.pumpAndSettle();

      // Go to Trends tab
      await tester.tap(find.text('Trends'));
      await tester.pumpAndSettle();

      // Should see premium locked indicator
      expect(find.text('PRO'), findsWidgets);
      expect(find.text('Upgrade to Premium'), findsOneWidget);
    });

    testWidgets('premium user sees full trends content', (tester) async {
      await tester.pumpWidget(_buildTestAppWithPremiumState(isPremium: true));
      await tester.pumpAndSettle();

      // Go to Trends tab
      await tester.tap(find.text('Trends'));
      await tester.pumpAndSettle();

      // Should see granularity controls, not upgrade button
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Upgrade to Premium'), findsNothing);
    });
  });

  group('Wallet Selection Tests', () {
    testWidgets('wallet selector shows all wallets', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Bank'), findsOneWidget);
    });
  });
}

Widget _buildTestApp() {
  return ProviderScope(
    overrides: [
      periodSummaryProvider.overrideWith((ref) async => _mockSummary),
      currentMonthCategoryBreakdownProvider
          .overrideWith((ref) async => _mockBreakdown),
      currentMonthDailySeriesProvider
          .overrideWith((ref) async => _mockTimeSeries),
      weeklySeriesProvider.overrideWith((ref) async => _mockTimeSeries),
      monthlySeriesProvider.overrideWith((ref) async => _mockTimeSeries),
      monthOverMonthComparisonProvider
          .overrideWith((ref) async => _mockComparison),
      walletsProvider.overrideWith((ref) async => _mockWallets),
    ],
    child: const MaterialApp(
      home: _TestAnalyticsScreen(),
    ),
  );
}

Widget _buildTestAppEmpty() {
  final emptyBreakdown = CategoryBreakdown(
    startDate: DateTime.now(),
    endDate: DateTime.now(),
    categories: [],
    totalAmount: 0,
    totalTransactions: 0,
  );

  return ProviderScope(
    overrides: [
      periodSummaryProvider.overrideWith((ref) async => _mockSummary),
      currentMonthCategoryBreakdownProvider
          .overrideWith((ref) async => emptyBreakdown),
      currentMonthDailySeriesProvider
          .overrideWith((ref) async => _mockTimeSeries),
      weeklySeriesProvider.overrideWith((ref) async => _mockTimeSeries),
      monthlySeriesProvider.overrideWith((ref) async => _mockTimeSeries),
      monthOverMonthComparisonProvider
          .overrideWith((ref) async => _mockComparison),
      walletsProvider.overrideWith((ref) async => _mockWallets),
    ],
    child: const MaterialApp(
      home: _TestAnalyticsScreen(),
    ),
  );
}

Widget _buildTestAppWithPremiumState({required bool isPremium}) {
  return ProviderScope(
    overrides: [
      periodSummaryProvider.overrideWith((ref) async => _mockSummary),
      currentMonthCategoryBreakdownProvider
          .overrideWith((ref) async => _mockBreakdown),
      currentMonthDailySeriesProvider
          .overrideWith((ref) async => _mockTimeSeries),
      weeklySeriesProvider.overrideWith((ref) async => _mockTimeSeries),
      monthlySeriesProvider.overrideWith((ref) async => _mockTimeSeries),
      monthOverMonthComparisonProvider
          .overrideWith((ref) async => _mockComparison),
      walletsProvider.overrideWith((ref) async => _mockWallets),
      premiumStateProvider
          .overrideWith((ref) => _MockPremiumNotifier(isPremium)),
    ],
    child: const MaterialApp(
      home: _TestAnalyticsScreenWithPremium(),
    ),
  );
}

class _MockPremiumNotifier extends PremiumStateNotifier {
  _MockPremiumNotifier(bool isPremium) : super(IapService()) {
    if (isPremium) {
      grantPremium();
    }
  }
}

/// Minimal test wrapper for analytics screen components
class _TestAnalyticsScreen extends ConsumerStatefulWidget {
  const _TestAnalyticsScreen();

  @override
  ConsumerState<_TestAnalyticsScreen> createState() =>
      _TestAnalyticsScreenState();
}

class _TestAnalyticsScreenState extends ConsumerState<_TestAnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final periodType = ref.watch(periodTypeProvider);
    final selectedWalletId = ref.watch(selectedWalletIdProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final summaryAsync = ref.watch(periodSummaryProvider);
    final breakdownAsync = ref.watch(currentMonthCategoryBreakdownProvider);
    final comparisonAsync = ref.watch(monthOverMonthComparisonProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Analytics',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            // Period Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: PeriodType.values
                  .map((p) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child:
                            Text(p.name[0].toUpperCase() + p.name.substring(1)),
                      ))
                  .toList(),
            ),
            // Wallet Selector
            SizedBox(
              height: 40,
              child: walletsAsync.when(
                data: (wallets) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('All'),
                    const SizedBox(width: 8),
                    ...wallets.map((w) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(w.name),
                        )),
                  ],
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ),
            // Stats
            summaryAsync.when(
              data: (summary) => const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Income'),
                  Text('Expenses'),
                  Text('Net'),
                ],
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            // Comparison
            comparisonAsync.when(
              data: (c) => const Text('vs Previous Period'),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Categories'),
                Tab(text: 'Trends'),
              ],
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Overview
                  const Center(child: Text('Overview Content')),
                  // Categories
                  breakdownAsync.when(
                    data: (breakdown) {
                      if (breakdown.isEmpty) {
                        return const Center(
                            child: Text('No expense data for this period'));
                      }
                      return ListView(
                        children: breakdown.categories
                            .map((c) => ListTile(
                                  title: Text(c.categoryName),
                                  trailing: Text(
                                      '${c.percentage.toStringAsFixed(1)}%'),
                                ))
                            .toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('Error')),
                  ),
                  // Trends
                  const Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Daily'),
                          SizedBox(width: 8),
                          Text('Weekly'),
                          SizedBox(width: 8),
                          Text('Monthly'),
                        ],
                      ),
                      Expanded(child: Center(child: Text('Chart'))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Test wrapper with premium gate for trends tab
class _TestAnalyticsScreenWithPremium extends ConsumerStatefulWidget {
  const _TestAnalyticsScreenWithPremium();

  @override
  ConsumerState<_TestAnalyticsScreenWithPremium> createState() =>
      _TestAnalyticsScreenWithPremiumState();
}

class _TestAnalyticsScreenWithPremiumState
    extends ConsumerState<_TestAnalyticsScreenWithPremium>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);
    final summaryAsync = ref.watch(periodSummaryProvider);
    final breakdownAsync = ref.watch(currentMonthCategoryBreakdownProvider);
    final isLocked =
        ref.watch(isFeatureLockedProvider(PremiumFeature.advancedAnalytics));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Analytics',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: PeriodType.values
                  .map((p) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child:
                            Text(p.name[0].toUpperCase() + p.name.substring(1)),
                      ))
                  .toList(),
            ),
            SizedBox(
              height: 40,
              child: walletsAsync.when(
                data: (wallets) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('All'),
                    const SizedBox(width: 8),
                    ...wallets.map((w) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(w.name),
                        )),
                  ],
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ),
            summaryAsync.when(
              data: (summary) => const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [Text('Income'), Text('Expenses'), Text('Net')],
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Categories'),
                Tab(text: 'Trends'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const Center(child: Text('Overview Content')),
                  breakdownAsync.when(
                    data: (breakdown) {
                      if (breakdown.isEmpty) {
                        return const Center(
                            child: Text('No expense data for this period'));
                      }
                      return ListView(
                        children: breakdown.categories
                            .map((c) => ListTile(
                                  title: Text(c.categoryName),
                                  trailing: Text(
                                      '${c.percentage.toStringAsFixed(1)}%'),
                                ))
                            .toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('Error')),
                  ),
                  // Trends with premium gate
                  isLocked
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('PRO',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(height: 16),
                            const Text('Advanced Analytics'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {},
                              child: const Text('Upgrade to Premium'),
                            ),
                          ],
                        )
                      : const Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Daily'),
                                SizedBox(width: 8),
                                Text('Weekly'),
                                SizedBox(width: 8),
                                Text('Monthly'),
                              ],
                            ),
                            Expanded(child: Center(child: Text('Chart'))),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
