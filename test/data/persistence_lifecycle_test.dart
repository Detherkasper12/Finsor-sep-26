import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/wallet.dart';
import 'package:finsor/models/category.dart';
import 'package:finsor/models/budget.dart';

/// Lifecycle & Performance Validation Tests
/// These tests validate:
/// 1. Cold start initialization
/// 2. Kill/reopen persistence
/// 3. Large dataset performance
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_lifecycle_');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Cold Start Validation', () {
    test('should initialize database within 500ms', () async {
      await Hive.deleteFromDisk();
      Hive.init(tempDir.path);

      final stopwatch = Stopwatch()..start();
      
      final db = HiveDatabaseService.instance;
      await db.init();
      
      stopwatch.stop();
      
      print('Cold start time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: 'Cold start should complete within 500ms');
      
      await db.close();
    });

    test('should have default data after cold start', () async {
      await Hive.deleteFromDisk();
      Hive.init(tempDir.path);

      final db = HiveDatabaseService.instance;
      await db.init();

      // Verify defaults exist
      final wallets = await db.getWallets();
      final categories = await db.getCategories();
      final settings = await db.getUserSettings();

      expect(wallets.isNotEmpty, isTrue, reason: 'Should have default wallet');
      expect(categories.isNotEmpty, isTrue, reason: 'Should have default categories');
      expect(settings, isNotNull, reason: 'Should have default settings');

      // Verify default wallet is "Cash"
      expect(wallets.any((w) => w.name == 'Cash'), isTrue);

      await db.close();
    });
  });

  group('Kill/Reopen Persistence', () {
    test('should persist transactions across close/reopen', () async {
      await Hive.deleteFromDisk();
      Hive.init(tempDir.path);

      // Session 1: Create data
      var db = HiveDatabaseService.instance;
      await db.init();

      final testTransaction = Transaction(
        id: 'persist_test_${DateTime.now().millisecondsSinceEpoch}',
        amount: 123.45,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        description: 'Persistence test',
        createdAt: DateTime.now(),
      );

      await db.addTransaction(testTransaction);
      await db.close();

      // Simulate app kill - close Hive completely
      await Hive.close();

      // Session 2: Reopen and verify
      Hive.init(tempDir.path);
      db = HiveDatabaseService.instance;
      await db.init();

      final retrieved = await db.getTransaction(testTransaction.id);
      
      expect(retrieved, isNotNull, reason: 'Transaction should persist after reopen');
      expect(retrieved!.amount, equals(123.45));
      expect(retrieved.description, equals('Persistence test'));

      await db.close();
    });

    test('should persist wallet balance changes across sessions', () async {
      await Hive.deleteFromDisk();
      Hive.init(tempDir.path);

      // Session 1: Add income to change balance
      var db = HiveDatabaseService.instance;
      await db.init();

      final wallets = await db.getWallets();
      final wallet = wallets.first;
      final originalBalance = wallet.currentBalance;

      await db.addTransaction(Transaction(
        id: 'balance_persist_test',
        amount: 500.0,
        type: TransactionType.income,
        categoryId: 'income_salary',
        walletId: wallet.id,
        createdAt: DateTime.now(),
      ));

      final expectedBalance = originalBalance + 500.0;
      var updatedWallet = await db.getWallet(wallet.id);
      expect(updatedWallet!.currentBalance, equals(expectedBalance));

      await db.close();
      await Hive.close();

      // Session 2: Verify balance persisted
      Hive.init(tempDir.path);
      db = HiveDatabaseService.instance;
      await db.init();

      final persistedWallet = await db.getWallet(wallet.id);
      expect(persistedWallet!.currentBalance, equals(expectedBalance),
          reason: 'Balance should persist after reopen');

      await db.close();
    });

    test('should persist multiple entities across sessions', () async {
      await Hive.deleteFromDisk();
      Hive.init(tempDir.path);

      final now = DateTime.now();
      final testWalletId = 'test_wallet_${now.millisecondsSinceEpoch}';
      final testBudgetId = 'test_budget_${now.millisecondsSinceEpoch}';

      // Session 1: Create multiple entities
      var db = HiveDatabaseService.instance;
      await db.init();

      // Add custom wallet
      await db.addWallet(Wallet(
        id: testWalletId,
        name: 'Test Savings',
        type: WalletType.savings,
        currency: 'USD',
        currentBalance: 1000.0,
        createdAt: now,
      ));

      // Add budget
      await db.addBudget(Budget(
        id: testBudgetId,
        name: 'Food Budget',
        categoryId: 'expense_food',
        amount: 500.0,
        period: BudgetPeriod.monthly,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
        createdAt: now,
      ));

      await db.close();
      await Hive.close();

      // Session 2: Verify all persisted
      Hive.init(tempDir.path);
      db = HiveDatabaseService.instance;
      await db.init();

      final retrievedWallet = await db.getWallet(testWalletId);
      final retrievedBudget = await db.getBudget(testBudgetId);

      expect(retrievedWallet, isNotNull);
      expect(retrievedWallet!.name, equals('Test Savings'));
      expect(retrievedWallet.currentBalance, equals(1000.0));

      expect(retrievedBudget, isNotNull);
      expect(retrievedBudget!.name, equals('Food Budget'));
      expect(retrievedBudget.amount, equals(500.0));

      await db.close();
    });
  });

  group('Large Dataset Performance', () {
    test('should handle 1000 transactions within performance threshold', () async {
      await Hive.deleteFromDisk();
      Hive.init(tempDir.path);

      final db = HiveDatabaseService.instance;
      await db.init();

      final random = Random(42); // Seed for reproducibility
      final categories = ['expense_food', 'expense_transport', 'expense_shopping', 
                          'income_salary', 'income_freelance'];
      final now = DateTime.now();

      // Measure write performance
      final writeStopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 1000; i++) {
        final isExpense = random.nextBool();
        await db.addTransaction(Transaction(
          id: 'perf_tx_$i',
          amount: (random.nextDouble() * 1000).roundToDouble(),
          type: isExpense ? TransactionType.expense : TransactionType.income,
          categoryId: categories[random.nextInt(categories.length)],
          walletId: 'wallet_default',
          description: 'Performance test transaction $i',
          createdAt: now.subtract(Duration(days: random.nextInt(365))),
        ));
      }
      
      writeStopwatch.stop();
      print('Write 1000 transactions: ${writeStopwatch.elapsedMilliseconds}ms');
      print('Average per transaction: ${writeStopwatch.elapsedMilliseconds / 1000}ms');

      // Measure read all performance
      final readAllStopwatch = Stopwatch()..start();
      final allTransactions = await db.getTransactions();
      readAllStopwatch.stop();
      
      expect(allTransactions.length, greaterThanOrEqualTo(1000));
      print('Read all transactions: ${readAllStopwatch.elapsedMilliseconds}ms');

      // Measure date range query performance
      final rangeStopwatch = Stopwatch()..start();
      final lastMonth = await db.getTransactionsByDateRange(
        now.subtract(const Duration(days: 30)),
        now,
      );
      rangeStopwatch.stop();
      
      print('Date range query: ${rangeStopwatch.elapsedMilliseconds}ms');
      print('Results in range: ${lastMonth.length}');

      // Performance assertions
      expect(readAllStopwatch.elapsedMilliseconds, lessThan(1000),
          reason: 'Reading 1000+ transactions should complete within 1s');
      expect(rangeStopwatch.elapsedMilliseconds, lessThan(500),
          reason: 'Date range query should complete within 500ms');

      await db.close();
    });

    test('should handle 100 wallets efficiently', () async {
      await Hive.deleteFromDisk();
      Hive.init(tempDir.path);

      final db = HiveDatabaseService.instance;
      await db.init();

      const walletTypes = WalletType.values;
      final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CNY'];
      final random = Random(42);

      // Create 100 wallets
      final writeStopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 100; i++) {
        await db.addWallet(Wallet(
          id: 'wallet_$i',
          name: 'Wallet $i',
          type: walletTypes[random.nextInt(walletTypes.length)],
          currency: currencies[random.nextInt(currencies.length)],
          currentBalance: random.nextDouble() * 10000,
          createdAt: DateTime.now(),
        ));
      }
      
      writeStopwatch.stop();
      print('Write 100 wallets: ${writeStopwatch.elapsedMilliseconds}ms');

      // Read all wallets
      final readStopwatch = Stopwatch()..start();
      final allWallets = await db.getAllWallets();
      readStopwatch.stop();

      expect(allWallets.length, greaterThanOrEqualTo(100));
      print('Read all wallets: ${readStopwatch.elapsedMilliseconds}ms');
      
      expect(readStopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'Reading 100 wallets should complete within 200ms');

      await db.close();
    });

    test('should handle rapid sequential operations', () async {
      await Hive.deleteFromDisk();
      Hive.init(tempDir.path);

      final db = HiveDatabaseService.instance;
      await db.init();

      final stopwatch = Stopwatch()..start();
      
      // Rapid CRUD operations
      for (int i = 0; i < 100; i++) {
        // Create
        await db.addTransaction(Transaction(
          id: 'rapid_$i',
          amount: 100.0,
          type: TransactionType.expense,
          categoryId: 'expense_food',
          walletId: 'wallet_default',
          createdAt: DateTime.now(),
        ));

        // Read
        await db.getTransaction('rapid_$i');

        // Update
        await db.updateTransaction(Transaction(
          id: 'rapid_$i',
          amount: 150.0,
          type: TransactionType.expense,
          categoryId: 'expense_food',
          walletId: 'wallet_default',
          createdAt: DateTime.now(),
        ));

        // Delete
        await db.deleteTransaction('rapid_$i');
      }

      stopwatch.stop();
      print('100 CRUD cycles: ${stopwatch.elapsedMilliseconds}ms');
      print('Average per cycle: ${stopwatch.elapsedMilliseconds / 100}ms');

      expect(stopwatch.elapsedMilliseconds, lessThan(5000),
          reason: '100 CRUD cycles should complete within 5s');

      await db.close();
    });
  });

  group('Data Integrity', () {
    test('should maintain referential integrity after bulk operations', () async {
      await Hive.deleteFromDisk();
      Hive.init(tempDir.path);

      final db = HiveDatabaseService.instance;
      await db.init();

      // Get initial wallet
      final wallets = await db.getWallets();
      final wallet = wallets.first;
      final initialBalance = wallet.currentBalance;

      // Add 50 incomes and 50 expenses
      double expectedBalance = initialBalance;
      
      for (int i = 0; i < 50; i++) {
        await db.addTransaction(Transaction(
          id: 'integrity_income_$i',
          amount: 100.0,
          type: TransactionType.income,
          categoryId: 'income_salary',
          walletId: wallet.id,
          createdAt: DateTime.now(),
        ));
        expectedBalance += 100.0;

        await db.addTransaction(Transaction(
          id: 'integrity_expense_$i',
          amount: 50.0,
          type: TransactionType.expense,
          categoryId: 'expense_food',
          walletId: wallet.id,
          createdAt: DateTime.now(),
        ));
        expectedBalance -= 50.0;
      }

      // Verify balance integrity
      final finalWallet = await db.getWallet(wallet.id);
      expect(finalWallet!.currentBalance, equals(expectedBalance),
          reason: 'Balance should match expected after bulk operations');

      // Verify transaction count
      final allTx = await db.getTransactions();
      expect(allTx.length, greaterThanOrEqualTo(100));

      await db.close();
    });

    test('should handle update transaction balance correctly', () async {
      await Hive.deleteFromDisk();
      Hive.init(tempDir.path);

      final db = HiveDatabaseService.instance;
      await db.init();

      final wallets = await db.getWallets();
      final wallet = wallets.first;
      final initialBalance = wallet.currentBalance;

      // Add expense
      final tx = Transaction(
        id: 'update_test',
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallet.id,
        createdAt: DateTime.now(),
      );
      await db.addTransaction(tx);

      // Verify balance reduced
      var currentWallet = await db.getWallet(wallet.id);
      expect(currentWallet!.currentBalance, equals(initialBalance - 100.0));

      // Update transaction amount
      final updatedTx = tx.copyWith(amount: 200.0);
      await db.updateTransaction(updatedTx);

      // Verify balance updated correctly (old reversed, new applied)
      currentWallet = await db.getWallet(wallet.id);
      expect(currentWallet!.currentBalance, equals(initialBalance - 200.0));

      await db.close();
    });
  });
}
