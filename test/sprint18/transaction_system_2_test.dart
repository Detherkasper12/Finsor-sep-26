import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/repositories/transaction_repository.dart';
import 'package:finsor/repositories/analytics_repository.dart';
import 'package:finsor/repositories/analytics_models.dart';

void main() {
  late HiveDatabaseService db;
  late TransactionRepository txRepo;
  late AnalyticsRepository analyticsRepo;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sprint18_test_');
    Hive.init(tempDir.path);
    db = HiveDatabaseService.instance;
    await db.init();
    txRepo = TransactionRepository(db);
    analyticsRepo = AnalyticsRepository(db);
  });

  tearDownAll(() async {
    await db.close();
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('Duplicate detection', () {
    test('findPotentialDuplicates returns same-wallet similar-amount within 24h', () async {
      final base = DateTime.now();
      await db.addTransaction(Transaction(
        id: 'dup_1',
        amount: 100,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        createdAt: base,
      ));
      final candidate = Transaction(
        id: 'dup_2',
        amount: 101,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        createdAt: base.add(const Duration(hours: 1)),
      );
      final dupes = await txRepo.findPotentialDuplicates(candidate);
      expect(dupes.length, 1);
      expect(dupes.first.id, 'dup_1');
      await db.deleteTransaction('dup_1');
    });

    test('findPotentialDuplicates returns empty when amount differs >5%', () async {
      final base = DateTime.now();
      await db.addTransaction(Transaction(
        id: 'nodup_1',
        amount: 100,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        createdAt: base,
      ));
      final candidate = Transaction(
        id: 'nodup_2',
        amount: 200,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        createdAt: base.add(const Duration(hours: 1)),
      );
      final dupes = await txRepo.findPotentialDuplicates(candidate);
      expect(dupes, isEmpty);
      await db.deleteTransaction('nodup_1');
    });
  });

  group('Multi-subcategory', () {
    test('saveTransactionWithSubcategories and getSubcategoryIdsForTransaction', () async {
      final t = Transaction(
        id: 'subcat_tx_1',
        amount: 50,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        createdAt: DateTime.now(),
      );
      await txRepo.saveTransactionWithSubcategories(t, ['sub_1', 'sub_2']);
      final ids = await txRepo.getSubcategoryIdsForTransaction(t.id);
      expect(ids, containsAll(['sub_1', 'sub_2']));
      await txRepo.saveTransactionWithSubcategories(t.copyWith(amount: 60), ['sub_1']);
      final ids2 = await txRepo.getSubcategoryIdsForTransaction(t.id);
      expect(ids2, ['sub_1']);
      await db.deleteTransaction(t.id);
    });
  });

  group('Net worth', () {
    test('getCurrentNetWorth returns assets minus liabilities', () async {
      final snapshot = await analyticsRepo.getCurrentNetWorth();
      expect(snapshot.date, isNotNull);
      expect(snapshot.netWorth, equals(snapshot.assets - snapshot.liabilities));
    });
  });

  group('Spending velocity', () {
    test('getSpendingVelocity returns avgDaily and projected', () async {
      final v = await analyticsRepo.getSpendingVelocity();
      expect(v.daysInMonth, greaterThan(0));
      expect(v.daysElapsed, greaterThanOrEqualTo(0));
      expect(v.avgDailySpend, greaterThanOrEqualTo(0));
      expect(v.projectedMonthTotal, greaterThanOrEqualTo(0));
    });
  });

  group('Transaction split fields', () {
    test('Transaction model defaults isSplit and parentTransactionId', () {
      final t = Transaction(
        id: 's1',
        amount: 1,
        type: TransactionType.expense,
        categoryId: 'c1',
        walletId: 'w1',
        createdAt: DateTime.now(),
      );
      expect(t.isSplit, isFalse);
      expect(t.parentTransactionId, isNull);
    });
  });
}
