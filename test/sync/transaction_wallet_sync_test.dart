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
    tempDir = await Directory.systemTemp.createTemp('sync_wallet_');
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

  group('Transaction -> Wallet balance sync', () {
    test('Add expense decreases wallet balance', () async {
      final wallet = await db.getWallet('wallet_default');
      expect(wallet, isNotNull);
      final before = wallet!.currentBalance;

      await db.addTransaction(Transaction(
        id: 'tx_exp_1',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallet.id,
        createdAt: DateTime.now(),
      ));

      final after = await db.getWallet(wallet.id);
      expect(after!.currentBalance, equals(before - 50.0));
    });

    test('Add income increases wallet balance', () async {
      final wallet = await db.getWallet('wallet_default');
      final before = wallet!.currentBalance;

      await db.addTransaction(Transaction(
        id: 'tx_inc_1',
        amount: 100.0,
        type: TransactionType.income,
        categoryId: 'income_salary',
        walletId: wallet.id,
        createdAt: DateTime.now(),
      ));

      final after = await db.getWallet(wallet.id);
      expect(after!.currentBalance, equals(before + 100.0));
    });

    test('Edit transaction amount adjusts wallet balance by delta', () async {
      final wallet = await db.getWallet('wallet_default');
      final before = wallet!.currentBalance;

      final tx = Transaction(
        id: 'tx_edit_amt',
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallet.id,
        createdAt: DateTime.now(),
      );
      await db.addTransaction(tx);

      final afterAdd = await db.getWallet(wallet.id);
      expect(afterAdd!.currentBalance, equals(before - 100.0));

      final updated = Transaction(
        id: tx.id,
        amount: 200.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallet.id,
        createdAt: tx.createdAt,
        updatedAt: DateTime.now(),
      );
      await db.updateTransaction(updated);

      final afterEdit = await db.getWallet(wallet.id);
      expect(afterEdit!.currentBalance, equals(before - 200.0));
    });

    test('Edit transaction wallet transfers balance correctly', () async {
      final w2 = Wallet(
        id: 'wallet_test_2',
        name: 'Test Wallet 2',
        type: WalletType.savings,
        currency: 'USD',
        currentBalance: 500.0,
        initialBalance: 500.0,
        createdAt: DateTime.now(),
      );
      await db.addWallet(w2);

      final w1 = await db.getWallet('wallet_default');
      final w1Before = w1!.currentBalance;

      final tx = Transaction(
        id: 'tx_wallet_switch',
        amount: 75.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: w1.id,
        createdAt: DateTime.now(),
      );
      await db.addTransaction(tx);

      final w1AfterAdd = await db.getWallet(w1.id);
      expect(w1AfterAdd!.currentBalance, equals(w1Before - 75.0));

      final updated = Transaction(
        id: tx.id,
        amount: 75.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: w2.id,
        createdAt: tx.createdAt,
        updatedAt: DateTime.now(),
      );
      await db.updateTransaction(updated);

      final w1AfterEdit = await db.getWallet(w1.id);
      expect(w1AfterEdit!.currentBalance, equals(w1Before));

      final w2AfterEdit = await db.getWallet(w2.id);
      expect(w2AfterEdit!.currentBalance, equals(500.0 - 75.0));
    });

    test('Edit transaction type flips balance correctly', () async {
      final wallet = await db.getWallet('wallet_default');
      final before = wallet!.currentBalance;

      final tx = Transaction(
        id: 'tx_type_flip',
        amount: 60.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallet.id,
        createdAt: DateTime.now(),
      );
      await db.addTransaction(tx);
      final afterExpense = await db.getWallet(wallet.id);
      expect(afterExpense!.currentBalance, equals(before - 60.0));

      final updated = Transaction(
        id: tx.id,
        amount: 60.0,
        type: TransactionType.income,
        categoryId: 'income_salary',
        walletId: wallet.id,
        createdAt: tx.createdAt,
        updatedAt: DateTime.now(),
      );
      await db.updateTransaction(updated);

      final afterFlip = await db.getWallet(wallet.id);
      expect(afterFlip!.currentBalance, equals(before + 60.0));
    });

    test('Delete transaction restores wallet balance', () async {
      final wallet = await db.getWallet('wallet_default');
      final before = wallet!.currentBalance;

      await db.addTransaction(Transaction(
        id: 'tx_delete_restore',
        amount: 40.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallet.id,
        createdAt: DateTime.now(),
      ));

      final afterAdd = await db.getWallet(wallet.id);
      expect(afterAdd!.currentBalance, equals(before - 40.0));

      await db.deleteTransaction('tx_delete_restore');

      final afterDelete = await db.getWallet(wallet.id);
      expect(afterDelete!.currentBalance, equals(before));
    });
  });
}
