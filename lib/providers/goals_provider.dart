import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goal.dart';
import '../models/transaction.dart';
import '../services/goal_service.dart';
import 'database_provider.dart';
import 'sync_provider.dart';
import 'transaction_provider.dart';
import 'wallet_provider.dart';

final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  return await db.getGoals();
});

final activeGoalsProvider = FutureProvider<List<Goal>>((ref) async {
  final goals = await ref.watch(goalsProvider.future);
  return goals.where((g) => g.status == GoalStatus.active).toList();
});

final savingsGoalsProvider = FutureProvider<List<Goal>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  return await db.getGoalsByType(GoalType.savings);
});

final debtGoalsProvider = FutureProvider<List<Goal>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  return await db.getGoalsByType(GoalType.debt);
});

final goalProvider =
    FutureProvider.family<Goal?, String>((ref, id) async {
  final db = ref.read(databaseServiceProvider);
  return await db.getGoal(id);
});

final goalTransactionsProvider =
    FutureProvider.family<List<Transaction>, String>((ref, goalId) async {
  final db = ref.read(databaseServiceProvider);
  return await db.getTransactionsByGoal(goalId);
});

final goalServiceProvider = Provider<GoalService>((ref) {
  return GoalService(ref.read(databaseServiceProvider));
});

class GoalNotifier extends StateNotifier<AsyncValue<void>> {
  GoalNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  void _invalidateAll([String? goalId]) {
    ref.invalidate(goalsProvider);
    ref.invalidate(activeGoalsProvider);
    ref.invalidate(savingsGoalsProvider);
    ref.invalidate(debtGoalsProvider);
    if (goalId != null) {
      ref.invalidate(goalProvider(goalId));
      ref.invalidate(goalTransactionsProvider(goalId));
    }
  }

  Future<void> addGoal(Goal goal) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseServiceProvider);
      await db.addGoal(goal);
      enqueueSyncOp(ref, entityType: 'goals', entityId: goal.id,
          opType: 'upsert', payload: goal.toJson());
      _invalidateAll(goal.id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateGoal(Goal goal) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseServiceProvider);
      await db.updateGoal(goal);
      enqueueSyncOp(ref, entityType: 'goals', entityId: goal.id,
          opType: 'upsert', payload: goal.toJson());
      _invalidateAll(goal.id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteGoal(String id) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseServiceProvider);
      await db.deleteGoal(id);
      enqueueSyncOp(ref, entityType: 'goals', entityId: id,
          opType: 'delete', payload: {'id': id});
      _invalidateAll(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFunds({
    required String goalId,
    required double amount,
    required String walletId,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(goalServiceProvider);
      await service.addFundsToGoal(
        goalId: goalId,
        amount: amount,
        walletId: walletId,
        description: description,
      );
      _invalidateAll(goalId);
      ref.invalidate(transactionsProvider);
      ref.invalidate(walletsProvider);
      ref.invalidate(totalBalanceProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> recordPayment({
    required String goalId,
    required double amount,
    required String walletId,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(goalServiceProvider);
      await service.recordDebtPayment(
        goalId: goalId,
        amount: amount,
        walletId: walletId,
        description: description,
      );
      _invalidateAll(goalId);
      ref.invalidate(transactionsProvider);
      ref.invalidate(walletsProvider);
      ref.invalidate(totalBalanceProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reconcile(String goalId) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(goalServiceProvider);
      await service.recomputeGoalAmount(goalId);
      _invalidateAll(goalId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final goalNotifierProvider =
    StateNotifierProvider<GoalNotifier, AsyncValue<void>>((ref) {
  return GoalNotifier(ref);
});
