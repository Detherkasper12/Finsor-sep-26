import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import 'analytics_providers.dart';
import 'budgets_provider.dart';
import 'categories_provider.dart';
import 'database_provider.dart';
import 'insights_providers.dart';
import 'repository_providers.dart';
import 'sync_provider.dart';
import 'wallet_provider.dart';
import '../screens/transactions/transaction_filter_sheet.dart';

/// Provider for all transactions
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getTransactions();
});

/// Provider for transactions by wallet
final transactionsByWalletProvider =
    FutureProvider.family<List<Transaction>, String>((ref, walletId) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getTransactionsByWallet(walletId);
});

/// Provider for transactions by category
final transactionsByCategoryProvider =
    FutureProvider.family<List<Transaction>, String>((ref, categoryId) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getTransactionsByCategory(categoryId);
});

/// Provider for transactions by date range
final transactionsByDateRangeProvider = FutureProvider.family<List<Transaction>,
    ({DateTime startDate, DateTime endDate})>((ref, params) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getTransactionsByDateRange(
    params.startDate,
    params.endDate,
  );
});

/// Provider for single transaction
final transactionProvider =
    FutureProvider.family<Transaction?, String>((ref, id) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getTransaction(id);
});

/// Subcategory names per transaction ID for list display. Key: sorted transaction IDs joined by comma.
final subcategoryNamesForTransactionsProvider =
    FutureProvider.family<Map<String, List<String>>, String>((ref, idListKey) async {
  if (idListKey.isEmpty) return {};
  final ids = idListKey.split(',');
  final repo = ref.read(transactionRepositoryProvider);
  final categories = await ref.read(categoriesProvider.future);
  return repo.getSubcategoryNamesForTransactions(ids, categories);
});

/// Provider for recent transactions (last 30 days)
final recentTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  final endDate = DateTime.now();
  final startDate = endDate.subtract(const Duration(days: 30));
  final transactions = await databaseService.getTransactionsByDateRange(
    startDate,
    endDate,
  );

  // Sort by date descending
  transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return transactions;
});

/// Provider for today's transactions
final todayTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return await databaseService.getTransactionsByDateRange(startOfDay, endOfDay);
});

/// Provider for this week's transactions
final thisWeekTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfWeekDay =
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  final endOfWeek = startOfWeekDay
      .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

  return await databaseService.getTransactionsByDateRange(
      startOfWeekDay, endOfWeek);
});

/// Provider for this month's transactions
final thisMonthTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  return await databaseService.getTransactionsByDateRange(
      startOfMonth, endOfMonth);
});

/// State for paginated transactions list (accumulated pages + next cursor).
class TransactionsPageState {
  final List<Transaction> list;
  final String? nextCursor;
  final bool isLoadingMore;

  const TransactionsPageState({
    this.list = const [],
    this.nextCursor,
    this.isLoadingMore = false,
  });
}

/// Notifier for paginated transactions list. Call setQuery then loadFirstPage; loadMore for infinite scroll.
class TransactionsPageNotifier extends StateNotifier<AsyncValue<TransactionsPageState>> {
  TransactionsPageNotifier(this.ref) : super(const AsyncValue.data(TransactionsPageState()));

  final Ref ref;
  DateTime? _startDate;
  DateTime? _endDate;
  TransactionFilterState _filterState = TransactionFilterState.empty;
  Set<String>? _categoryIds;

  bool get hasQuery => _startDate != null;

  void setQuery({
    required DateTime startDate,
    required DateTime endDate,
    TransactionFilterState? filterState,
    Set<String>? categoryIds,
  }) {
    _startDate = startDate;
    _endDate = endDate;
    _filterState = filterState ?? TransactionFilterState.empty;
    _categoryIds = categoryIds;
  }

  Future<void> refresh() async {
    if (!hasQuery) return;
    await loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(transactionRepositoryProvider);
      final result = await repo.getTransactionsPage(
        200,
        null,
        startDate: _startDate,
        endDate: _endDate,
        type: _filterState.type,
        walletId: _filterState.walletId,
        categoryIds: _categoryIds,
        amountMin: _filterState.amountMin,
        amountMax: _filterState.amountMax,
      );
      state = AsyncValue.data(TransactionsPageState(
        list: result.page,
        nextCursor: result.nextCursor,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.nextCursor == null || current.isLoadingMore) return;
    state = AsyncValue.data(TransactionsPageState(
      list: current.list,
      nextCursor: current.nextCursor,
      isLoadingMore: true,
    ));
    try {
      final repo = ref.read(transactionRepositoryProvider);
      final result = await repo.getTransactionsPage(
        200,
        current.nextCursor,
        startDate: _startDate,
        endDate: _endDate,
        type: _filterState.type,
        walletId: _filterState.walletId,
        categoryIds: _categoryIds,
        amountMin: _filterState.amountMin,
        amountMax: _filterState.amountMax,
      );
      final prev = state.valueOrNull ?? current;
      state = AsyncValue.data(TransactionsPageState(
        list: [...prev.list, ...result.page],
        nextCursor: result.nextCursor,
      ));
    } catch (e) {
      state = AsyncValue.data(TransactionsPageState(
        list: current.list,
        nextCursor: current.nextCursor,
        isLoadingMore: false,
      ));
    }
  }

  void reset() {
    state = const AsyncValue.data(TransactionsPageState());
  }
}

final transactionsPageNotifierProvider =
    StateNotifierProvider<TransactionsPageNotifier, AsyncValue<TransactionsPageState>>((ref) {
  return TransactionsPageNotifier(ref);
});

/// Balance (begin, end) for a given month for the transactions screen. Optional wallet filter.
final transactionsMonthBalanceProvider =
    FutureProvider.family<({double begin, double end}), ({DateTime month, String? walletId})>((ref, params) async {
  final repo = ref.read(transactionRepositoryProvider);
  final monthStart = DateTime(params.month.year, params.month.month);
  final monthEnd = DateTime(params.month.year, params.month.month + 1, 0, 23, 59, 59);
  final before = await repo.getSummary(startDate: DateTime(2020), endDate: monthStart, walletId: params.walletId);
  final month = await repo.getSummary(startDate: monthStart, endDate: monthEnd, walletId: params.walletId);
  return (begin: before.balance, end: before.balance + month.balance);
});

/// Notify all providers that depend on transactions
void _invalidateTransactionDependents(
  Ref ref, {
  String? walletId,
  String? categoryId,
  String? oldWalletId,
  String? oldCategoryId,
  String? transactionId,
}) {
  ref.invalidate(transactionsProvider);
  final pageNotifier = ref.read(transactionsPageNotifierProvider.notifier);
  if (pageNotifier.hasQuery) pageNotifier.refresh();
  ref.invalidate(transactionsMonthBalanceProvider);
  ref.invalidate(recentTransactionsProvider);
  ref.invalidate(todayTransactionsProvider);
  ref.invalidate(thisWeekTransactionsProvider);
  ref.invalidate(thisMonthTransactionsProvider);
  ref.invalidate(periodSummaryProvider);
  ref.invalidate(walletsProvider);
  ref.invalidate(activeWalletsProvider);
  ref.invalidate(totalBalanceProvider);
  ref.invalidate(balancesByCurrencyProvider);
  ref.invalidate(budgetsProvider);
  ref.invalidate(computedBudgetsProvider);
  ref.invalidate(activeBudgetsProvider);
  ref.invalidate(budgetAlertsProvider);
  ref.invalidate(budgetSummaryProvider);
  ref.invalidate(currentMonthCategoryBreakdownProvider);
  ref.invalidate(currentMonthDailySeriesProvider);
  ref.invalidate(weeklySeriesProvider);
  ref.invalidate(monthlySeriesProvider);
  ref.invalidate(monthOverMonthComparisonProvider);
  ref.invalidate(weekOverWeekComparisonProvider);
  ref.invalidate(walletAnalyticsProvider);
  ref.invalidate(insightsProvider);
  if (walletId != null) ref.invalidate(transactionsByWalletProvider(walletId));
  if (categoryId != null)
    ref.invalidate(transactionsByCategoryProvider(categoryId));
  if (oldWalletId != null && oldWalletId != walletId)
    ref.invalidate(transactionsByWalletProvider(oldWalletId));
  if (oldCategoryId != null && oldCategoryId != categoryId)
    ref.invalidate(transactionsByCategoryProvider(oldCategoryId));
  if (transactionId != null) ref.invalidate(transactionProvider(transactionId));
  if (walletId != null) ref.invalidate(walletProvider(walletId));
  if (oldWalletId != null) ref.invalidate(walletProvider(oldWalletId));
}

/// Notifier for transaction operations
class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  TransactionNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> addTransaction(Transaction transaction) async {
    state = const AsyncValue.loading();
    try {
      final databaseService = ref.read(databaseServiceProvider);
      await databaseService.addTransaction(transaction);
      enqueueSyncOp(ref, entityType: 'transactions', entityId: transaction.id,
          opType: 'upsert', payload: transaction.toJson());
      _invalidateTransactionDependents(ref,
          walletId: transaction.walletId, categoryId: transaction.categoryId);
      if (transaction.toWalletId != null)
        ref.invalidate(walletProvider(transaction.toWalletId!));
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    state = const AsyncValue.loading();
    try {
      final databaseService = ref.read(databaseServiceProvider);
      final old = await databaseService.getTransaction(transaction.id);
      await databaseService.updateTransaction(transaction);
      enqueueSyncOp(ref, entityType: 'transactions', entityId: transaction.id,
          opType: 'upsert', payload: transaction.toJson());
      _invalidateTransactionDependents(
        ref,
        walletId: transaction.walletId,
        categoryId: transaction.categoryId,
        oldWalletId: old?.walletId,
        oldCategoryId: old?.categoryId,
        transactionId: transaction.id,
      );
      if (transaction.toWalletId != null)
        ref.invalidate(walletProvider(transaction.toWalletId!));
      if (old?.toWalletId != null)
        ref.invalidate(walletProvider(old!.toWalletId!));
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteTransaction(String id) async {
    state = const AsyncValue.loading();
    try {
      final databaseService = ref.read(databaseServiceProvider);
      final old = await databaseService.getTransaction(id);
      await databaseService.deleteTransaction(id);
      enqueueSyncOp(ref, entityType: 'transactions', entityId: id,
          opType: 'delete', payload: {'id': id});
      _invalidateTransactionDependents(ref,
          walletId: old?.walletId,
          categoryId: old?.categoryId,
          transactionId: id);
      final tw = old?.toWalletId;
      if (tw != null) ref.invalidate(walletProvider(tw));
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for transaction operations
final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<void>>((ref) {
  return TransactionNotifier(ref);
});
