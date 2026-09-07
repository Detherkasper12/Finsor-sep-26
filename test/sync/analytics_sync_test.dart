import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/repositories/analytics_repository.dart';

void main() {
  late HiveDatabaseService db;
  late AnalyticsRepository analyticsRepo;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_analytics_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    await Hive.deleteFromDisk();
    Hive.init(tempDir.path);
    db = HiveDatabaseService.instance;
    await db.init();
    analyticsRepo = AnalyticsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Transaction -> Analytics sync', () {
    test('Add transaction updates category breakdown', () async {
      final wallets = await db.getWallets();
      expect(wallets.isNotEmpty, true);

      final now = DateTime.now();
      final start = DateTime(now.year, now.month);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final breakdownBefore = await analyticsRepo.getCategoryBreakdown(
        startDate: start, endDate: end, type: TransactionType.expense);
      final totalBefore = breakdownBefore.totalAmount;

      await db.addTransaction(Transaction(
        id: 'tx_analytics_1',
        amount: 75.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallets.first.id,
        createdAt: DateTime.now(),
      ));

      final breakdownAfter = await analyticsRepo.getCategoryBreakdown(
        startDate: start, endDate: end, type: TransactionType.expense);
      final totalAfter = breakdownAfter.totalAmount;

      expect(totalAfter, equals(totalBefore + 75.0));
    });

    test('Delete transaction reduces analytics totals', () async {
      final wallets = await db.getWallets();
      final now = DateTime.now();
      final start = DateTime(now.year, now.month);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      await db.addTransaction(Transaction(
        id: 'tx_analytics_del',
        amount: 120.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallets.first.id,
        createdAt: DateTime.now(),
      ));

      final before = await analyticsRepo.getCategoryBreakdown(
        startDate: start, endDate: end, type: TransactionType.expense);

      await db.deleteTransaction('tx_analytics_del');

      final after = await analyticsRepo.getCategoryBreakdown(
        startDate: start, endDate: end, type: TransactionType.expense);

      expect(after.totalAmount, equals(before.totalAmount - 120.0));
    });

    test('Edit transaction updates analytics correctly', () async {
      final wallets = await db.getWallets();
      final now = DateTime.now();
      final start = DateTime(now.year, now.month);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final tx = Transaction(
        id: 'tx_analytics_edit',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallets.first.id,
        createdAt: DateTime.now(),
      );
      await db.addTransaction(tx);

      final beforeEdit = await analyticsRepo.getCategoryBreakdown(
        startDate: start, endDate: end, type: TransactionType.expense);

      final updated = Transaction(
        id: tx.id,
        amount: 200.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallets.first.id,
        createdAt: tx.createdAt,
        updatedAt: DateTime.now(),
      );
      await db.updateTransaction(updated);

      final afterEdit = await analyticsRepo.getCategoryBreakdown(
        startDate: start, endDate: end, type: TransactionType.expense);

      expect(afterEdit.totalAmount, equals(beforeEdit.totalAmount + 150.0));
    });
  });
}
