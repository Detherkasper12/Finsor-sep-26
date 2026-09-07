import '../models/transaction.dart';
import '../models/wallet.dart';
import '../services/hive_database_service.dart';
import 'analytics_models.dart';

/// Analytics repository for read-only aggregations and analytics
/// All aggregation logic lives here - providers are thin adapters only
///
/// CORRECTNESS RULES:
/// - Transfers are EXCLUDED from income/expense totals everywhere
/// - Custom date range comparison uses same duration, immediately preceding period
/// - Time series `balance` field is cumulative net flow (income - expenses)
///   BUT the UI should display per-bucket net flow, not cumulative balance,
///   since we don't have a verified opening balance
class AnalyticsRepository {
  final HiveDatabaseService _db;

  AnalyticsRepository(this._db);

  // ==================== CATEGORY BREAKDOWN ====================

  /// Get expense breakdown by category for a period
  Future<CategoryBreakdown> getCategoryBreakdown({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    TransactionType type = TransactionType.expense,
  }) async {
    final transactions = await _getFilteredTransactions(
      startDate: startDate,
      endDate: endDate,
      walletId: walletId,
    );

    // Filter by type and exclude transfers
    final filtered = transactions
        .where((t) => t.type == type)
        .toList();

    if (filtered.isEmpty) {
      return CategoryBreakdown(
        startDate: startDate,
        endDate: endDate,
        categories: [],
        totalAmount: 0,
        totalTransactions: 0,
      );
    }

    // Group by category - single pass aggregation
    final categoryMap = <String, _CategoryAccumulator>{};
    double totalAmount = 0;

    for (final tx in filtered) {
      totalAmount += tx.amount;
      final acc = categoryMap.putIfAbsent(
        tx.categoryId,
        () => _CategoryAccumulator(tx.categoryId),
      );
      acc.amount += tx.amount;
      acc.count++;
    }

    // Get category names
    final categories = await _db.getCategories();
    final categoryNameMap = {for (final c in categories) c.id: c.name};

    // Build summaries with percentages
    final summaries = categoryMap.entries.map((entry) {
      final acc = entry.value;
      return CategorySummary(
        categoryId: acc.categoryId,
        categoryName: categoryNameMap[acc.categoryId] ?? acc.categoryId,
        amount: acc.amount,
        percentage: totalAmount > 0 ? (acc.amount / totalAmount) * 100 : 0,
        transactionCount: acc.count,
        type: type,
      );
    }).toList();

    // Sort by amount descending
    summaries.sort((a, b) => b.amount.compareTo(a.amount));

    return CategoryBreakdown(
      startDate: startDate,
      endDate: endDate,
      categories: summaries,
      totalAmount: totalAmount,
      totalTransactions: filtered.length,
    );
  }

  /// Get expense breakdown for current month
  Future<CategoryBreakdown> getCurrentMonthCategoryBreakdown({
    String? walletId,
  }) async {
    final now = DateTime.now();
    return getCategoryBreakdown(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      walletId: walletId,
    );
  }

  // ==================== TIME SERIES ====================

  /// Get time series data for a period
  Future<TimeSeries> getTimeSeries({
    required DateTime startDate,
    required DateTime endDate,
    required TimeSeriesGranularity granularity,
    String? walletId,
  }) async {
    final transactions = await _getFilteredTransactions(
      startDate: startDate,
      endDate: endDate,
      walletId: walletId,
    );

    // Exclude transfers from income/expense calculations
    final relevantTx = transactions
        .where((t) => t.type != TransactionType.transfer)
        .toList();

    // Generate time buckets
    final buckets = _generateBuckets(startDate, endDate, granularity);

    // Single pass aggregation into buckets
    final bucketData = <DateTime, _TimeSeriesAccumulator>{};
    for (final bucket in buckets) {
      bucketData[bucket] = _TimeSeriesAccumulator();
    }

    double totalIncome = 0;
    double totalExpenses = 0;

    for (final tx in relevantTx) {
      final bucket = _getBucketForDate(tx.createdAt, granularity, buckets);
      if (bucket != null) {
        final acc = bucketData[bucket]!;
        if (tx.type == TransactionType.income) {
          acc.income += tx.amount;
          totalIncome += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          acc.expenses += tx.amount;
          totalExpenses += tx.amount;
        }
        acc.count++;
      }
    }

    // Build points with running balance
    double runningBalance = 0;
    final points = <TimeSeriesPoint>[];

    for (final bucket in buckets) {
      final acc = bucketData[bucket]!;
      runningBalance += acc.income - acc.expenses;
      points.add(TimeSeriesPoint(
        date: bucket,
        income: acc.income,
        expenses: acc.expenses,
        balance: runningBalance,
        transactionCount: acc.count,
      ));
    }

    return TimeSeries(
      startDate: startDate,
      endDate: endDate,
      granularity: granularity,
      points: points,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
    );
  }

  /// Get daily time series for current month
  Future<TimeSeries> getCurrentMonthDailySeries({String? walletId}) async {
    final now = DateTime.now();
    return getTimeSeries(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      granularity: TimeSeriesGranularity.daily,
      walletId: walletId,
    );
  }

  /// Get weekly time series for last N weeks
  Future<TimeSeries> getWeeklySeries({
    int weeks = 12,
    String? walletId,
  }) async {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final startDate = endDate.subtract(Duration(days: weeks * 7));

    return getTimeSeries(
      startDate: startDate,
      endDate: endDate,
      granularity: TimeSeriesGranularity.weekly,
      walletId: walletId,
    );
  }

  /// Get monthly time series for last N months
  Future<TimeSeries> getMonthlySeries({
    int months = 12,
    String? walletId,
  }) async {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final startDate = DateTime(now.year, now.month - months + 1, 1);

    return getTimeSeries(
      startDate: startDate,
      endDate: endDate,
      granularity: TimeSeriesGranularity.monthly,
      walletId: walletId,
    );
  }

  // ==================== PERIOD COMPARISON ====================

  /// Compare current period with previous period
  Future<PeriodComparison> getPeriodComparison({
    required DateTime currentStart,
    required DateTime currentEnd,
    String? walletId,
  }) async {
    // Calculate previous period of same length
    final duration = currentEnd.difference(currentStart);
    final previousEnd = currentStart.subtract(const Duration(seconds: 1));
    final previousStart = previousEnd.subtract(duration);

    // Get transactions for both periods
    final currentTx = await _getFilteredTransactions(
      startDate: currentStart,
      endDate: currentEnd,
      walletId: walletId,
    );

    final previousTx = await _getFilteredTransactions(
      startDate: previousStart,
      endDate: previousEnd,
      walletId: walletId,
    );

    // Aggregate current period (exclude transfers)
    double currentIncome = 0;
    double currentExpenses = 0;
    int currentCount = 0;

    for (final tx in currentTx.where((t) => t.type != TransactionType.transfer)) {
      if (tx.type == TransactionType.income) {
        currentIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        currentExpenses += tx.amount;
      }
      currentCount++;
    }

    // Aggregate previous period
    double previousIncome = 0;
    double previousExpenses = 0;
    int previousCount = 0;

    for (final tx in previousTx.where((t) => t.type != TransactionType.transfer)) {
      if (tx.type == TransactionType.income) {
        previousIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        previousExpenses += tx.amount;
      }
      previousCount++;
    }

    return PeriodComparison(
      currentStart: currentStart,
      currentEnd: currentEnd,
      previousStart: previousStart,
      previousEnd: previousEnd,
      currentIncome: currentIncome,
      previousIncome: previousIncome,
      currentExpenses: currentExpenses,
      previousExpenses: previousExpenses,
      currentTransactionCount: currentCount,
      previousTransactionCount: previousCount,
    );
  }

  /// Compare current month with previous month
  Future<PeriodComparison> getMonthOverMonthComparison({
    String? walletId,
  }) async {
    final now = DateTime.now();
    return getPeriodComparison(
      currentStart: DateTime(now.year, now.month, 1),
      currentEnd: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      walletId: walletId,
    );
  }

  /// Compare current week with previous week
  Future<PeriodComparison> getWeekOverWeekComparison({
    String? walletId,
  }) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final currentStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final currentEnd = currentStart.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    return getPeriodComparison(
      currentStart: currentStart,
      currentEnd: currentEnd,
      walletId: walletId,
    );
  }

  // ==================== NET WORTH ====================

  /// Current net worth: assets (regular + savings) - liabilities (debt)
  Future<NetWorthSnapshot> getCurrentNetWorth() async {
    final wallets = await _db.getAllWallets();
    double assets = 0;
    double liabilities = 0;
    for (final w in wallets) {
      if (!w.isActive) continue;
      if (w.accountType == AccountType.debt) {
        liabilities += w.debtTotal ?? w.currentBalance;
      } else if (w.accountType == AccountType.regular || w.accountType == AccountType.savings) {
        if (w.includeInTotal) assets += w.currentBalance;
      }
    }
    return NetWorthSnapshot(
      assets: assets,
      liabilities: liabilities,
      netWorth: assets - liabilities,
      date: DateTime.now(),
    );
  }

  /// Spending velocity for current month: avg daily, projected total, % vs budget
  Future<SpendingVelocity> getSpendingVelocity({String? walletId}) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final daysInMonth = endOfMonth.day;
    final daysElapsed = now.day;
    final transactions = await _getFilteredTransactions(
      startDate: startOfMonth,
      endDate: now,
      walletId: walletId,
    );
    double mtdSpend = 0;
    for (final t in transactions.where((x) => x.type == TransactionType.expense)) {
      mtdSpend += t.amount;
    }
    final avgDaily = daysElapsed > 0 ? mtdSpend / daysElapsed : 0.0;
    final projected = avgDaily * daysInMonth;
    double? pctVsBudget;
    final budgets = await _db.getBudgets();
    if (budgets.isNotEmpty) {
      final totalBudget = budgets.fold<double>(0, (s, b) => s + b.amount);
      if (totalBudget > 0) pctVsBudget = (projected / totalBudget) * 100;
    }
    return SpendingVelocity(
      avgDailySpend: avgDaily,
      projectedMonthTotal: projected,
      percentageVsBudget: pctVsBudget,
      monthToDateSpend: mtdSpend,
      daysElapsed: daysElapsed,
      daysInMonth: daysInMonth,
    );
  }

  // ==================== WALLET ANALYTICS ====================

  /// Get analytics for all wallets
  Future<List<WalletAnalytics>> getWalletAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final wallets = await _db.getWallets();
    final results = <WalletAnalytics>[];

    for (final wallet in wallets) {
      final transactions = await _getFilteredTransactions(
        startDate: startDate,
        endDate: endDate,
        walletId: wallet.id,
      );

      double income = 0;
      double expenses = 0;
      int count = 0;

      for (final tx in transactions.where((t) => t.type != TransactionType.transfer)) {
        if (tx.type == TransactionType.income) {
          income += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          expenses += tx.amount;
        }
        count++;
      }

      results.add(WalletAnalytics(
        walletId: wallet.id,
        walletName: wallet.name,
        currentBalance: wallet.currentBalance,
        periodIncome: income,
        periodExpenses: expenses,
        periodNetFlow: income - expenses,
        transactionCount: count,
      ));
    }

    return results;
  }

  // ==================== HELPERS ====================

  /// Get filtered transactions (single query, reused across methods)
  Future<List<Transaction>> _getFilteredTransactions({
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
  }) async {
    var transactions = await _db.getTransactionsByDateRange(startDate, endDate);

    if (walletId != null) {
      transactions = transactions.where((t) => t.walletId == walletId).toList();
    }

    return transactions;
  }

  /// Generate time buckets for a period
  List<DateTime> _generateBuckets(
    DateTime start,
    DateTime end,
    TimeSeriesGranularity granularity,
  ) {
    final buckets = <DateTime>[];
    var current = _normalizeToGranularity(start, granularity);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      buckets.add(current);
      current = _advanceBucket(current, granularity);
    }

    return buckets;
  }

  /// Normalize date to start of granularity period
  DateTime _normalizeToGranularity(DateTime date, TimeSeriesGranularity granularity) {
    switch (granularity) {
      case TimeSeriesGranularity.daily:
        return DateTime(date.year, date.month, date.day);
      case TimeSeriesGranularity.weekly:
        final weekday = date.weekday;
        final startOfWeek = date.subtract(Duration(days: weekday - 1));
        return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      case TimeSeriesGranularity.monthly:
        return DateTime(date.year, date.month, 1);
    }
  }

  /// Advance to next bucket
  DateTime _advanceBucket(DateTime current, TimeSeriesGranularity granularity) {
    switch (granularity) {
      case TimeSeriesGranularity.daily:
        return current.add(const Duration(days: 1));
      case TimeSeriesGranularity.weekly:
        return current.add(const Duration(days: 7));
      case TimeSeriesGranularity.monthly:
        return DateTime(current.year, current.month + 1, 1);
    }
  }

  /// Get the bucket a date falls into
  DateTime? _getBucketForDate(
    DateTime date,
    TimeSeriesGranularity granularity,
    List<DateTime> buckets,
  ) {
    final normalized = _normalizeToGranularity(date, granularity);
    for (final bucket in buckets) {
      if (bucket.isAtSameMomentAs(normalized)) {
        return bucket;
      }
    }
    return null;
  }
}

/// Internal accumulator for category aggregation
class _CategoryAccumulator {
  final String categoryId;
  double amount = 0;
  int count = 0;

  _CategoryAccumulator(this.categoryId);
}

/// Internal accumulator for time series aggregation
class _TimeSeriesAccumulator {
  double income = 0;
  double expenses = 0;
  int count = 0;
}
