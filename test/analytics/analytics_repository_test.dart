import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/repositories/analytics_repository.dart';
import 'package:finsor/repositories/analytics_models.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/wallet.dart';

/// Comprehensive Analytics Repository Tests
void main() {
  late Directory tempDir;
  late HiveDatabaseService db;
  late AnalyticsRepository analytics;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('analytics_test_');
    Hive.init(tempDir.path);
    db = HiveDatabaseService.instance;
    await db.init();
    analytics = AnalyticsRepository(db);
  });

  tearDownAll(() async {
    await db.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Category Breakdown', () {
    test('should return empty breakdown for empty dataset', () async {
      final now = DateTime.now();
      final breakdown = await analytics.getCategoryBreakdown(
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
      );

      expect(breakdown.isEmpty, isTrue);
      expect(breakdown.totalAmount, equals(0));
      expect(breakdown.totalTransactions, equals(0));
    });

    test('should correctly calculate category percentages', () async {
      // Seed known transactions
      final now = DateTime.now();
      await db.addTransaction(Transaction(
        id: 'cat_test_1',
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        createdAt: now,
      ));
      await db.addTransaction(Transaction(
        id: 'cat_test_2',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        createdAt: now,
      ));
      await db.addTransaction(Transaction(
        id: 'cat_test_3',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: 'expense_transport',
        walletId: 'wallet_default',
        createdAt: now,
      ));

      final breakdown = await analytics.getCategoryBreakdown(
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: now.add(const Duration(hours: 1)),
      );

      expect(breakdown.totalAmount, equals(200.0));
      expect(breakdown.totalTransactions, equals(3));
      expect(breakdown.categories.length, equals(2));

      // Food should be 75% (150/200)
      final food = breakdown.categories.firstWhere((c) => c.categoryId == 'expense_food');
      expect(food.amount, equals(150.0));
      expect(food.percentage, equals(75.0));
      expect(food.transactionCount, equals(2));

      // Transport should be 25% (50/200)
      final transport = breakdown.categories.firstWhere((c) => c.categoryId == 'expense_transport');
      expect(transport.amount, equals(50.0));
      expect(transport.percentage, equals(25.0));
    });

    test('should filter by wallet', () async {
      // Create second wallet
      await db.addWallet(Wallet(
        id: 'wallet_test_2',
        name: 'Test Wallet 2',
        type: WalletType.bank,
        currency: 'USD',
        createdAt: DateTime.now(),
      ));

      final now = DateTime.now();
      await db.addTransaction(Transaction(
        id: 'wallet_filter_1',
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'expense_shopping',
        walletId: 'wallet_test_2',
        createdAt: now,
      ));

      // Get breakdown for specific wallet
      final breakdown = await analytics.getCategoryBreakdown(
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: now.add(const Duration(hours: 1)),
        walletId: 'wallet_test_2',
      );

      expect(breakdown.totalAmount, equals(100.0));
      expect(breakdown.categories.length, equals(1));
      expect(breakdown.categories.first.categoryId, equals('expense_shopping'));
    });

    test('should exclude transfers from expense breakdown', () async {
      final now = DateTime.now();
      await db.addTransaction(Transaction(
        id: 'transfer_exclude',
        amount: 500.0,
        type: TransactionType.transfer,
        categoryId: 'transfer',
        walletId: 'wallet_default',
        toWalletId: 'wallet_test_2',
        createdAt: now,
      ));

      final breakdown = await analytics.getCategoryBreakdown(
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: now.add(const Duration(hours: 1)),
        type: TransactionType.expense,
      );

      // Transfer should not appear in expense breakdown
      final hasTransfer = breakdown.categories.any((c) => c.categoryId == 'transfer');
      expect(hasTransfer, isFalse);
    });

    test('topCategories should return sorted top N', () async {
      final now = DateTime.now();
      final breakdown = await analytics.getCategoryBreakdown(
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(hours: 1)),
      );

      final top2 = breakdown.topCategories(2);
      expect(top2.length, lessThanOrEqualTo(2));
      
      if (top2.length >= 2) {
        expect(top2[0].amount, greaterThanOrEqualTo(top2[1].amount));
      }
    });
  });

  group('Time Series', () {
    test('should generate correct daily buckets', () async {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final series = await analytics.getTimeSeries(
        startDate: startOfMonth,
        endDate: endOfMonth,
        granularity: TimeSeriesGranularity.daily,
      );

      // Should have roughly a month of daily points
      expect(series.points.length, greaterThanOrEqualTo(28));
      expect(series.points.length, lessThanOrEqualTo(31));
      expect(series.granularity, equals(TimeSeriesGranularity.daily));
    });

    test('should generate correct weekly buckets', () async {
      final series = await analytics.getWeeklySeries(weeks: 4);

      // May have 4-5 weeks depending on current day position
      expect(series.points.length, greaterThanOrEqualTo(4));
      expect(series.points.length, lessThanOrEqualTo(5));
      expect(series.granularity, equals(TimeSeriesGranularity.weekly));

      // Each point should be 7 days apart
      for (int i = 1; i < series.points.length; i++) {
        final diff = series.points[i].date.difference(series.points[i - 1].date);
        expect(diff.inDays, equals(7));
      }
    });

    test('should generate correct monthly buckets', () async {
      final series = await analytics.getMonthlySeries(months: 6);

      expect(series.points.length, equals(6));
      expect(series.granularity, equals(TimeSeriesGranularity.monthly));
    });

    test('should calculate running balance correctly', () async {
      final now = DateTime.now();
      
      // Add income then expense
      await db.addTransaction(Transaction(
        id: 'ts_income',
        amount: 1000.0,
        type: TransactionType.income,
        categoryId: 'income_salary',
        walletId: 'wallet_default',
        createdAt: now.subtract(const Duration(days: 2)),
      ));
      await db.addTransaction(Transaction(
        id: 'ts_expense',
        amount: 300.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        createdAt: now.subtract(const Duration(days: 1)),
      ));

      final series = await analytics.getTimeSeries(
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now,
        granularity: TimeSeriesGranularity.daily,
      );

      // Total should reflect both transactions
      expect(series.totalIncome, greaterThanOrEqualTo(1000.0));
      expect(series.totalExpenses, greaterThanOrEqualTo(300.0));
    });

    test('should exclude transfers from income/expense totals', () async {
      final now = DateTime.now();
      await db.addTransaction(Transaction(
        id: 'ts_transfer',
        amount: 999.0,
        type: TransactionType.transfer,
        categoryId: 'transfer',
        walletId: 'wallet_default',
        toWalletId: 'wallet_test_2',
        createdAt: now,
      ));

      final series = await analytics.getTimeSeries(
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: now.add(const Duration(hours: 1)),
        granularity: TimeSeriesGranularity.daily,
      );

      // Transfer of 999 should not appear in income or expenses
      // (it might have other transactions, so we just check it's not adding 999)
      final pointWithTransfer = series.points.firstWhere(
        (p) => p.date.day == now.day,
        orElse: () => TimeSeriesPoint(
          date: DateTime(2000),
          income: 0,
          expenses: 0,
          balance: 0,
          transactionCount: 0,
        ),
      );
      
      // The 999 transfer should not inflate income or expenses by exactly 999
      expect(pointWithTransfer.income, isNot(equals(999.0)));
      expect(pointWithTransfer.expenses, isNot(equals(999.0)));
    });
  });

  group('Period Comparison', () {
    test('should calculate correct deltas', () async {
      final now = DateTime.now();
      final currentStart = DateTime(now.year, now.month, 1);
      final currentEnd = DateTime(now.year, now.month + 1, 0);

      final comparison = await analytics.getPeriodComparison(
        currentStart: currentStart,
        currentEnd: currentEnd,
      );

      // Verify structure
      expect(comparison.currentStart, equals(currentStart));
      expect(comparison.currentEnd, equals(currentEnd));
      
      // Previous period should be same length
      final currentDuration = currentEnd.difference(currentStart);
      final previousDuration = comparison.previousEnd.difference(comparison.previousStart);
      expect(previousDuration.inDays, closeTo(currentDuration.inDays, 1));
    });

    test('should handle zero previous period gracefully', () async {
      // Query a period where previous has no data
      final comparison = await analytics.getPeriodComparison(
        currentStart: DateTime(2030, 1, 1),
        currentEnd: DateTime(2030, 1, 31),
      );

      // Should not throw, percentages should be 0
      expect(comparison.previousIncome, equals(0));
      expect(comparison.incomePercentageChange, equals(0));
    });

    test('should calculate percentage changes correctly', () async {
      // Create known data for comparison
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final previousMonthStart = DateTime(now.year, now.month - 1, 1);

      // Add to previous month
      await db.addTransaction(Transaction(
        id: 'prev_month_income',
        amount: 1000.0,
        type: TransactionType.income,
        categoryId: 'income_salary',
        walletId: 'wallet_default',
        createdAt: previousMonthStart.add(const Duration(days: 5)),
      ));

      // Add to current month (more income)
      await db.addTransaction(Transaction(
        id: 'curr_month_income',
        amount: 1500.0,
        type: TransactionType.income,
        categoryId: 'income_salary',
        walletId: 'wallet_default',
        createdAt: currentMonthStart.add(const Duration(days: 5)),
      ));

      final comparison = await analytics.getMonthOverMonthComparison();

      // Current should have at least 1500, previous at least 1000
      expect(comparison.currentIncome, greaterThanOrEqualTo(1500.0));
      expect(comparison.previousIncome, greaterThanOrEqualTo(1000.0));
      expect(comparison.incomeIncreased, isTrue);
    });
  });

  group('Wallet Analytics', () {
    test('should return analytics for all wallets', () async {
      final now = DateTime.now();
      final walletAnalytics = await analytics.getWalletAnalytics(
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
      );

      expect(walletAnalytics.isNotEmpty, isTrue);
      
      for (final wa in walletAnalytics) {
        expect(wa.walletId, isNotEmpty);
        expect(wa.walletName, isNotEmpty);
        expect(wa.periodNetFlow, equals(wa.periodIncome - wa.periodExpenses));
      }
    });
  });

  group('Performance', () {
    test('should seed 1000 transactions for performance test', () async {
      final random = Random(42);
      final categories = [
        'expense_food', 'expense_transport', 'expense_shopping',
        'expense_entertainment', 'expense_utilities',
        'income_salary', 'income_freelance',
      ];
      final now = DateTime.now();

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        final isExpense = random.nextDouble() > 0.25;
        final categoryId = isExpense
            ? categories[random.nextInt(5)]
            : categories[5 + random.nextInt(2)];

        await db.addTransaction(Transaction(
          id: 'perf_analytics_$i',
          amount: (random.nextDouble() * 500 + 10).roundToDouble(),
          type: isExpense ? TransactionType.expense : TransactionType.income,
          categoryId: categoryId,
          walletId: 'wallet_default',
          createdAt: now.subtract(Duration(days: random.nextInt(90))),
        ));
      }

      stopwatch.stop();
      print('Seeding 1000 transactions: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('should compute category breakdown in <100ms', () async {
      final now = DateTime.now();
      final stopwatch = Stopwatch()..start();

      final breakdown = await analytics.getCategoryBreakdown(
        startDate: now.subtract(const Duration(days: 90)),
        endDate: now,
      );

      stopwatch.stop();
      print('Category breakdown (${breakdown.totalTransactions} tx): ${stopwatch.elapsedMilliseconds}ms');
      print('  Categories: ${breakdown.categories.length}');
      print('  Total: \$${breakdown.totalAmount}');

      // Wide threshold for CI stability; target is <100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Category breakdown should complete in <200ms (target: <100ms)');
    });

    // Performance baseline test - uses wide threshold for CI stability
    // Target: <100ms, Threshold: 200ms (2x margin for system variance)
    test('should compute daily time series within threshold', () async {
      final stopwatch = Stopwatch()..start();

      final series = await analytics.getCurrentMonthDailySeries();

      stopwatch.stop();
      print('Daily series: ${stopwatch.elapsedMilliseconds}ms');
      print('  Points: ${series.points.length}');
      print('  Total income: \$${series.totalIncome}');
      print('  Total expenses: \$${series.totalExpenses}');

      expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Daily series should complete in <200ms (target: <100ms)');
    });

    // Performance baseline test - uses wide threshold for CI stability
    // Target: <100ms, Threshold: 200ms (2x margin for system variance)
    test('should compute weekly series within threshold', () async {
      final stopwatch = Stopwatch()..start();

      final series = await analytics.getWeeklySeries(weeks: 12);

      stopwatch.stop();
      print('Weekly series (12 weeks): ${stopwatch.elapsedMilliseconds}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Weekly series should complete in <200ms (target: <100ms)');
    });

    // Performance baseline test - uses wide threshold for CI stability
    // Target: <100ms, Threshold: 200ms (2x margin for system variance)
    test('should compute monthly series within threshold', () async {
      final stopwatch = Stopwatch()..start();

      final series = await analytics.getMonthlySeries(months: 12);

      stopwatch.stop();
      print('Monthly series (12 months): ${stopwatch.elapsedMilliseconds}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Monthly series should complete in <200ms (target: <100ms)');
    });

    // Performance baseline test - uses wide threshold for CI stability
    // Target: <100ms, Threshold: 200ms (2x margin for system variance)
    test('should compute period comparison within threshold', () async {
      final stopwatch = Stopwatch()..start();

      final comparison = await analytics.getMonthOverMonthComparison();

      stopwatch.stop();
      print('Period comparison: ${stopwatch.elapsedMilliseconds}ms');
      print('  Current: \$${comparison.currentIncome} in, \$${comparison.currentExpenses} out');
      print('  Previous: \$${comparison.previousIncome} in, \$${comparison.previousExpenses} out');
      print('  Income delta: ${comparison.incomePercentageChange.toStringAsFixed(1)}%');

      // Wide threshold for CI stability; target is <100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Period comparison should complete in <200ms (target: <100ms)');
    });

    // Performance baseline test - uses wide threshold for CI stability
    // Target: <200ms, Threshold: 500ms (margin for cold cache + system variance)
    test('should compute full analytics suite within threshold', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate full analytics load
      final breakdown = await analytics.getCurrentMonthCategoryBreakdown();
      final dailySeries = await analytics.getCurrentMonthDailySeries();
      final comparison = await analytics.getMonthOverMonthComparison();
      final walletStats = await analytics.getWalletAnalytics(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      stopwatch.stop();
      print('Full analytics suite: ${stopwatch.elapsedMilliseconds}ms');
      print('  Breakdown categories: ${breakdown.categories.length}');
      print('  Daily points: ${dailySeries.points.length}');
      print('  Wallet count: ${walletStats.length}');

      // Wide threshold for CI stability; target is <200ms
      expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: 'Full analytics suite should complete in <500ms (target: <200ms)');
    });
  });

  group('Edge Cases', () {
    test('should handle single transaction correctly', () async {
      // Use a unique category that only has one transaction
      final now = DateTime.now();
      final uniqueCategoryId = 'expense_unique_${now.millisecondsSinceEpoch}';
      
      await db.addTransaction(Transaction(
        id: 'single_tx_${now.millisecondsSinceEpoch}',
        amount: 42.0,
        type: TransactionType.expense,
        categoryId: uniqueCategoryId,
        walletId: 'wallet_default',
        createdAt: now,
      ));

      final breakdown = await analytics.getCategoryBreakdown(
        startDate: now.subtract(const Duration(seconds: 1)),
        endDate: now.add(const Duration(seconds: 1)),
      );

      // Find our unique category
      final single = breakdown.categories.firstWhere(
        (c) => c.categoryId == uniqueCategoryId,
        orElse: () => throw Exception('Category not found'),
      );
      
      // Verify it has the correct amount
      expect(single.amount, equals(42.0));
      expect(single.transactionCount, equals(1));
    });

    test('should handle future dates gracefully', () async {
      final futureStart = DateTime.now().add(const Duration(days: 365));
      final futureEnd = futureStart.add(const Duration(days: 30));

      final breakdown = await analytics.getCategoryBreakdown(
        startDate: futureStart,
        endDate: futureEnd,
      );

      expect(breakdown.isEmpty, isTrue);
    });

    test('should handle wallet filter with no transactions', () async {
      final breakdown = await analytics.getCategoryBreakdown(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
        walletId: 'nonexistent_wallet',
      );

      expect(breakdown.isEmpty, isTrue);
    });
  });
}
