import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/wallet.dart';

void main() {
  late HiveDatabaseService db;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sprint12_wallet_');
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

  group('Wallet reassignment', () {
    test('getTransactionCountByWallet returns correct count', () async {
      final w2 = Wallet(
        id: 'wallet_2',
        name: 'Savings',
        type: WalletType.savings,
        currency: 'USD',
        currentBalance: 0,
        createdAt: DateTime.now(),
      );
      await db.addWallet(w2);

      final w1 = await db.getWallet('wallet_default');
      expect(w1, isNotNull);

      await db.addTransaction(Transaction(
        id: 'tx1',
        amount: 10,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: w1!.id,
        createdAt: DateTime.now(),
      ));
      await db.addTransaction(Transaction(
        id: 'tx2',
        amount: 20,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: w1.id,
        createdAt: DateTime.now(),
      ));

      expect(await db.getTransactionCountByWallet(w1.id), equals(2));
      expect(await db.getTransactionCountByWallet(w2.id), equals(0));
    });

    test('reassignTransactionsToWallet moves transactions and updates balances', () async {
      final w2 = Wallet(
        id: 'wallet_2',
        name: 'Target',
        type: WalletType.savings,
        currency: 'USD',
        currentBalance: 0,
        createdAt: DateTime.now(),
      );
      await db.addWallet(w2);

      final w1 = await db.getWallet('wallet_default');
      expect(w1, isNotNull);

      await db.addTransaction(Transaction(
        id: 'reassign_tx',
        amount: 50,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: w1!.id,
        createdAt: DateTime.now(),
      ));

      await db.reassignTransactionsToWallet(w1.id, w2.id);

      expect(await db.getTransactionCountByWallet(w1.id), equals(0));

      final t = await db.getTransaction('reassign_tx');
      expect(t!.walletId, equals(w2.id));
    });
  });
}
