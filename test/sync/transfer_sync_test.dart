import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/wallet.dart';
import 'package:finsor/repositories/transaction_repository.dart';
import 'package:finsor/repositories/budget_repository.dart';
import 'package:finsor/models/budget.dart';

void main() {
  late HiveDatabaseService db;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_transfer_');
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

  group('Transfer sync', () {
    late Wallet walletA;
    late Wallet walletB;

    setUp(() async {
      walletA = Wallet(
        id: 'wallet_transfer_a',
        name: 'Transfer A',
        type: WalletType.cash,
        currency: 'USD',
        initialBalance: 500.0,
        currentBalance: 500.0,
        createdAt: DateTime.now(),
      );
      walletB = Wallet(
        id: 'wallet_transfer_b',
        name: 'Transfer B',
        type: WalletType.bank,
        currency: 'USD',
        initialBalance: 200.0,
        currentBalance: 200.0,
        createdAt: DateTime.now(),
      );
      await db.addWallet(walletA);
      await db.addWallet(walletB);
    });

    test('Add transfer debits source and credits destination', () async {
      await db.addTransaction(Transaction(
        id: 'tx_xfer_1',
        amount: 100.0,
        type: TransactionType.transfer,
        categoryId: 'transfer',
        walletId: walletA.id,
        toWalletId: walletB.id,
        createdAt: DateTime.now(),
      ));

      final a = await db.getWallet(walletA.id);
      final b = await db.getWallet(walletB.id);
      expect(a!.currentBalance, equals(400.0));
      expect(b!.currentBalance, equals(300.0));
    });

    test('Delete transfer reverses both wallet balances', () async {
      await db.addTransaction(Transaction(
        id: 'tx_xfer_del',
        amount: 75.0,
        type: TransactionType.transfer,
        categoryId: 'transfer',
        walletId: walletA.id,
        toWalletId: walletB.id,
        createdAt: DateTime.now(),
      ));

      final aBefore = await db.getWallet(walletA.id);
      final bBefore = await db.getWallet(walletB.id);
      expect(aBefore!.currentBalance, equals(425.0));
      expect(bBefore!.currentBalance, equals(275.0));

      await db.deleteTransaction('tx_xfer_del');

      final aAfter = await db.getWallet(walletA.id);
      final bAfter = await db.getWallet(walletB.id);
      expect(aAfter!.currentBalance, equals(500.0));
      expect(bAfter!.currentBalance, equals(200.0));
    });

    test('Edit transfer amount adjusts both wallets correctly', () async {
      await db.addTransaction(Transaction(
        id: 'tx_xfer_edit',
        amount: 50.0,
        type: TransactionType.transfer,
        categoryId: 'transfer',
        walletId: walletA.id,
        toWalletId: walletB.id,
        createdAt: DateTime.now(),
      ));

      // A: 500-50=450, B: 200+50=250
      var a = await db.getWallet(walletA.id);
      var b = await db.getWallet(walletB.id);
      expect(a!.currentBalance, equals(450.0));
      expect(b!.currentBalance, equals(250.0));

      // Edit to 120
      await db.updateTransaction(Transaction(
        id: 'tx_xfer_edit',
        amount: 120.0,
        type: TransactionType.transfer,
        categoryId: 'transfer',
        walletId: walletA.id,
        toWalletId: walletB.id,
        createdAt: DateTime.now(),
      ));

      a = await db.getWallet(walletA.id);
      b = await db.getWallet(walletB.id);
      // A: 500-120=380, B: 200+120=320
      expect(a!.currentBalance, equals(380.0));
      expect(b!.currentBalance, equals(320.0));
    });

    test('Transfer does NOT affect income/expense totals', () async {
      final txRepo = TransactionRepository(db);
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Add an expense for baseline
      await db.addTransaction(Transaction(
        id: 'tx_exp_baseline',
        amount: 30.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: walletA.id,
        createdAt: now,
      ));

      final beforeSummary = await txRepo.getSummary(startDate: start, endDate: end);
      final beforeExpense = beforeSummary.expenses;
      final beforeIncome = beforeSummary.income;

      // Add a transfer
      await db.addTransaction(Transaction(
        id: 'tx_xfer_analytics',
        amount: 200.0,
        type: TransactionType.transfer,
        categoryId: 'transfer',
        walletId: walletA.id,
        toWalletId: walletB.id,
        createdAt: now,
      ));

      final afterSummary = await txRepo.getSummary(startDate: start, endDate: end);
      expect(afterSummary.expenses, equals(beforeExpense));
      expect(afterSummary.income, equals(beforeIncome));
    });

    test('Transfer does NOT affect budget spent amount', () async {
      final budgetRepo = BudgetRepository(db);

      // Create a budget for food
      final budget = await budgetRepo.createBudget(
        name: 'Food Budget',
        amount: 500.0,
        categoryId: 'expense_food',
        period: BudgetPeriod.monthly,
      );

      final now = DateTime.now();

      // Add an expense to the budget
      await db.addTransaction(Transaction(
        id: 'tx_budget_exp',
        amount: 40.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: walletA.id,
        createdAt: now,
      ));

      final beforeBudget = await budgetRepo.getComputedBudget(budget.id);
      final beforeSpent = beforeBudget!.spent;

      // Add a transfer (should not affect budget)
      await db.addTransaction(Transaction(
        id: 'tx_budget_xfer',
        amount: 150.0,
        type: TransactionType.transfer,
        categoryId: 'transfer',
        walletId: walletA.id,
        toWalletId: walletB.id,
        createdAt: now,
      ));

      final afterBudget = await budgetRepo.getComputedBudget(budget.id);
      expect(afterBudget!.spent, equals(beforeSpent));
    });
  });
}
