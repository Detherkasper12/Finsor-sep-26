import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/services/goal_service.dart';
import 'package:finsor/models/goal.dart';
import 'package:finsor/models/wallet.dart';

void main() {
  late HiveDatabaseService db;
  late GoalService goalService;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('goals_sync_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    await Hive.deleteFromDisk();
    Hive.init(tempDir.path);
    db = HiveDatabaseService.instance;
    await db.init();
    goalService = GoalService(db);
  });

  tearDown(() async {
    await db.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Savings goal tests', () {
    late Wallet wallet;
    late Goal savingsGoal;

    setUp(() async {
      wallet = Wallet(
        id: 'wallet_goal_test',
        name: 'GoalWallet',
        type: WalletType.cash,
        currency: 'USD',
        initialBalance: 5000.0,
        currentBalance: 5000.0,
        createdAt: DateTime.now(),
      );
      await db.addWallet(wallet);

      savingsGoal = Goal(
        id: 'goal_savings_1',
        name: 'Emergency Fund',
        type: GoalType.savings,
        targetAmount: 1000.0,
        createdAt: DateTime.now(),
      );
      await db.addGoal(savingsGoal);
    });

    test('addFundsToGoal creates transaction and updates goal', () async {
      await goalService.addFundsToGoal(
        goalId: savingsGoal.id,
        amount: 250.0,
        walletId: wallet.id,
      );

      final updated = await db.getGoal(savingsGoal.id);
      expect(updated!.currentAmount, equals(250.0));
      expect(updated.status, equals(GoalStatus.active));

      final txs = await db.getTransactionsByGoal(savingsGoal.id);
      expect(txs.length, equals(1));
      expect(txs.first.goalId, equals(savingsGoal.id));

      final updatedWallet = await db.getWallet(wallet.id);
      expect(updatedWallet!.currentBalance, equals(4750.0));
    });

    test('goal auto-completes when target reached', () async {
      await goalService.addFundsToGoal(
        goalId: savingsGoal.id,
        amount: 1000.0,
        walletId: wallet.id,
      );

      final updated = await db.getGoal(savingsGoal.id);
      expect(updated!.currentAmount, equals(1000.0));
      expect(updated.status, equals(GoalStatus.completed));
    });

    test('recomputeGoalAmount reconciles from transactions', () async {
      // Use isolated goal to avoid cross-test leakage
      final isolatedGoal = Goal(
        id: 'goal_reconcile_isolated',
        name: 'Reconcile Test',
        type: GoalType.savings,
        targetAmount: 1000.0,
        createdAt: DateTime.now(),
      );
      await db.addGoal(isolatedGoal);

      await goalService.addFundsToGoal(
        goalId: isolatedGoal.id,
        amount: 300.0,
        walletId: wallet.id,
      );

      // Manually drift the goal amount
      final drifted = isolatedGoal.copyWith(currentAmount: 999.0, updatedAt: DateTime.now());
      await db.updateGoal(drifted);

      final driftedGoal = await db.getGoal(isolatedGoal.id);
      expect(driftedGoal!.currentAmount, equals(999.0));

      // Reconcile
      await goalService.recomputeGoalAmount(isolatedGoal.id);

      final reconciled = await db.getGoal(isolatedGoal.id);
      expect(reconciled!.currentAmount, equals(300.0));
    });

    test('verifyAllGoals reconciles all goals', () async {
      // Use isolated goals
      final g1 = Goal(
        id: 'goal_verify_a',
        name: 'Verify A',
        type: GoalType.savings,
        targetAmount: 1000.0,
        createdAt: DateTime.now(),
      );
      final g2 = Goal(
        id: 'goal_verify_b',
        name: 'Verify B',
        type: GoalType.savings,
        targetAmount: 500.0,
        createdAt: DateTime.now(),
      );
      await db.addGoal(g1);
      await db.addGoal(g2);

      await goalService.addFundsToGoal(goalId: g1.id, amount: 100.0, walletId: wallet.id);
      await goalService.addFundsToGoal(goalId: g2.id, amount: 200.0, walletId: wallet.id);

      // Drift both
      await db.updateGoal(g1.copyWith(currentAmount: 0.0, updatedAt: DateTime.now()));
      await db.updateGoal(g2.copyWith(currentAmount: 0.0, updatedAt: DateTime.now()));

      await goalService.verifyAllGoals();

      final r1 = await db.getGoal(g1.id);
      final r2 = await db.getGoal(g2.id);
      expect(r1!.currentAmount, equals(100.0));
      expect(r2!.currentAmount, equals(200.0));
    });
  });

  group('Debt goal tests', () {
    late Wallet wallet;
    late Goal debtGoal;

    setUp(() async {
      wallet = Wallet(
        id: 'wallet_debt_test',
        name: 'DebtWallet',
        type: WalletType.bank,
        currency: 'USD',
        initialBalance: 3000.0,
        currentBalance: 3000.0,
        createdAt: DateTime.now(),
      );
      await db.addWallet(wallet);

      debtGoal = Goal(
        id: 'goal_debt_1',
        name: 'Student Loan',
        type: GoalType.debt,
        targetAmount: 500.0,
        debtorName: 'Bank of Test',
        createdAt: DateTime.now(),
      );
      await db.addGoal(debtGoal);
    });

    test('recordDebtPayment creates transaction and updates goal', () async {
      await goalService.recordDebtPayment(
        goalId: debtGoal.id,
        amount: 100.0,
        walletId: wallet.id,
        description: 'Monthly payment',
      );

      final updated = await db.getGoal(debtGoal.id);
      expect(updated!.currentAmount, equals(100.0));

      final txs = await db.getTransactionsByGoal(debtGoal.id);
      expect(txs.length, equals(1));
      expect(txs.first.description, equals('Monthly payment'));
    });

    test('debt completes when fully paid', () async {
      await goalService.recordDebtPayment(
        goalId: debtGoal.id,
        amount: 500.0,
        walletId: wallet.id,
      );

      final updated = await db.getGoal(debtGoal.id);
      expect(updated!.status, equals(GoalStatus.completed));
    });
  });
}
