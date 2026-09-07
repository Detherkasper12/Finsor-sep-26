import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/wallet.dart';
import 'package:finsor/models/budget.dart';

void main() {
  late HiveDatabaseService db;
  late Directory tempDir;

  setUpAll(() async {
    // Create temp directory for Hive
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    // Clear any existing boxes
    await Hive.deleteFromDisk();
    Hive.init(tempDir.path);
    
    // Get fresh instance
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

  group('Transaction CRUD', () {
    test('should create and retrieve a transaction', () async {
      final transaction = Transaction(
        id: 'test_tx_1',
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        description: 'Test transaction',
        createdAt: DateTime.now(),
      );

      await db.addTransaction(transaction);
      final retrieved = await db.getTransaction('test_tx_1');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('test_tx_1'));
      expect(retrieved.amount, equals(100.0));
      expect(retrieved.type, equals(TransactionType.expense));
      expect(retrieved.description, equals('Test transaction'));
    });

    test('should update a transaction', () async {
      final transaction = Transaction(
        id: 'test_tx_2',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        createdAt: DateTime.now(),
      );

      await db.addTransaction(transaction);
      
      final updated = transaction.copyWith(
        amount: 75.0,
        description: 'Updated description',
      );
      await db.updateTransaction(updated);

      final retrieved = await db.getTransaction('test_tx_2');
      expect(retrieved!.amount, equals(75.0));
      expect(retrieved.description, equals('Updated description'));
    });

    test('should delete a transaction', () async {
      final transaction = Transaction(
        id: 'test_tx_3',
        amount: 25.0,
        type: TransactionType.income,
        categoryId: 'income_salary',
        walletId: 'wallet_default',
        createdAt: DateTime.now(),
      );

      await db.addTransaction(transaction);
      expect(await db.getTransaction('test_tx_3'), isNotNull);

      await db.deleteTransaction('test_tx_3');
      expect(await db.getTransaction('test_tx_3'), isNull);
    });

    test('should retrieve transactions by date range', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final lastWeek = now.subtract(const Duration(days: 7));

      // Get initial count
      final initialTx = await db.getTransactions();
      final initialCount = initialTx.length;

      await db.addTransaction(Transaction(
        id: 'tx_today_range',
        amount: 10.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        createdAt: now,
      ));

      await db.addTransaction(Transaction(
        id: 'tx_yesterday_range',
        amount: 20.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        createdAt: yesterday,
      ));

      await db.addTransaction(Transaction(
        id: 'tx_last_week_range',
        amount: 30.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        createdAt: lastWeek,
      ));

      final allTx = await db.getTransactions();
      expect(allTx.length, equals(initialCount + 3));

      // Verify we can filter by date
      final lastTwoDays = await db.getTransactionsByDateRange(
        now.subtract(const Duration(days: 2)),
        now.add(const Duration(days: 1)),
      );

      // Should include tx_today_range and tx_yesterday_range (and potentially others from same date range)
      expect(lastTwoDays.any((t) => t.id == 'tx_today_range'), isTrue);
      expect(lastTwoDays.any((t) => t.id == 'tx_yesterday_range'), isTrue);
      expect(lastTwoDays.any((t) => t.id == 'tx_last_week_range'), isFalse);
    });
  });

  group('Wallet Balance Consistency', () {
    test('should update wallet balance on income transaction', () async {
      // Get default wallet (created during init)
      var wallets = await db.getWallets();
      final wallet = wallets.first;
      final initialBalance = wallet.currentBalance;

      await db.addTransaction(Transaction(
        id: 'income_tx',
        amount: 500.0,
        type: TransactionType.income,
        categoryId: 'income_salary',
        walletId: wallet.id,
        createdAt: DateTime.now(),
      ));

      final updatedWallet = await db.getWallet(wallet.id);
      expect(updatedWallet!.currentBalance, equals(initialBalance + 500.0));
    });

    test('should update wallet balance on expense transaction', () async {
      var wallets = await db.getWallets();
      final wallet = wallets.first;
      
      // First add income so we have balance
      await db.addTransaction(Transaction(
        id: 'setup_income',
        amount: 1000.0,
        type: TransactionType.income,
        categoryId: 'income_salary',
        walletId: wallet.id,
        createdAt: DateTime.now(),
      ));

      final balanceAfterIncome = (await db.getWallet(wallet.id))!.currentBalance;

      await db.addTransaction(Transaction(
        id: 'expense_tx',
        amount: 200.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallet.id,
        createdAt: DateTime.now(),
      ));

      final updatedWallet = await db.getWallet(wallet.id);
      expect(updatedWallet!.currentBalance, equals(balanceAfterIncome - 200.0));
    });

    test('should reverse balance on transaction delete', () async {
      var wallets = await db.getWallets();
      final wallet = wallets.first;
      final initialBalance = wallet.currentBalance;

      await db.addTransaction(Transaction(
        id: 'to_delete',
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallet.id,
        createdAt: DateTime.now(),
      ));

      // Balance should be reduced
      var afterAdd = await db.getWallet(wallet.id);
      expect(afterAdd!.currentBalance, equals(initialBalance - 100.0));

      // Delete transaction
      await db.deleteTransaction('to_delete');

      // Balance should be restored
      var afterDelete = await db.getWallet(wallet.id);
      expect(afterDelete!.currentBalance, equals(initialBalance));
    });

    test('should handle transfer between wallets', () async {
      // Create second wallet
      final wallet2 = Wallet(
        id: 'wallet_2',
        name: 'Savings',
        type: WalletType.savings,
        currency: 'USD',
        currentBalance: 0.0,
        createdAt: DateTime.now(),
      );
      await db.addWallet(wallet2);

      var wallets = await db.getWallets();
      final wallet1 = wallets.firstWhere((w) => w.id == 'wallet_default');
      
      // Add income to wallet1
      await db.addTransaction(Transaction(
        id: 'initial_income',
        amount: 1000.0,
        type: TransactionType.income,
        categoryId: 'income_salary',
        walletId: wallet1.id,
        createdAt: DateTime.now(),
      ));

      final wallet1BalanceBefore = (await db.getWallet(wallet1.id))!.currentBalance;
      final wallet2BalanceBefore = (await db.getWallet('wallet_2'))!.currentBalance;

      // Transfer from wallet1 to wallet2
      await db.addTransaction(Transaction(
        id: 'transfer_tx',
        amount: 300.0,
        type: TransactionType.transfer,
        categoryId: 'transfer',
        walletId: wallet1.id,
        toWalletId: 'wallet_2',
        createdAt: DateTime.now(),
      ));

      final wallet1After = await db.getWallet(wallet1.id);
      final wallet2After = await db.getWallet('wallet_2');

      expect(wallet1After!.currentBalance, equals(wallet1BalanceBefore - 300.0));
      expect(wallet2After!.currentBalance, equals(wallet2BalanceBefore + 300.0));
    });
  });

  group('Category Operations', () {
    test('should load default categories on init', () async {
      final categories = await db.getCategories();
      expect(categories.isNotEmpty, isTrue);
      
      // Check income and expense categories exist
      final incomeCategories = categories.where((c) => c.type == TransactionType.income);
      final expenseCategories = categories.where((c) => c.type == TransactionType.expense);
      
      expect(incomeCategories.isNotEmpty, isTrue);
      expect(expenseCategories.isNotEmpty, isTrue);
    });

    test('should filter categories by type', () async {
      final incomeCategories = await db.getCategoriesByType(TransactionType.income);
      final expenseCategories = await db.getCategoriesByType(TransactionType.expense);

      for (final cat in incomeCategories) {
        expect(cat.type, equals(TransactionType.income));
      }

      for (final cat in expenseCategories) {
        expect(cat.type, equals(TransactionType.expense));
      }
    });
  });

  group('Budget Operations', () {
    test('should create and retrieve a budget', () async {
      final now = DateTime.now();
      final budget = Budget(
        id: 'test_budget',
        name: 'Food Budget',
        categoryId: 'expense_food',
        amount: 500.0,
        spent: 0.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
        createdAt: now,
      );

      await db.addBudget(budget);
      final retrieved = await db.getBudget('test_budget');

      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Food Budget'));
      expect(retrieved.amount, equals(500.0));
    });

    test('should update budget spent amount', () async {
      final now = DateTime.now();
      final budget = Budget(
        id: 'budget_to_update',
        name: 'Shopping Budget',
        categoryId: 'expense_shopping',
        amount: 300.0,
        spent: 0.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
        createdAt: now,
      );

      await db.addBudget(budget);
      
      final updated = budget.copyWith(spent: 150.0);
      await db.updateBudget(updated);

      final retrieved = await db.getBudget('budget_to_update');
      expect(retrieved!.spent, equals(150.0));
      expect(retrieved.percentageSpent, equals(50.0));
    });
  });

  group('Data Persistence', () {
    test('should persist data across service restarts', () async {
      // Add data
      await db.addTransaction(Transaction(
        id: 'persist_test',
        amount: 999.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        createdAt: DateTime.now(),
      ));

      // Close and reinitialize
      await db.close();
      
      // Reinitialize
      final newDb = HiveDatabaseService.instance;
      await newDb.init();

      // Data should still exist
      final retrieved = await newDb.getTransaction('persist_test');
      expect(retrieved, isNotNull);
      expect(retrieved!.amount, equals(999.0));
    });
  });

  group('Export/Import', () {
    test('should export all data', () async {
      final exportData = await db.exportData();

      expect(exportData['transactions'], isA<List>());
      expect(exportData['wallets'], isA<List>());
      expect(exportData['categories'], isA<List>());
      expect(exportData['budgets'], isA<List>());
      expect(exportData['settings'], isA<Map>());
      expect(exportData['export_date'], isNotNull);
    });
  });
}
