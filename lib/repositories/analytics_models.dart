/// Analytics DTOs - Pure data transfer objects for analytics output
/// NOT persisted in Hive, used only for analytics aggregation results
library;

import '../models/transaction.dart';

/// Overview tab metrics: savings rate, biggest expense, average daily spend.
class OverviewMetrics {
  final double? savingsRatePercent;
  final double? biggestExpenseAmount;
  final String biggestExpenseLabel;
  final double averageDailySpend;
  final int daysInPeriod;

  const OverviewMetrics({
    this.savingsRatePercent,
    this.biggestExpenseAmount,
    this.biggestExpenseLabel = '—',
    required this.averageDailySpend,
    required this.daysInPeriod,
  });
}

/// Summary for a single category within a period
class CategorySummary {
  final String categoryId;
  final String categoryName;
  final double amount;
  final double percentage;
  final int transactionCount;
  final TransactionType type;

  const CategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
    required this.type,
  });

  @override
  String toString() =>
      'CategorySummary($categoryName: \$$amount, $percentage%, $transactionCount tx)';
}

/// Category breakdown result containing all categories for a period
class CategoryBreakdown {
  final DateTime startDate;
  final DateTime endDate;
  final List<CategorySummary> categories;
  final double totalAmount;
  final int totalTransactions;

  const CategoryBreakdown({
    required this.startDate,
    required this.endDate,
    required this.categories,
    required this.totalAmount,
    required this.totalTransactions,
  });

  /// Get top N categories by amount
  List<CategorySummary> topCategories(int n) {
    final sorted = List<CategorySummary>.from(categories)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return sorted.take(n).toList();
  }

  bool get isEmpty => categories.isEmpty;
}

/// Single point in a time series
class TimeSeriesPoint {
  final DateTime date;
  final double income;
  final double expenses;
  final double balance;
  final int transactionCount;

  const TimeSeriesPoint({
    required this.date,
    required this.income,
    required this.expenses,
    required this.balance,
    required this.transactionCount,
  });

  double get netFlow => income - expenses;

  @override
  String toString() =>
      'TimeSeriesPoint(${date.toIso8601String().substring(0, 10)}: '
      'in=\$$income, out=\$$expenses, balance=\$$balance)';
}

/// Time series aggregation result
class TimeSeries {
  final DateTime startDate;
  final DateTime endDate;
  final TimeSeriesGranularity granularity;
  final List<TimeSeriesPoint> points;
  final double totalIncome;
  final double totalExpenses;

  const TimeSeries({
    required this.startDate,
    required this.endDate,
    required this.granularity,
    required this.points,
    required this.totalIncome,
    required this.totalExpenses,
  });

  double get totalBalance => totalIncome - totalExpenses;
  bool get isEmpty => points.isEmpty;

  /// Get average daily/weekly/monthly values
  double get averageIncome => points.isEmpty ? 0 : totalIncome / points.length;
  double get averageExpenses =>
      points.isEmpty ? 0 : totalExpenses / points.length;
}

/// Granularity for time series
enum TimeSeriesGranularity {
  daily,
  weekly,
  monthly,
}

/// Comparison between two periods
class PeriodComparison {
  final DateTime currentStart;
  final DateTime currentEnd;
  final DateTime previousStart;
  final DateTime previousEnd;
  final double currentIncome;
  final double previousIncome;
  final double currentExpenses;
  final double previousExpenses;
  final int currentTransactionCount;
  final int previousTransactionCount;

  const PeriodComparison({
    required this.currentStart,
    required this.currentEnd,
    required this.previousStart,
    required this.previousEnd,
    required this.currentIncome,
    required this.previousIncome,
    required this.currentExpenses,
    required this.previousExpenses,
    required this.currentTransactionCount,
    required this.previousTransactionCount,
  });

  // Income deltas
  double get incomeDelta => currentIncome - previousIncome;
  double get incomePercentageChange =>
      previousIncome == 0 ? 0 : (incomeDelta / previousIncome) * 100;
  bool get incomeIncreased => incomeDelta > 0;

  // Expense deltas
  double get expensesDelta => currentExpenses - previousExpenses;
  double get expensesPercentageChange =>
      previousExpenses == 0 ? 0 : (expensesDelta / previousExpenses) * 100;
  bool get expensesIncreased => expensesDelta > 0;

  // Balance deltas
  double get currentBalance => currentIncome - currentExpenses;
  double get previousBalance => previousIncome - previousExpenses;
  double get balanceDelta => currentBalance - previousBalance;
  double get balancePercentageChange =>
      previousBalance == 0 ? 0 : (balanceDelta / previousBalance) * 100;

  // Transaction count delta
  int get transactionCountDelta =>
      currentTransactionCount - previousTransactionCount;

  @override
  String toString() => 'PeriodComparison('
      'income: \$$currentIncome vs \$$previousIncome (${incomePercentageChange.toStringAsFixed(1)}%), '
      'expenses: \$$currentExpenses vs \$$previousExpenses (${expensesPercentageChange.toStringAsFixed(1)}%))';
}

/// Wallet analytics summary
class WalletAnalytics {
  final String walletId;
  final String walletName;
  final double currentBalance;
  final double periodIncome;
  final double periodExpenses;
  final double periodNetFlow;
  final int transactionCount;

  const WalletAnalytics({
    required this.walletId,
    required this.walletName,
    required this.currentBalance,
    required this.periodIncome,
    required this.periodExpenses,
    required this.periodNetFlow,
    required this.transactionCount,
  });
}

/// Net worth: assets (regular + savings) - liabilities (debt)
class NetWorthSnapshot {
  final double assets;
  final double liabilities;
  final double netWorth;
  final DateTime date;

  const NetWorthSnapshot({
    required this.assets,
    required this.liabilities,
    required this.netWorth,
    required this.date,
  });
}

/// Spending velocity: avg daily spend, projected month total, % vs budget
class SpendingVelocity {
  final double avgDailySpend;
  final double projectedMonthTotal;
  final double? percentageVsBudget;
  final double monthToDateSpend;
  final int daysElapsed;
  final int daysInMonth;

  const SpendingVelocity({
    required this.avgDailySpend,
    required this.projectedMonthTotal,
    this.percentageVsBudget,
    required this.monthToDateSpend,
    required this.daysElapsed,
    required this.daysInMonth,
  });
}
