import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/wallet.dart';
import 'package:finsor/repositories/analytics_repository.dart';
import 'package:finsor/repositories/transaction_repository.dart';

void main() {
  late HiveDatabaseService db;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_edit_inv_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    await Hive.deleteFromDisk();
    Hive.init(tempDir.path);
    db = HiveDatabaseService.instance;
    await db.init();
  });

  tearDown(() async {
    await db.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Transaction edit invalidation', () {
    late Wallet walletX;
    late Wallet walletY;

    setUp(() async {
      walletX = Wallet(
        id: 'wallet_inv_x',
        name: 'Wallet X',
        type: WalletType.cash,
        currency: 'USD',
        initialBalance: 1000.0,
        currentBalance: 1000.0,
        createdAt: DateTime.now(),
      );
      walletY = Wallet(
        id: 'wallet_inv_y',
        name: 'Wallet Y',
        type: WalletType.bank,
        currency: 'USD',
        initialBalance: 500.0,
        currentBalance: 500.0,
        createdAt: DateTime.now(),
      );
      await db.addWallet(walletX);
      await db.addWallet(walletY);
    });

    test('Edit wallet change updates both old and new wallet balances', () async {
      // Add expense to walletX
      await db.addTransaction(Transaction(
        id: 'tx_inv_wallet',
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: walletX.id,
        createdAt: DateTime.now(),
      ));

      var x = await db.getWallet(walletX.id);
      expect(x!.currentBalance, equals(900.0));

      // Edit: move transaction to walletY
      await db.updateTransaction(Transaction(
        id: 'tx_inv_wallet',
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: walletY.id,
        createdAt: DateTime.now(),
      ));

      x = await db.getWallet(walletX.id);
      final y = await db.getWallet(walletY.id);
      expect(x!.currentBalance, equals(1000.0)); // restored
      expect(y!.currentBalance, equals(400.0)); // debited
    });

    test('Edit category change updates analytics category breakdown', () async {
      final analyticsRepo = AnalyticsRepository(db);
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Snapshot baseline food amount before test
      final baselineBreakdown = await analyticsRepo.getCategoryBreakdown(
        startDate: start,
        endDate: end,
        type: TransactionType.expense,
      );
      final foodBaseline = baselineBreakdown.categories
          .where((c) => c.categoryId == 'expense_food')
          .firstOrNull;
      final foodBaselineAmount = foodBaseline?.amount ?? 0.0;
      final transportBaseline = baselineBreakdown.categories
          .where((c) => c.categoryId == 'expense_transport')
          .firstOrNull;
      final transportBaselineAmount = transportBaseline?.amount ?? 0.0;

      // Add expense to food
      await db.addTransaction(Transaction(
        id: 'tx_inv_cat',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: walletX.id,
        createdAt: now,
      ));

      final beforeBreakdown = await analyticsRepo.getCategoryBreakdown(
        startDate: start,
        endDate: end,
        type: TransactionType.expense,
      );
      final foodBefore = beforeBreakdown.categories
          .where((c) => c.categoryId == 'expense_food')
          .firstOrNull;
      expect(foodBefore, isNotNull);
      expect(foodBefore!.amount, equals(foodBaselineAmount + 50.0));

      // Edit: change category to transport
      await db.updateTransaction(Transaction(
        id: 'tx_inv_cat',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: 'expense_transport',
        walletId: walletX.id,
        createdAt: now,
      ));

      final afterBreakdown = await analyticsRepo.getCategoryBreakdown(
        startDate: start,
        endDate: end,
        type: TransactionType.expense,
      );
      final foodAfter = afterBreakdown.categories
          .where((c) => c.categoryId == 'expense_food')
          .firstOrNull;
      final transportAfter = afterBreakdown.categories
          .where((c) => c.categoryId == 'expense_transport')
          .firstOrNull;

      // Food should be back to baseline (the 50 moved away)
      final foodAfterAmount = foodAfter?.amount ?? 0.0;
      expect(foodAfterAmount, equals(foodBaselineAmount));

      // Transport should have baseline + 50
      expect(transportAfter, isNotNull);
      expect(transportAfter!.amount, equals(transportBaselineAmount + 50.0));
    });

    test('Edit type from expense to income updates both wallet and analytics', () async {
      final txRepo = TransactionRepository(db);
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Add expense
      await db.addTransaction(Transaction(
        id: 'tx_inv_type',
        amount: 80.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: walletX.id,
        createdAt: now,
      ));

      var x = await db.getWallet(walletX.id);
      expect(x!.currentBalance, equals(920.0));

      // Flip to income
      await db.updateTransaction(Transaction(
        id: 'tx_inv_type',
        amount: 80.0,
        type: TransactionType.income,
        categoryId: 'income_salary',
        walletId: walletX.id,
        createdAt: now,
      ));

      x = await db.getWallet(walletX.id);
      // Was 1000 - 80 = 920. After reversal + income: 1000 + 80 = 1080
      expect(x!.currentBalance, equals(1080.0));

      final summary = await txRepo.getSummary(startDate: start, endDate: end);
      expect(summary.income, greaterThanOrEqualTo(80.0));
    });

    test('Edit date moves transaction across date buckets', () async {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 15);

      // Add transaction this month
      await db.addTransaction(Transaction(
        id: 'tx_inv_date',
        amount: 60.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: walletX.id,
        createdAt: now,
      ));

      // This month should contain the tx
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final thisMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      var thisMonthTxs = await db.getTransactionsByDateRange(thisMonthStart, thisMonthEnd);
      expect(thisMonthTxs.any((t) => t.id == 'tx_inv_date'), isTrue);

      // Edit date to last month
      await db.updateTransaction(Transaction(
        id: 'tx_inv_date',
        amount: 60.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: walletX.id,
        createdAt: lastMonth,
      ));

      // This month should NOT contain it
      thisMonthTxs = await db.getTransactionsByDateRange(thisMonthStart, thisMonthEnd);
      expect(thisMonthTxs.any((t) => t.id == 'tx_inv_date'), isFalse);

      // Last month should contain it
      final lastMonthStart = DateTime(lastMonth.year, lastMonth.month, 1);
      final lastMonthEnd = DateTime(lastMonth.year, lastMonth.month + 1, 0, 23, 59, 59);
      final lastMonthTxs = await db.getTransactionsByDateRange(lastMonthStart, lastMonthEnd);
      expect(lastMonthTxs.any((t) => t.id == 'tx_inv_date'), isTrue);
    });
  });
}
