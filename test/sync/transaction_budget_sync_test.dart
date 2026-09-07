import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/budget.dart';
import 'package:finsor/repositories/budget_repository.dart';

void main() {
  late HiveDatabaseService db;
  late BudgetRepository budgetRepo;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_budget_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    await Hive.deleteFromDisk();
    Hive.init(tempDir.path);
    db = HiveDatabaseService.instance;
    await db.init();
    budgetRepo = BudgetRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Transaction -> Budget spent sync', () {
    Future<Budget> _createTestBudget() async {
      final budget = await budgetRepo.createBudget(
        name: 'Food Budget',
        categoryId: 'expense_food',
        amount: 500.0,
        period: BudgetPeriod.monthly,
      );
      return budget;
    }

    test('Add expense in budgeted category increases budget spent', () async {
      final budget = await _createTestBudget();
      final wallets = await db.getWallets();
      expect(wallets.isNotEmpty, true);

      await db.addTransaction(Transaction(
        id: 'tx_budget_1',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallets.first.id,
        createdAt: DateTime.now(),
      ));

      final computed = await budgetRepo.getComputedBudget(budget.id);
      expect(computed, isNotNull);
      expect(computed!.spent, greaterThanOrEqualTo(50.0));
    });

    test('Delete expense decreases budget spent', () async {
      final budget = await _createTestBudget();
      final wallets = await db.getWallets();

      await db.addTransaction(Transaction(
        id: 'tx_budget_del',
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallets.first.id,
        createdAt: DateTime.now(),
      ));

      final before = await budgetRepo.getComputedBudget(budget.id);
      expect(before!.spent, greaterThanOrEqualTo(100.0));

      await db.deleteTransaction('tx_budget_del');

      final after = await budgetRepo.getComputedBudget(budget.id);
      expect(after!.spent, lessThan(before.spent));
    });

    test('Edit expense amount updates budget spent', () async {
      final budget = await _createTestBudget();
      final wallets = await db.getWallets();

      final tx = Transaction(
        id: 'tx_budget_edit',
        amount: 80.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallets.first.id,
        createdAt: DateTime.now(),
      );
      await db.addTransaction(tx);

      final beforeEdit = await budgetRepo.getComputedBudget(budget.id);

      final updated = Transaction(
        id: tx.id,
        amount: 150.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallets.first.id,
        createdAt: tx.createdAt,
        updatedAt: DateTime.now(),
      );
      await db.updateTransaction(updated);

      final afterEdit = await budgetRepo.getComputedBudget(budget.id);
      expect(afterEdit!.spent, greaterThan(beforeEdit!.spent));
    });

    test('Change category from budgeted to non-budgeted frees budget', () async {
      final budget = await _createTestBudget();
      final wallets = await db.getWallets();

      final tx = Transaction(
        id: 'tx_budget_cat_change',
        amount: 60.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallets.first.id,
        createdAt: DateTime.now(),
      );
      await db.addTransaction(tx);

      final before = await budgetRepo.getComputedBudget(budget.id);
      expect(before!.spent, greaterThanOrEqualTo(60.0));

      final updated = Transaction(
        id: tx.id,
        amount: 60.0,
        type: TransactionType.expense,
        categoryId: 'expense_transport',
        walletId: wallets.first.id,
        createdAt: tx.createdAt,
        updatedAt: DateTime.now(),
      );
      await db.updateTransaction(updated);

      final after = await budgetRepo.getComputedBudget(budget.id);
      expect(after!.spent, lessThan(before.spent));
    });
  });
}
