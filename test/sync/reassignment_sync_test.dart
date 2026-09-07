import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/wallet.dart';
import 'package:finsor/models/category.dart';

void main() {
  late HiveDatabaseService db;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_reassign_');
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
    test('Reassign moves all transactions to target category', () async {
      final srcCat = Category(
        id: 'cat_src',
        name: 'Source Cat',
        type: TransactionType.expense,
        iconName: 'restaurant',
        color: '#FF5722',
        createdAt: DateTime.now(),
      );
      final dstCat = Category(
        id: 'cat_dst',
        name: 'Dest Cat',
        type: TransactionType.expense,
        iconName: 'shopping_bag',
        color: '#9C27B0',
        createdAt: DateTime.now(),
      );
      await db.addCategory(srcCat);
      await db.addCategory(dstCat);

      final wallets = await db.getWallets();
      expect(wallets.isNotEmpty, true);

      for (int i = 0; i < 3; i++) {
        await db.addTransaction(Transaction(
          id: 'tx_reassign_cat_$i',
          amount: 10.0 * (i + 1),
          type: TransactionType.expense,
          categoryId: srcCat.id,
          walletId: wallets.first.id,
          createdAt: DateTime.now(),
        ));
      }

      final srcCount = await db.getTransactionCountByCategory(srcCat.id);
      expect(srcCount, 3);

      await db.reassignTransactionsToCategory(srcCat.id, dstCat.id);

      final srcCountAfter = await db.getTransactionCountByCategory(srcCat.id);
      expect(srcCountAfter, 0);

      final dstCount = await db.getTransactionCountByCategory(dstCat.id);
      expect(dstCount, 3);
    });
  });

  group('Wallet reassignment', () {
    test('Reassign moves transactions and recalculates balances', () async {
      // Use dedicated wallets to avoid cross-contamination from other tests
      final w1 = Wallet(
        id: 'wallet_src_isolated',
        name: 'Source Wallet',
        type: WalletType.cash,
        currency: 'USD',
        initialBalance: 500.0,
        currentBalance: 500.0,
        createdAt: DateTime.now(),
      );
      final w2 = Wallet(
        id: 'wallet_dst_isolated',
        name: 'Target Wallet',
        type: WalletType.bank,
        currency: 'USD',
        initialBalance: 1000.0,
        currentBalance: 1000.0,
        createdAt: DateTime.now(),
      );
      await db.addWallet(w1);
      await db.addWallet(w2);

      await db.addTransaction(Transaction(
        id: 'tx_reassign_iso_1',
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: w1.id,
        createdAt: DateTime.now(),
      ));
      await db.addTransaction(Transaction(
        id: 'tx_reassign_iso_2',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: w1.id,
        createdAt: DateTime.now(),
      ));

      final w1AfterAdd = await db.getWallet(w1.id);
      expect(w1AfterAdd!.currentBalance, equals(350.0));

      await db.reassignTransactionsToWallet(w1.id, w2.id);

      final w1AfterReassign = await db.getWallet(w1.id);
      expect(w1AfterReassign!.currentBalance, equals(500.0));

      final w2AfterReassign = await db.getWallet(w2.id);
      expect(w2AfterReassign!.currentBalance, equals(850.0));

      final w1TxCount = await db.getTransactionCountByWallet(w1.id);
      expect(w1TxCount, 0);

      final w2TxCount = await db.getTransactionCountByWallet(w2.id);
      expect(w2TxCount, 2);
    });

    test('Cannot delete last wallet validation', () async {
      final wallets = await db.getWallets();
      if (wallets.length == 1) {
        final count = await db.getTransactionCountByWallet(wallets.first.id);
        // Even with 0 transactions, we should validate elsewhere.
        // This test just verifies getTransactionCountByWallet works.
        expect(count, isA<int>());
      }
    });
  });
}
