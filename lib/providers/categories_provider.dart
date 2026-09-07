import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'analytics_providers.dart';
import 'budgets_provider.dart';
import 'database_provider.dart';
import 'insights_providers.dart';
import 'repository_providers.dart';
import 'sync_provider.dart';
import 'transaction_provider.dart' hide recentTransactionsProvider;

/// Provider for all categories
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getCategories();
});

/// Provider for income categories
final incomeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getCategoriesByType(TransactionType.income);
});

/// Provider for expense categories
final expenseCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getCategoriesByType(TransactionType.expense);
});

/// Provider for a single category by ID
final categoryProvider = FutureProvider.family<Category?, String>((ref, id) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getCategory(id);
});

/// Provider for subcategories of a given parent
final subcategoriesProvider = FutureProvider.family<List<Category>, String>((ref, parentId) async {
  final all = await ref.watch(categoriesProvider.future);
  return all.where((c) => c.parentId == parentId && c.isActive).toList();
});

/// Categories sorted by usage (last 30 days), most used first
final categoriesByUsageProvider = FutureProvider<List<Category>>((ref) async {
  final categories = await ref.watch(categoriesProvider.future);
  final repo = ref.read(transactionRepositoryProvider);
  final order = await repo.getCategoryIdsByUsageLast30Days();
  final byId = {for (final c in categories) c.id: c};
  final result = order
      .map((id) => byId[id])
      .whereType<Category>()
      .where((c) => c.isActive)
      .toList();
  final resultIds = result.map((c) => c.id).toSet();
  for (final c in categories) {
    if (c.isActive && !resultIds.contains(c.id)) result.add(c);
  }
  return result;
});

/// Average expense amount for a category in last 30 days (for anomaly detection)
final categoryAverageAmountProvider = FutureProvider.family<double, String>((ref, categoryId) async {
  final repo = ref.read(transactionRepositoryProvider);
  return repo.getCategoryAverageAmountLast30Days(categoryId);
});

/// Provider for transaction count per category
final transactionCountByCategoryProvider = FutureProvider.family<int, String>((ref, categoryId) async {
  final db = ref.read(databaseServiceProvider);
  return await db.getTransactionCountByCategory(categoryId);
});

/// Notifier for category operations
class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  CategoryNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  /// Add new category
  Future<void> addCategory(Category category) async {
    state = const AsyncValue.loading();
    try {
      final databaseService = ref.read(databaseServiceProvider);
      await databaseService.addCategory(category);
      enqueueSyncOp(ref, entityType: 'categories', entityId: category.id,
          opType: 'upsert', payload: category.toJson());
      
      ref.invalidate(categoriesProvider);
      ref.invalidate(incomeCategoriesProvider);
      ref.invalidate(expenseCategoriesProvider);
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update existing category
  Future<void> updateCategory(Category category) async {
    state = const AsyncValue.loading();
    try {
      final databaseService = ref.read(databaseServiceProvider);
      await databaseService.updateCategory(category);
      enqueueSyncOp(ref, entityType: 'categories', entityId: category.id,
          opType: 'upsert', payload: category.toJson());
      
      ref.invalidate(categoriesProvider);
      ref.invalidate(incomeCategoriesProvider);
      ref.invalidate(expenseCategoriesProvider);
      ref.invalidate(categoryProvider(category.id));
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete category (soft delete). If transactions exist, pass reassignToId.
  Future<void> deleteCategory(String id, {String? reassignToId}) async {
    state = const AsyncValue.loading();
    try {
      final databaseService = ref.read(databaseServiceProvider);
      final count = await databaseService.getTransactionCountByCategory(id);
      if (count > 0) {
        if (reassignToId == null || reassignToId == id) {
          throw CategoryHasTransactionsException(id, count);
        }
        await databaseService.reassignTransactionsToCategory(id, reassignToId);
        ref.invalidate(transactionsProvider);
        ref.invalidate(periodSummaryProvider);
        ref.invalidate(budgetsProvider);
        ref.invalidate(computedBudgetsProvider);
        ref.invalidate(currentMonthCategoryBreakdownProvider);
        ref.invalidate(insightsProvider);
      }
      await databaseService.deleteCategory(id);
      enqueueSyncOp(ref, entityType: 'categories', entityId: id,
          opType: 'delete', payload: {'id': id});
      ref.invalidate(categoriesProvider);
      ref.invalidate(incomeCategoriesProvider);
      ref.invalidate(expenseCategoriesProvider);
      ref.invalidate(categoryProvider(id));
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Reorder categories by id list (order = sortOrder)
  Future<void> reorderCategories(List<String> orderedIds) async {
    state = const AsyncValue.loading();
    try {
      final databaseService = ref.read(databaseServiceProvider);
      for (var i = 0; i < orderedIds.length; i++) {
        final cat = await databaseService.getCategory(orderedIds[i]);
        if (cat != null && cat.sortOrder != i) {
          final updated = cat.copyWith(sortOrder: i, updatedAt: DateTime.now());
          await databaseService.updateCategory(updated);
          enqueueSyncOp(ref, entityType: 'categories', entityId: cat.id,
              opType: 'upsert', payload: updated.toJson());
        }
      }
      ref.invalidate(categoriesProvider);
      ref.invalidate(incomeCategoriesProvider);
      ref.invalidate(expenseCategoriesProvider);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class CategoryHasTransactionsException implements Exception {
  final String categoryId;
  final int count;
  CategoryHasTransactionsException(this.categoryId, this.count);
  @override
  String toString() => 'Category has $count transaction(s). Reassign before delete.';
}

/// Provider for category operations
final categoryNotifierProvider = 
    StateNotifierProvider<CategoryNotifier, AsyncValue<void>>((ref) {
  return CategoryNotifier(ref);
});
