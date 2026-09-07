import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../repositories/budget_repository.dart';
import 'database_provider.dart';
import 'sync_provider.dart';

/// Provider for BudgetRepository
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final db = ref.read(databaseServiceProvider);
  return BudgetRepository(db);
});

/// Provider for all raw budgets from database
final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  return await db.getBudgets();
});

/// Provider for computed budgets with real spending data
final computedBudgetsProvider = FutureProvider<List<ComputedBudget>>((ref) async {
  final repo = ref.read(budgetRepositoryProvider);
  return await repo.getComputedBudgets();
});

/// Provider for active computed budgets only
final activeBudgetsProvider = FutureProvider<List<ComputedBudget>>((ref) async {
  final computed = await ref.watch(computedBudgetsProvider.future);
  return computed.where((cb) => cb.budget.isActive).toList();
});

/// Provider for budgets with alerts (near limit or exceeded)
final budgetAlertsProvider = FutureProvider<List<ComputedBudget>>((ref) async {
  final repo = ref.read(budgetRepositoryProvider);
  return await repo.getBudgetsWithAlerts();
});

/// Provider for budget summary (for dashboard indicators)
final budgetSummaryProvider = FutureProvider<BudgetSummary>((ref) async {
  final repo = ref.read(budgetRepositoryProvider);
  return await repo.getBudgetSummary();
});

/// Provider for a single computed budget by ID
final computedBudgetProvider = FutureProvider.family<ComputedBudget?, String>((ref, id) async {
  final repo = ref.read(budgetRepositoryProvider);
  return await repo.getComputedBudget(id);
});

/// Provider for budgets by category
final budgetsByCategoryProvider = FutureProvider.family<List<ComputedBudget>, String>((ref, categoryId) async {
  final computed = await ref.watch(computedBudgetsProvider.future);
  return computed.where((cb) => cb.budget.categoryId == categoryId).toList();
});

/// Notifier for budget CRUD operations
class BudgetNotifier extends StateNotifier<AsyncValue<void>> {
  BudgetNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  /// Add new budget
  Future<void> addBudget(Budget budget) async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseServiceProvider);
      await db.addBudget(budget);
      enqueueSyncOp(_ref, entityType: 'budgets', entityId: budget.id,
          opType: 'upsert', payload: budget.toJson());
      _invalidateProviders();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Budget?> createBudget({
    required String name,
    String? categoryId,
    String? walletId,
    required double amount,
    required BudgetPeriod period,
    double warningThreshold = 80.0,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(budgetRepositoryProvider);
      if (categoryId != null && walletId != null) {
        throw ArgumentError('Budget type must be global, category, or wallet - not both category and wallet.');
      }
      final budget = await repo.createBudget(
        name: name,
        categoryId: categoryId,
        walletId: walletId,
        amount: amount,
        period: period,
        warningThreshold: warningThreshold,
        description: description,
      );
      enqueueSyncOp(_ref, entityType: 'budgets', entityId: budget.id,
          opType: 'upsert', payload: budget.toJson());
      _invalidateProviders();
      state = const AsyncValue.data(null);
      return budget;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update existing budget
  Future<void> updateBudget(Budget budget) async {
    if (budget.categoryId != null && budget.walletId != null) {
      throw ArgumentError('Budget type must be global, category, or wallet - not both.');
    }
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseServiceProvider);
      final updated = budget.copyWith(updatedAt: DateTime.now());
      await db.updateBudget(updated);
      enqueueSyncOp(_ref, entityType: 'budgets', entityId: budget.id,
          opType: 'upsert', payload: updated.toJson());
      _invalidateProviders();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete budget
  Future<void> deleteBudget(String id) async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseServiceProvider);
      await db.deleteBudget(id);
      enqueueSyncOp(_ref, entityType: 'budgets', entityId: id,
          opType: 'delete', payload: {'id': id});
      _invalidateProviders();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _invalidateProviders() {
    _ref.invalidate(budgetsProvider);
    _ref.invalidate(computedBudgetsProvider);
    _ref.invalidate(activeBudgetsProvider);
    _ref.invalidate(budgetAlertsProvider);
    _ref.invalidate(budgetSummaryProvider);
  }
}

/// Provider for budget operations
final budgetNotifierProvider = StateNotifierProvider<BudgetNotifier, AsyncValue<void>>((ref) {
  return BudgetNotifier(ref);
});
