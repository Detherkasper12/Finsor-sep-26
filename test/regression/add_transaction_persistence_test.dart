import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/repositories/transaction_repository.dart';
import 'package:finsor/models/transaction.dart';

/// Regression test: Verify transactions added via HiveDatabaseService
/// are visible in TransactionRepository queries (same storage backend)
void main() {
  late Directory tempDir;
  late HiveDatabaseService db;
  late TransactionRepository repo;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('regression_add_tx_');
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

  test('transaction added via db.addTransaction appears in repo.getRecent', () async {
    // Count before
    final beforeRecent = await repo.getRecent(limit: 100);
    final beforeCount = beforeRecent.length;

    // Add a transaction (simulating what add_transaction_bottom_sheet does)
    final now = DateTime.now();
    final tx = Transaction(
      id: 'regression_tx_${now.millisecondsSinceEpoch}',
      amount: 500.0,
      type: TransactionType.income,
      categoryId: 'income_salary',
      walletId: 'wallet_default',
      description: 'Regression test income',
      createdAt: now,
    );

    await db.addTransaction(tx);

    // Query via repository (simulating what home_screen does)
    final afterRecent = await repo.getRecent(limit: 100);
    final afterCount = afterRecent.length;

    expect(afterCount, equals(beforeCount + 1),
        reason: 'Transaction should be visible via repository after adding via db');

    // Verify the specific transaction is present
    final found = afterRecent.any((t) => t.id == tx.id);
    expect(found, isTrue, reason: 'Added transaction should be in recent list');
  });

  test('transaction added via db appears in repo.getCurrentMonthSummary', () async {
    final now = DateTime.now();

    // Get summary before
    final beforeSummary = await repo.getCurrentMonthSummary();
    final beforeIncome = beforeSummary.income;

    // Add income transaction
    final tx = Transaction(
      id: 'regression_summary_${now.millisecondsSinceEpoch}',
      amount: 1000.0,
      type: TransactionType.income,
      categoryId: 'income_salary',
      walletId: 'wallet_default',
      description: 'Regression test summary income',
      createdAt: now,
    );

    await db.addTransaction(tx);

    // Get summary after
    final afterSummary = await repo.getCurrentMonthSummary();
    final afterIncome = afterSummary.income;

    expect(afterIncome, equals(beforeIncome + 1000.0),
        reason: 'Income should increase by transaction amount');
  });

  test('transaction with DateTime.now() is included in current month query', () async {
    final now = DateTime.now();

    // This tests the date range boundary issue
    final tx = Transaction(
      id: 'regression_boundary_${now.millisecondsSinceEpoch}',
      amount: 250.0,
      type: TransactionType.expense,
      categoryId: 'expense_food',
      walletId: 'wallet_default',
      description: 'Boundary test',
      createdAt: now,
    );

    await db.addTransaction(tx);

    // Query by date range for current month
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final transactions = await db.getTransactionsByDateRange(startOfMonth, endOfMonth);
    final found = transactions.any((t) => t.id == tx.id);

    expect(found, isTrue,
        reason: 'Transaction created with DateTime.now() should be in current month range');
  });
}
