import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/models/budget.dart';
import 'package:finsor/models/category.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/wallet.dart';
import 'package:finsor/repositories/budget_repository.dart';
import 'package:finsor/services/hive_database_service.dart';

void main() {
  late HiveDatabaseService db;
  late BudgetRepository repo;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('budget_test_');
    Hive.init(tempDir.path);
    db = HiveDatabaseService.instance;
    await db.init();
    repo = BudgetRepository(db);
  });

  tearDownAll(() async {
    await db.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Budget Status Calculation', () {
    test('should return underBudget for <80% spent', () async {
      final budget = Budget(
        id: 'test_under',
        name: 'Test Under Budget',
        categoryId: 'expense_food',
        amount: 1000,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 15)),
        createdAt: DateTime.now(),
      );
      await db.addBudget(budget);

      // Add expense transactions < 80%
      await db.addTransaction(Transaction(
        id: 'tx_under_1',
        amount: 500, // 50%
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_1',
        createdAt: DateTime.now(),
      ));

      final computed = await repo.getComputedBudget('test_under');
      expect(computed, isNotNull);
      expect(computed!.status, equals(BudgetStatus.underBudget));
      expect(computed.percentageUsed, lessThan(80));

      // Cleanup
      await db.deleteBudget('test_under');
      await db.deleteTransaction('tx_under_1');
    });

    test('should return nearLimit for 80-99% spent', () async {
      final budget = Budget(
        id: 'test_near',
        name: 'Test Near Limit',
        categoryId: 'expense_transport',
        amount: 1000,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 15)),
        warningThreshold: 80,
        createdAt: DateTime.now(),
      );
      await db.addBudget(budget);

      // Add expense transactions = 85%
      await db.addTransaction(Transaction(
        id: 'tx_near_1',
        amount: 850,
        type: TransactionType.expense,
        categoryId: 'expense_transport',
        walletId: 'wallet_1',
        createdAt: DateTime.now(),
      ));

      final computed = await repo.getComputedBudget('test_near');
      expect(computed, isNotNull);
      expect(computed!.status, equals(BudgetStatus.nearLimit));
      expect(computed.percentageUsed, greaterThanOrEqualTo(80));
      expect(computed.percentageUsed, lessThan(100));

      // Cleanup
      await db.deleteBudget('test_near');
      await db.deleteTransaction('tx_near_1');
    });

    test('should return exceeded for >=100% spent', () async {
      final budget = Budget(
        id: 'test_exceeded',
        name: 'Test Exceeded',
        categoryId: 'expense_shopping',
        amount: 500,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 15)),
        createdAt: DateTime.now(),
      );
      await db.addBudget(budget);

      // Add expense transactions > 100%
      await db.addTransaction(Transaction(
        id: 'tx_exceeded_1',
        amount: 600, // 120%
        type: TransactionType.expense,
        categoryId: 'expense_shopping',
        walletId: 'wallet_1',
        createdAt: DateTime.now(),
      ));

      final computed = await repo.getComputedBudget('test_exceeded');
      expect(computed, isNotNull);
      expect(computed!.status, equals(BudgetStatus.exceeded));
      expect(computed.percentageUsed, greaterThanOrEqualTo(100));
      expect(computed.remaining, lessThan(0));

      // Cleanup
      await db.deleteBudget('test_exceeded');
      await db.deleteTransaction('tx_exceeded_1');
    });
  });

  group('Budget Calculation Rules', () {
    test('should only count expenses, not income', () async {
      final budget = Budget(
        id: 'test_expense_only',
        name: 'Expense Only Test',
        categoryId: 'expense_food',
        amount: 1000,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 15)),
        createdAt: DateTime.now(),
      );
      await db.addBudget(budget);

      // Add income (should not count)
      await db.addTransaction(Transaction(
        id: 'tx_income',
        amount: 5000,
        type: TransactionType.income,
        categoryId: 'income_salary',
        walletId: 'wallet_1',
        createdAt: DateTime.now(),
      ));

      // Add expense
      await db.addTransaction(Transaction(
        id: 'tx_expense',
        amount: 200,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_1',
        createdAt: DateTime.now(),
      ));

      final computed = await repo.getComputedBudget('test_expense_only');
      expect(computed, isNotNull);
      expect(computed!.spent, equals(200)); // Only expense counted

      // Cleanup
      await db.deleteBudget('test_expense_only');
      await db.deleteTransaction('tx_income');
      await db.deleteTransaction('tx_expense');
    });

    test('should exclude transfers from budget', () async {
      final budget = Budget(
        id: 'test_no_transfer',
        name: 'No Transfer Test',
        categoryId: null, // All categories
        amount: 1000,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 15)),
        createdAt: DateTime.now(),
      );
      await db.addBudget(budget);

      // Add transfer (should not count)
      await db.addTransaction(Transaction(
        id: 'tx_transfer',
        amount: 500,
        type: TransactionType.transfer,
        categoryId: 'transfer',
        walletId: 'wallet_1',
        toWalletId: 'wallet_2',
        createdAt: DateTime.now(),
      ));

      final computed = await repo.getComputedBudget('test_no_transfer');
      expect(computed, isNotNull);
      expect(computed!.spent, equals(0)); // Transfer not counted

      // Cleanup
      await db.deleteBudget('test_no_transfer');
      await db.deleteTransaction('tx_transfer');
    });

    test('should filter by category when specified', () async {
      final budget = Budget(
        id: 'test_category_filter',
        name: 'Category Filter Test',
        categoryId: 'expense_food',
        amount: 1000,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 15)),
        createdAt: DateTime.now(),
      );
      await db.addBudget(budget);

      // Add matching expense
      await db.addTransaction(Transaction(
        id: 'tx_matching',
        amount: 100,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_1',
        createdAt: DateTime.now(),
      ));

      // Add non-matching expense
      await db.addTransaction(Transaction(
        id: 'tx_non_matching',
        amount: 200,
        type: TransactionType.expense,
        categoryId: 'expense_transport',
        walletId: 'wallet_1',
        createdAt: DateTime.now(),
      ));

      final computed = await repo.getComputedBudget('test_category_filter');
      expect(computed, isNotNull);
      expect(computed!.spent, equals(100)); // Only matching category

      // Cleanup
      await db.deleteBudget('test_category_filter');
      await db.deleteTransaction('tx_matching');
      await db.deleteTransaction('tx_non_matching');
    });
  });

  group('Budget Summary', () {
    test('should return empty summary when no budgets', () async {
      // Clear all budgets first
      final budgets = await db.getBudgets();
      for (final b in budgets) {
        await db.deleteBudget(b.id);
      }

      final summary = await repo.getBudgetSummary();
      expect(summary.totalBudgets, equals(0));
      expect(summary.hasAlerts, isFalse);
    });

    test('should count alerts correctly', () async {
      // Create budgets with different statuses
      await db.addBudget(Budget(
        id: 'sum_under',
        name: 'Under',
        amount: 1000,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 15)),
        createdAt: DateTime.now(),
      ));

      await db.addBudget(Budget(
        id: 'sum_near',
        name: 'Near',
        categoryId: 'expense_near_cat',
        amount: 100,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 15)),
        warningThreshold: 80,
        createdAt: DateTime.now(),
      ));

      // Add expense to trigger near limit
      await db.addTransaction(Transaction(
        id: 'tx_near_sum',
        amount: 85,
        type: TransactionType.expense,
        categoryId: 'expense_near_cat',
        walletId: 'wallet_1',
        createdAt: DateTime.now(),
      ));

      final summary = await repo.getBudgetSummary();
      expect(summary.totalBudgets, greaterThanOrEqualTo(2));
      expect(summary.nearLimitCount, greaterThanOrEqualTo(1));

      // Cleanup
      await db.deleteBudget('sum_under');
      await db.deleteBudget('sum_near');
      await db.deleteTransaction('tx_near_sum');
    });
  });

  group('Budget Alerts', () {
    test('should return only budgets with alerts', () async {
      // Clear existing
      final existing = await db.getBudgets();
      for (final b in existing) {
        await db.deleteBudget(b.id);
      }

      // Create under-budget (no alert)
      await db.addBudget(Budget(
        id: 'alert_under',
        name: 'Under',
        amount: 1000,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 15)),
        createdAt: DateTime.now(),
      ));

      // Create exceeded budget (alert)
      await db.addBudget(Budget(
        id: 'alert_exceeded',
        name: 'Exceeded',
        categoryId: 'expense_alert',
        amount: 100,
        period: BudgetPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 15)),
        createdAt: DateTime.now(),
      ));

      await db.addTransaction(Transaction(
        id: 'tx_alert',
        amount: 150,
        type: TransactionType.expense,
        categoryId: 'expense_alert',
        walletId: 'wallet_1',
        createdAt: DateTime.now(),
      ));

      final alerts = await repo.getBudgetsWithAlerts();
      expect(alerts.length, equals(1));
      expect(alerts.first.budget.id, equals('alert_exceeded'));
      expect(alerts.first.isExceeded, isTrue);

      // Cleanup
      await db.deleteBudget('alert_under');
      await db.deleteBudget('alert_exceeded');
      await db.deleteTransaction('tx_alert');
    });
  });

  group('Parent budget includes child expenses', () {
    test('category budget spent includes transactions in subcategories', () async {
      final parentId = 'parent_cat_sub';
      final childId = 'child_cat_sub';
      final walletId = 'wallet_sub';
      await db.addCategory(Category(
        id: parentId,
        name: 'Parent',
        type: TransactionType.expense,
        color: '#000000',
        iconName: 'restaurant',
        parentId: null,
        isActive: true,
        sortOrder: 0,
        createdAt: DateTime.now(),
      ));
      await db.addCategory(Category(
        id: childId,
        name: 'Child',
        type: TransactionType.expense,
        color: '#000000',
        iconName: 'restaurant',
        parentId: parentId,
        isActive: true,
        sortOrder: 0,
        createdAt: DateTime.now(),
      ));
      await db.addWallet(Wallet(
        id: walletId,
        name: 'W',
        type: WalletType.bank,
        currency: 'USD',
        initialBalance: 0,
        currentBalance: 0,
        createdAt: DateTime.now(),
      ));
      final start = DateTime.now().subtract(const Duration(days: 5));
      final end = DateTime.now().add(const Duration(days: 5));
      await db.addBudget(Budget(
        id: 'bud_sub',
        name: 'Parent Budget',
        categoryId: parentId,
        amount: 500,
        period: BudgetPeriod.monthly,
        startDate: start,
        endDate: end,
        createdAt: DateTime.now(),
      ));
      await db.addTransaction(Transaction(
        id: 'tx_child_1',
        amount: 100,
        type: TransactionType.expense,
        categoryId: childId,
        walletId: walletId,
        createdAt: DateTime.now(),
      ));
      final computed = await repo.getComputedBudget('bud_sub');
      expect(computed, isNotNull);
      expect(computed!.spent, equals(100));
      await db.deleteBudget('bud_sub');
      await db.deleteTransaction('tx_child_1');
      await db.deleteCategory(childId);
      await db.deleteCategory(parentId);
      await db.deleteWallet(walletId);
    });
  });
}
