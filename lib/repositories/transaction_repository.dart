import '../models/transaction.dart';
import '../models/category.dart';
import '../services/hive_database_service.dart';

/// Result of getTransactionsPage: one page of transactions and optional next cursor.
class TransactionPageResult {
  final List<Transaction> page;
  final String? nextCursor;

  const TransactionPageResult({required this.page, this.nextCursor});
}

/// Transaction repository for business logic and aggregations
/// Sits between providers and HiveDatabaseService (low-level storage)
class TransactionRepository {
  final HiveDatabaseService _db;

  TransactionRepository(this._db);

  // ==================== CRUD (delegates to service) ====================

  Future<List<Transaction>> getAll() => _db.getTransactions();

  Future<Transaction?> getById(String id) => _db.getTransaction(id);

  Future<List<Transaction>> getByWallet(String walletId) =>
      _db.getTransactionsByWallet(walletId);

  Future<List<Transaction>> getByCategory(String categoryId) =>
      _db.getTransactionsByCategory(categoryId);

  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) =>
      _db.getTransactionsByDateRange(start, end);

  /// Paginated list. Cursor is opaque (dateMillis_id). Query uses same semantics as filter state.
  Future<TransactionPageResult> getTransactionsPage(
    int limit,
    String? cursor, {
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    String? walletId,
    Set<String>? categoryIds,
    double? amountMin,
    double? amountMax,
  }) async {
    var list = await _db.getTransactions();
    if (startDate != null) {
      list = list.where((t) => !t.createdAt.isBefore(startDate)).toList();
    }
    if (endDate != null) {
      list = list.where((t) => !t.createdAt.isAfter(endDate)).toList();
    }
    if (type != null) {
      list = list.where((t) => t.type == type).toList();
    }
    if (walletId != null) {
      list = list.where((t) => t.walletId == walletId || t.toWalletId == walletId).toList();
    }
    if (categoryIds != null && categoryIds.isNotEmpty) {
      list = list.where((t) => categoryIds.contains(t.categoryId)).toList();
    }
    if (amountMin != null) {
      list = list.where((t) => t.amount >= amountMin).toList();
    }
    if (amountMax != null) {
      list = list.where((t) => t.amount <= amountMax).toList();
    }
    list.sort((a, b) {
      final c = b.createdAt.compareTo(a.createdAt);
      return c != 0 ? c : b.id.compareTo(a.id);
    });
    int skip = 0;
    if (cursor != null && cursor.isNotEmpty) {
      final parts = cursor.split('_');
      if (parts.length >= 2) {
        final cursorMs = int.tryParse(parts[0]);
        final cursorId = parts.sublist(1).join('_');
        if (cursorMs != null && cursorId.isNotEmpty) {
          skip = list.indexWhere((t) {
            final tMs = t.createdAt.millisecondsSinceEpoch;
            if (tMs < cursorMs) return true;
            if (tMs > cursorMs) return false;
            return t.id.compareTo(cursorId) < 0;
          });
          if (skip < 0) skip = list.length;
        }
      }
    }
    final page = list.skip(skip).take(limit).toList();
    final nextCursor = page.isEmpty
        ? null
        : '${page.last.createdAt.millisecondsSinceEpoch}_${page.last.id}';
    return TransactionPageResult(
      page: page,
      nextCursor: page.length < limit ? null : nextCursor,
    );
  }

  Future<void> add(Transaction transaction) => _db.addTransaction(transaction);

  Future<void> update(Transaction transaction) =>
      _db.updateTransaction(transaction);

  Future<void> delete(String id) => _db.deleteTransaction(id);

  Future<List<String>> getSubcategoryIdsForTransaction(String transactionId) async {
    final links = await _db.getTransactionSubcategoryLinks(transactionId);
    return links.map((l) => l.subcategoryId).toList();
  }

  /// Batch resolve subcategory names for given transaction IDs. Returns map txId -> list of subcategory names (order preserved).
  Future<Map<String, List<String>>> getSubcategoryNamesForTransactions(
    List<String> transactionIds,
    List<Category> categories,
  ) async {
    if (transactionIds.isEmpty) return {};
    final allLinks = await _db.getAllTransactionSubcategoryLinks();
    final idSet = transactionIds.toSet();
    final linksForTx = allLinks.where((l) => idSet.contains(l.transactionId)).toList();
    final catById = {for (final c in categories) c.id: c.name};
    final map = <String, List<String>>{};
    for (final link in linksForTx) {
      map.putIfAbsent(link.transactionId, () => []).add(catById[link.subcategoryId] ?? link.subcategoryId);
    }
    return map;
  }

  Future<void> saveTransactionWithSubcategories(
    Transaction transaction,
    List<String> subcategoryIds,
  ) async {
    if (transaction.id.isNotEmpty) {
      final existing = await _db.getTransaction(transaction.id);
      if (existing != null) {
        await _db.updateTransaction(transaction);
      } else {
        await _db.addTransaction(transaction);
      }
    } else {
      await _db.addTransaction(transaction);
    }
    await _db.setTransactionSubcategoryLinks(transaction.id, subcategoryIds);
  }

  /// Category IDs sorted by transaction count in last 30 days (most used first).
  Future<List<String>> getCategoryIdsByUsageLast30Days() async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 30));
    final transactions = await getByDateRange(start, end);
    final count = <String, int>{};
    for (final t in transactions.where((x) => x.type != TransactionType.transfer)) {
      count[t.categoryId] = (count[t.categoryId] ?? 0) + 1;
    }
    final order = count.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return order.map((e) => e.key).toList();
  }

  /// Average expense amount for a category in last 30 days. Returns 0 if none.
  Future<double> getCategoryAverageAmountLast30Days(String categoryId) async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 30));
    final transactions = await getByDateRange(start, end);
    final list = transactions
        .where((t) => t.type == TransactionType.expense && t.categoryId == categoryId)
        .toList();
    if (list.isEmpty) return 0;
    return list.fold<double>(0, (s, t) => s + t.amount) / list.length;
  }

  /// Returns transactions that might be duplicates: same wallet, amount within ±5%, within 24h.
  Future<List<Transaction>> findPotentialDuplicates(Transaction transaction) async {
    final walletTxns = await _db.getTransactionsByWallet(transaction.walletId);
    final low = transaction.amount * 0.95;
    final high = transaction.amount * 1.05;
    final windowStart = transaction.date.subtract(const Duration(hours: 24));
    final windowEnd = transaction.date.add(const Duration(hours: 24));
    return walletTxns.where((t) {
      if (t.id == transaction.id) return false;
      if (t.amount < low || t.amount > high) return false;
      final d = t.date;
      return !d.isBefore(windowStart) && !d.isAfter(windowEnd);
    }).toList();
  }

  // ==================== AGGREGATIONS ====================

  /// Get summary for a date range (income, expenses, balance)
  Future<PeriodSummary> getSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
  }) async {
    var transactions = await getByDateRange(startDate, endDate);

    if (walletId != null) {
      transactions = transactions.where((t) => t.walletId == walletId).toList();
    }

    double income = 0;
    double expenses = 0;
    int incomeCount = 0;
    int expenseCount = 0;

    for (final tx in transactions) {
      switch (tx.type) {
        case TransactionType.income:
          income += tx.amount;
          incomeCount++;
          break;
        case TransactionType.expense:
          expenses += tx.amount;
          expenseCount++;
          break;
        case TransactionType.transfer:
          // Transfers don't affect income/expense summary
          break;
      }
    }

    return PeriodSummary(
      startDate: startDate,
      endDate: endDate,
      income: income,
      expenses: expenses,
      balance: income - expenses,
      incomeCount: incomeCount,
      expenseCount: expenseCount,
      totalCount: transactions.length,
    );
  }

  /// Get monthly summary for current month
  Future<PeriodSummary> getCurrentMonthSummary({String? walletId}) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return getSummary(
      startDate: startOfMonth,
      endDate: endOfMonth,
      walletId: walletId,
    );
  }

  /// Get weekly summary for current week
  Future<PeriodSummary> getCurrentWeekSummary({String? walletId}) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    return getSummary(
      startDate: startDate,
      endDate: endDate,
      walletId: walletId,
    );
  }

  /// Get recent transactions (last N)
  Future<List<Transaction>> getRecent({int limit = 10, String? walletId}) async {
    var transactions = await getAll();

    if (walletId != null) {
      transactions = transactions.where((t) => t.walletId == walletId).toList();
    }

    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return transactions.take(limit).toList();
  }

  /// Get spending by category for a date range
  Future<Map<String, double>> getSpendingByCategory({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
  }) async {
    var transactions = await getByDateRange(startDate, endDate);

    if (walletId != null) {
      transactions = transactions.where((t) => t.walletId == walletId).toList();
    }

    final spending = <String, double>{};
    for (final tx in transactions.where((t) => t.type == TransactionType.expense)) {
      spending[tx.categoryId] = (spending[tx.categoryId] ?? 0) + tx.amount;
    }

    return spending;
  }

  /// Largest single expense in period (for overview). Returns null if none.
  Future<Transaction?> getBiggestExpense({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
  }) async {
    var transactions = await getByDateRange(startDate, endDate);
    if (walletId != null) {
      transactions = transactions.where((t) => t.walletId == walletId).toList();
    }
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    if (expenses.isEmpty) return null;
    expenses.sort((a, b) => b.amount.compareTo(a.amount));
    return expenses.first;
  }
}

/// Period summary data class
class PeriodSummary {
  final DateTime startDate;
  final DateTime endDate;
  final double income;
  final double expenses;
  final double balance;
  final int incomeCount;
  final int expenseCount;
  final int totalCount;

  const PeriodSummary({
    required this.startDate,
    required this.endDate,
    required this.income,
    required this.expenses,
    required this.balance,
    required this.incomeCount,
    required this.expenseCount,
    required this.totalCount,
  });

  bool get isPositive => balance >= 0;

  /// Savings rate % (null when income is 0).
  double? get savingsRatePercent =>
      income > 0 ? (balance / income) * 100 : null;

  /// Days in period (at least 1).
  int get daysInPeriod {
    final d = endDate.difference(startDate).inDays + 1;
    return d < 1 ? 1 : d;
  }

  /// Average daily spend; 0 if no days.
  double get averageDailySpend =>
      daysInPeriod > 0 ? expenses / daysInPeriod : 0.0;
}

/// Period type for filtering
enum PeriodType {
  week,
  month,
  custom,
}
