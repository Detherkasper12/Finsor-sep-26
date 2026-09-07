import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/category.dart';

void main() {
  late HiveDatabaseService db;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sprint12_cat_');
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

  group('Category reassignment', () {
    test('getTransactionCountByCategory returns correct count', () async {
      const catA = 'test_cat_a';
      const catB = 'test_cat_b';
      await db.addCategory(Category(id: catA, name: 'Test A', type: TransactionType.expense, iconName: 'food', color: '#FF0000', createdAt: DateTime.now()));
      await db.addCategory(Category(id: catB, name: 'Test B', type: TransactionType.expense, iconName: 'car', color: '#00FF00', createdAt: DateTime.now()));

      await db.addTransaction(Transaction(
        id: 'tx_cat1_a',
        amount: 10,
        type: TransactionType.expense,
        categoryId: catA,
        walletId: 'wallet_default',
        createdAt: DateTime.now(),
      ));
      await db.addTransaction(Transaction(
        id: 'tx_cat1_b',
        amount: 20,
        type: TransactionType.expense,
        categoryId: catA,
        walletId: 'wallet_default',
        createdAt: DateTime.now(),
      ));
      await db.addTransaction(Transaction(
        id: 'tx_cat2',
        amount: 30,
        type: TransactionType.expense,
        categoryId: catB,
        walletId: 'wallet_default',
        createdAt: DateTime.now(),
      ));

      expect(await db.getTransactionCountByCategory(catA), equals(2));
      expect(await db.getTransactionCountByCategory(catB), equals(1));
      expect(await db.getTransactionCountByCategory('nonexistent'), equals(0));
    });

    test('reassignTransactionsToCategory moves transactions to target category', () async {
      const fromCat = 'test_from_cat';
      const toCat = 'test_to_cat';
      await db.addCategory(Category(id: fromCat, name: 'From', type: TransactionType.expense, iconName: 'food', color: '#FF0000', createdAt: DateTime.now()));
      await db.addCategory(Category(id: toCat, name: 'To', type: TransactionType.expense, iconName: 'car', color: '#00FF00', createdAt: DateTime.now()));

      await db.addTransaction(Transaction(
        id: 'reassign_a',
        amount: 50,
        type: TransactionType.expense,
        categoryId: fromCat,
        walletId: 'wallet_default',
        createdAt: DateTime.now(),
      ));
      await db.addTransaction(Transaction(
        id: 'reassign_b',
        amount: 75,
        type: TransactionType.expense,
        categoryId: fromCat,
        walletId: 'wallet_default',
        createdAt: DateTime.now(),
      ));

      await db.reassignTransactionsToCategory(fromCat, toCat);

      expect(await db.getTransactionCountByCategory(fromCat), equals(0));
      expect(await db.getTransactionCountByCategory(toCat), equals(2));

      final t1 = await db.getTransaction('reassign_a');
      final t2 = await db.getTransaction('reassign_b');
      expect(t1!.categoryId, equals(toCat));
      expect(t2!.categoryId, equals(toCat));
    });

    test('reassignTransactionsToCategory preserves transaction amounts', () async {
      const fromCat = 'test_preserve_from';
      const toCat = 'test_preserve_to';
      await db.addCategory(Category(id: fromCat, name: 'From', type: TransactionType.expense, iconName: 'food', color: '#FF0000', createdAt: DateTime.now()));
      await db.addCategory(Category(id: toCat, name: 'To', type: TransactionType.expense, iconName: 'car', color: '#00FF00', createdAt: DateTime.now()));

      await db.addTransaction(Transaction(
        id: 'preserve_tx',
        amount: 99.99,
        type: TransactionType.expense,
        categoryId: fromCat,
        walletId: 'wallet_default',
        description: 'Original desc',
        createdAt: DateTime.now(),
      ));

      await db.reassignTransactionsToCategory(fromCat, toCat);

      final t = await db.getTransaction('preserve_tx');
      expect(t!.amount, equals(99.99));
      expect(t.description, equals('Original desc'));
      expect(t.categoryId, equals(toCat));
    });
  });
}
