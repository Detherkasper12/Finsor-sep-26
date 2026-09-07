import '../models/budget.dart';
import '../models/transaction.dart';
import '../services/hive_database_service.dart';
import '../utils/category_utils.dart';

/// Budget status based on spending
enum BudgetStatus {
  underBudget,   // < 80%
  nearLimit,     // >= 80% and < 100%
  exceeded,      // >= 100%
}

/// Computed budget with real-time spending data
class ComputedBudget {
  final Budget budget;
  final double spent;
  final double remaining;
  final double percentageUsed;
  final BudgetStatus status;
  final String? categoryName;
  final String? walletName;
  final double? projectedSpend;
  final bool isProjectedExceeded;

  const ComputedBudget({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.status,
    this.categoryName,
    this.walletName,
    this.projectedSpend,
    this.isProjectedExceeded = false,
  });

  bool get isExceeded => status == BudgetStatus.exceeded;
  bool get isNearLimit => status == BudgetStatus.nearLimit;
  bool get isUnderBudget => status == BudgetStatus.underBudget;

  String get statusLabel {
    switch (status) {
      case BudgetStatus.underBudget:
        return 'On Track';
      case BudgetStatus.nearLimit:
        return 'Approaching Limit';
      case BudgetStatus.exceeded:
        return 'Exceeded';
    }
  }

  String get statusColor {
    switch (status) {
      case BudgetStatus.underBudget:
        return '#4CAF50'; // Green
      case BudgetStatus.nearLimit:
        return '#FF9800'; // Orange
      case BudgetStatus.exceeded:
        return '#F44336'; // Red
    }
  }
}

/// Budget summary for dashboard
class BudgetSummary {
  final int totalBudgets;
  final int exceededCount;
  final int nearLimitCount;
  final int underBudgetCount;
  final double totalBudgetAmount;
  final double totalSpent;

  const BudgetSummary({
    required this.totalBudgets,
    required this.exceededCount,
    required this.nearLimitCount,
    required this.underBudgetCount,
    required this.totalBudgetAmount,
    required this.totalSpent,
  });

  static const empty = BudgetSummary(
    totalBudgets: 0,
    exceededCount: 0,
    nearLimitCount: 0,
    underBudgetCount: 0,
    totalBudgetAmount: 0,
    totalSpent: 0,
  );

  bool get hasAlerts => exceededCount > 0 || nearLimitCount > 0;
  double get overallPercentage => totalBudgetAmount > 0 
      ? (totalSpent / totalBudgetAmount) * 100 
      : 0;
}

/// Repository for budget calculations and aggregations
/// Uses transaction data to compute real-time budget status
class BudgetRepository {
  final HiveDatabaseService _db;

  BudgetRepository(this._db);

  /// Get all computed budgets with real spending data
  Future<List<ComputedBudget>> getComputedBudgets() async {
    final budgets = await _db.getBudgets();
    final activeBudgets = budgets.where((b) => b.isActive).toList();

    final results = <ComputedBudget>[];
    for (final budget in activeBudgets) {
      final computed = await _computeBudget(budget);
      results.add(computed);
    }

    return results;
  }

  /// Get computed budget by ID
  Future<ComputedBudget?> getComputedBudget(String id) async {
    final budget = await _db.getBudget(id);
    if (budget == null) return null;
    return _computeBudget(budget);
  }

  /// Get budget summary for dashboard indicators
  Future<BudgetSummary> getBudgetSummary() async {
    final computed = await getComputedBudgets();
    if (computed.isEmpty) return BudgetSummary.empty;

    int exceeded = 0;
    int nearLimit = 0;
    int underBudget = 0;
    double totalAmount = 0;
    double totalSpent = 0;

    for (final cb in computed) {
      totalAmount += cb.budget.amount;
      totalSpent += cb.spent;

      switch (cb.status) {
        case BudgetStatus.exceeded:
          exceeded++;
          break;
        case BudgetStatus.nearLimit:
          nearLimit++;
          break;
        case BudgetStatus.underBudget:
          underBudget++;
          break;
      }
    }

    return BudgetSummary(
      totalBudgets: computed.length,
      exceededCount: exceeded,
      nearLimitCount: nearLimit,
      underBudgetCount: underBudget,
      totalBudgetAmount: totalAmount,
      totalSpent: totalSpent,
    );
  }

  /// Get budgets that need alerts (near limit or exceeded)
  Future<List<ComputedBudget>> getBudgetsWithAlerts() async {
    final computed = await getComputedBudgets();
    return computed.where((cb) => cb.isExceeded || cb.isNearLimit).toList();
  }

  /// Compute a single budget with real spending and projected (forecast) spend
  Future<ComputedBudget> _computeBudget(Budget budget) async {
    final spent = await _calculateSpent(budget);
    final remaining = budget.amount - spent;
    final percentageUsed = budget.amount > 0 
        ? (spent / budget.amount) * 100 
        : 0.0;

    final status = _determineStatus(percentageUsed, budget.warningThreshold);

    final now = DateTime.now();
    final end = budget.endDate;
    final daysElapsed = now.isBefore(budget.startDate)
        ? 0
        : now.difference(budget.startDate).inDays;
    final remainingDays = now.isAfter(end)
        ? 0
        : end.difference(DateTime(now.year, now.month, now.day)).inDays + 1;
    double? projectedSpend;
    bool isProjectedExceeded = false;
    if (daysElapsed > 0 && remainingDays > 0) {
      final dailyRate = spent / daysElapsed;
      projectedSpend = spent + (dailyRate * remainingDays);
      if (budget.amount > 0 && projectedSpend! > budget.amount) {
        isProjectedExceeded = true;
      }
    }

    String? categoryName;
    String? walletName;

    if (budget.categoryId != null) {
      final categories = await _db.getCategories();
      final category = categories.where((c) => c.id == budget.categoryId).firstOrNull;
      categoryName = category?.name;
    }

    if (budget.walletId != null) {
      final wallet = await _db.getWallet(budget.walletId!);
      walletName = wallet?.name;
    }

    return ComputedBudget(
      budget: budget,
      spent: spent,
      remaining: remaining,
      percentageUsed: percentageUsed,
      status: status,
      categoryName: categoryName,
      walletName: walletName,
      projectedSpend: projectedSpend,
      isProjectedExceeded: isProjectedExceeded,
    );
  }

  /// Calculate spent amount for a budget based on transactions.
  /// Category budget includes all descendant categories (parent + children).
  Future<double> _calculateSpent(Budget budget) async {
    final transactions = await _db.getTransactionsByDateRange(
      budget.startDate,
      budget.endDate,
    );

    Set<String>? categoryIds;
    if (budget.categoryId != null) {
      final categories = await _db.getCategories();
      categoryIds = getDescendantCategoryIds(categories, budget.categoryId!);
    }

    double spent = 0;
    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;
      if (budget.categoryId != null && budget.walletId != null) continue;
      if (budget.categoryId != null &&
          (categoryIds == null || !categoryIds.contains(tx.categoryId))) continue;
      if (budget.walletId != null && tx.walletId != budget.walletId) continue;
      spent += tx.amount;
    }
    return spent;
  }

  /// Determine budget status based on percentage used
  BudgetStatus _determineStatus(double percentageUsed, double warningThreshold) {
    if (percentageUsed >= 100) {
      return BudgetStatus.exceeded;
    } else if (percentageUsed >= warningThreshold) {
      return BudgetStatus.nearLimit;
    }
    return BudgetStatus.underBudget;
  }

  /// Create budget with auto-calculated period dates.
  /// Types are mutually exclusive: global (both null), category (categoryId only), wallet (walletId only).
  Future<Budget> createBudget({
    required String name,
    String? categoryId,
    String? walletId,
    required double amount,
    required BudgetPeriod period,
    double warningThreshold = 80.0,
    String? description,
  }) async {
    if (categoryId != null && walletId != null) {
      throw ArgumentError('Budget cannot have both categoryId and walletId. Choose one type: global, category, or wallet.');
    }

    final now = DateTime.now();
    final dates = _calculatePeriodDates(now, period);

    final budget = Budget(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      categoryId: categoryId,
      walletId: walletId,
      amount: amount,
      period: period,
      startDate: dates.$1,
      endDate: dates.$2,
      warningThreshold: warningThreshold,
      description: description,
      createdAt: now,
    );

    await _db.addBudget(budget);
    return budget;
  }

  /// Calculate start and end dates for a period
  (DateTime, DateTime) _calculatePeriodDates(DateTime from, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        final startOfWeek = from.subtract(Duration(days: from.weekday - 1));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return (start, end);

      case BudgetPeriod.monthly:
        final start = DateTime(from.year, from.month, 1);
        final end = DateTime(from.year, from.month + 1, 0, 23, 59, 59);
        return (start, end);

      case BudgetPeriod.quarterly:
        final quarter = ((from.month - 1) ~/ 3);
        final startMonth = quarter * 3 + 1;
        final start = DateTime(from.year, startMonth, 1);
        final end = DateTime(from.year, startMonth + 3, 0, 23, 59, 59);
        return (start, end);

      case BudgetPeriod.yearly:
        final start = DateTime(from.year, 1, 1);
        final end = DateTime(from.year, 12, 31, 23, 59, 59);
        return (start, end);

      case BudgetPeriod.custom:
        // Default to 30 days for custom
        final end = from.add(const Duration(days: 30));
        return (from, end);
    }
  }
}
