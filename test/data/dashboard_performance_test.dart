import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/repositories/transaction_repository.dart';
import 'package:finsor/models/transaction.dart';

/// Dashboard Performance Tests
/// Validates dashboard renders efficiently with 1000+ transactions
void main() {
  late Directory tempDir;
  late HiveDatabaseService db;
  late TransactionRepository repo;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('dashboard_perf_');
    Hive.init(tempDir.path);
    db = HiveDatabaseService.instance;
    await db.init();
    repo = TransactionRepository(db);
  });

  tearDownAll(() async {
    await db.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Dashboard Performance with 1000 Transactions', () {
    test('should seed 1000 transactions efficiently', () async {
      final random = Random(42);
      final categories = [
        'expense_food',
        'expense_transport',
        'expense_shopping',
        'expense_entertainment',
        'income_salary',
        'income_freelance',
      ];
      final now = DateTime.now();

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        final isExpense = random.nextDouble() > 0.3; // 70% expenses
        await db.addTransaction(Transaction(
          id: 'perf_dashboard_$i',
          amount: (random.nextDouble() * 500 + 10).roundToDouble(),
          type: isExpense ? TransactionType.expense : TransactionType.income,
          categoryId: categories[random.nextInt(categories.length)],
          walletId: 'wallet_default',
          description: 'Dashboard perf test $i',
          createdAt: now.subtract(Duration(days: random.nextInt(60))),
        ));
      }

      stopwatch.stop();
      print('Seeding 1000 transactions: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    test('should compute monthly summary within 100ms', () async {
      final stopwatch = Stopwatch()..start();

      final summary = await repo.getCurrentMonthSummary();

      stopwatch.stop();
      print('Monthly summary computation: ${stopwatch.elapsedMilliseconds}ms');
      print('  Income: \$${summary.income}');
      print('  Expenses: \$${summary.expenses}');
      print('  Balance: \$${summary.balance}');
      print('  Transactions in period: ${summary.totalCount}');

      // Wide threshold for CI stability; target is <100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Monthly summary should compute in <200ms (target: <100ms)');
    });

    // Performance baseline test - wide threshold for CI stability
    test('should compute weekly summary within threshold', () async {
      final stopwatch = Stopwatch()..start();

      final summary = await repo.getCurrentWeekSummary();

      stopwatch.stop();
      print('Weekly summary computation: ${stopwatch.elapsedMilliseconds}ms');
      print('  Transactions in period: ${summary.totalCount}');

      // Wide threshold for CI stability; target is <100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Weekly summary should compute in <200ms (target: <100ms)');
    });

    // Performance baseline test - wide threshold for CI stability
    test('should fetch recent 10 transactions within threshold', () async {
      final stopwatch = Stopwatch()..start();

      final recent = await repo.getRecent(limit: 10);

      stopwatch.stop();
      print('Fetch recent 10: ${stopwatch.elapsedMilliseconds}ms');

      expect(recent.length, equals(10));
      // Wide threshold for CI stability; target is <50ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Recent transactions should load in <100ms (target: <50ms)');
    });

    // Performance baseline test - wide threshold for CI stability
    test('should compute spending by category within threshold', () async {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final stopwatch = Stopwatch()..start();

      final spending = await repo.getSpendingByCategory(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      stopwatch.stop();
      print('Spending by category: ${stopwatch.elapsedMilliseconds}ms');
      print('  Categories with spending: ${spending.length}');

      // Wide threshold for CI stability; target is <100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Spending by category should compute in <200ms (target: <100ms)');
    });

    test('should handle full dashboard data load within 200ms', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate full dashboard load
      final summary = await repo.getCurrentMonthSummary();
      final recent = await repo.getRecent(limit: 10);
      final wallets = await db.getWallets();
      final totalBalance = wallets.fold(0.0, (sum, w) => sum + w.currentBalance);

      stopwatch.stop();
      print('Full dashboard load: ${stopwatch.elapsedMilliseconds}ms');
      print('  Summary: \$${summary.income} income, \$${summary.expenses} expenses');
      print('  Recent transactions: ${recent.length}');
      print('  Total balance: \$${totalBalance.toStringAsFixed(2)}');

      expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Full dashboard data should load within 200ms');
    });

    test('should filter by wallet efficiently', () async {
      final stopwatch = Stopwatch()..start();

      final filteredSummary = await repo.getCurrentMonthSummary(
        walletId: 'wallet_default',
      );
      final filteredRecent = await repo.getRecent(
        limit: 10,
        walletId: 'wallet_default',
      );

      stopwatch.stop();
      print('Filtered dashboard load: ${stopwatch.elapsedMilliseconds}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });

    test('should verify balance integrity after bulk operations', () async {
      final balanceCheck = await db.verifyAllBalances();

      print('Balance verification:');
      for (final entry in balanceCheck.entries) {
        final data = entry.value;
        print('  ${data['name']}: stored=\$${data['stored']}, '
            'computed=\$${data['computed']}, matches=${data['matches']}');
      }

      // All balances should match
      final allMatch = balanceCheck.values.every((v) => v['matches'] == true);
      expect(allMatch, isTrue,
          reason: 'All wallet balances should match computed values');
    });
  });
}
