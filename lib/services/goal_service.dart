import 'package:flutter/foundation.dart' show debugPrint;
import '../models/goal.dart';
import '../models/transaction.dart';
import 'hive_database_service.dart';

class GoalService {
  final HiveDatabaseService _db;

  GoalService(this._db);

  /// Add funds to a savings goal. Creates a linked expense transaction
  /// (money moves from wallet into the goal).
  Future<Transaction> addFundsToGoal({
    required String goalId,
    required double amount,
    required String walletId,
    String? description,
  }) async {
    final goal = await _db.getGoal(goalId);
    if (goal == null) throw Exception('Goal not found');

    final tx = Transaction(
      id: 'goal_${goalId}_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      type: TransactionType.expense,
      categoryId: 'cat_savings',
      walletId: walletId,
      description: description ?? 'Savings: ${goal.name}',
      createdAt: DateTime.now(),
      goalId: goalId,
    );
    await _db.addTransaction(tx);

    final updated = goal.copyWith(
      currentAmount: goal.currentAmount + amount,
      status: (goal.currentAmount + amount) >= goal.targetAmount
          ? GoalStatus.completed
          : GoalStatus.active,
      updatedAt: DateTime.now(),
    );
    await _db.updateGoal(updated);

    return tx;
  }

  /// Record a debt payment. Creates a linked expense transaction.
  Future<Transaction> recordDebtPayment({
    required String goalId,
    required double amount,
    required String walletId,
    String? description,
  }) async {
    final goal = await _db.getGoal(goalId);
    if (goal == null) throw Exception('Goal not found');

    final tx = Transaction(
      id: 'goal_${goalId}_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      type: TransactionType.expense,
      categoryId: 'cat_debt_payment',
      walletId: walletId,
      description: description ?? 'Payment: ${goal.name}',
      createdAt: DateTime.now(),
      goalId: goalId,
    );
    await _db.addTransaction(tx);

    final updated = goal.copyWith(
      currentAmount: goal.currentAmount + amount,
      status: (goal.currentAmount + amount) >= goal.targetAmount
          ? GoalStatus.completed
          : GoalStatus.active,
      updatedAt: DateTime.now(),
    );
    await _db.updateGoal(updated);

    return tx;
  }

  /// Recompute goal progress from linked transactions (reconciliation).
  Future<void> recomputeGoalAmount(String goalId) async {
    final goal = await _db.getGoal(goalId);
    if (goal == null) return;

    final txs = await _db.getTransactionsByGoal(goalId);
    final computed = txs.fold<double>(0.0, (sum, tx) => sum + tx.amount);

    if ((goal.currentAmount - computed).abs() > 0.01) {
      debugPrint('[GoalService] Reconciling ${goal.name}: ${goal.currentAmount} -> $computed');
      final updated = goal.copyWith(
        currentAmount: computed,
        status: computed >= goal.targetAmount
            ? GoalStatus.completed
            : GoalStatus.active,
        updatedAt: DateTime.now(),
      );
      await _db.updateGoal(updated);
    }
  }

  /// Verify and reconcile all goals.
  Future<void> verifyAllGoals() async {
    final goals = await _db.getGoals();
    for (final goal in goals) {
      await recomputeGoalAmount(goal.id);
    }
    debugPrint('[GoalService] Verified ${goals.length} goals');
  }
}
