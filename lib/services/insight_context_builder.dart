import '../repositories/analytics_repository.dart';
import '../repositories/analytics_models.dart';

/// Builds structured analytics context for AI insights
/// Uses ONLY AnalyticsRepository outputs - no raw transactions
/// Context is safe to pass to AI (aggregated numbers only)
class InsightContextBuilder {
  final AnalyticsRepository _repository;

  InsightContextBuilder(this._repository);

  /// Build full context for current month
  Future<InsightContext> buildCurrentMonthContext({
    String? walletId,
  }) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final breakdown = await _repository.getCategoryBreakdown(
      startDate: startDate,
      endDate: endDate,
      walletId: walletId,
    );

    final comparison = await _repository.getMonthOverMonthComparison(
      walletId: walletId,
    );

    final wallets = await _repository.getWalletAnalytics(
      startDate: startDate,
      endDate: endDate,
    );

    return InsightContext(
      periodStart: startDate.toIso8601String(),
      periodEnd: endDate.toIso8601String(),
      walletId: walletId,
      totalIncome: comparison.currentIncome,
      totalExpenses: comparison.currentExpenses,
      netFlow: comparison.currentIncome - comparison.currentExpenses,
      transactionCount: comparison.currentTransactionCount,
      topCategories: breakdown.topCategories(5).map((c) => CategoryContext(
            name: c.categoryName,
            amount: c.amount,
            percentage: c.percentage,
            transactionCount: c.transactionCount,
          )).toList(),
      comparison: PeriodContext(
        previousIncome: comparison.previousIncome,
        previousExpenses: comparison.previousExpenses,
        incomeDelta: comparison.incomeDelta,
        incomePercentageChange: comparison.incomePercentageChange,
        expensesDelta: comparison.expensesDelta,
        expensesPercentageChange: comparison.expensesPercentageChange,
      ),
      walletSummaries: wallets.map((w) => WalletContext(
            name: w.walletName,
            currentBalance: w.currentBalance,
            periodIncome: w.periodIncome,
            periodExpenses: w.periodExpenses,
            periodNetFlow: w.periodNetFlow,
            transactionCount: w.transactionCount,
          )).toList(),
    );
  }
}

/// Structured context for AI - aggregated numbers only, no PII
class InsightContext {
  final String periodStart;
  final String periodEnd;
  final String? walletId;
  final double totalIncome;
  final double totalExpenses;
  final double netFlow;
  final int transactionCount;
  final List<CategoryContext> topCategories;
  final PeriodContext comparison;
  final List<WalletContext> walletSummaries;

  InsightContext({
    required this.periodStart,
    required this.periodEnd,
    this.walletId,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netFlow,
    required this.transactionCount,
    required this.topCategories,
    required this.comparison,
    required this.walletSummaries,
  });

  Map<String, dynamic> toJson() => {
        'periodStart': periodStart,
        'periodEnd': periodEnd,
        'walletId': walletId,
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netFlow': netFlow,
        'transactionCount': transactionCount,
        'topCategories': topCategories.map((c) => c.toJson()).toList(),
        'comparison': comparison.toJson(),
        'walletSummaries': walletSummaries.map((w) => w.toJson()).toList(),
      };
}

class CategoryContext {
  final String name;
  final double amount;
  final double percentage;
  final int transactionCount;

  CategoryContext({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'percentage': percentage,
        'transactionCount': transactionCount,
      };
}

class PeriodContext {
  final double previousIncome;
  final double previousExpenses;
  final double incomeDelta;
  final double incomePercentageChange;
  final double expensesDelta;
  final double expensesPercentageChange;

  PeriodContext({
    required this.previousIncome,
    required this.previousExpenses,
    required this.incomeDelta,
    required this.incomePercentageChange,
    required this.expensesDelta,
    required this.expensesPercentageChange,
  });

  Map<String, dynamic> toJson() => {
        'previousIncome': previousIncome,
        'previousExpenses': previousExpenses,
        'incomeDelta': incomeDelta,
        'incomePercentageChange': incomePercentageChange,
        'expensesDelta': expensesDelta,
        'expensesPercentageChange': expensesPercentageChange,
      };
}

class WalletContext {
  final String name;
  final double currentBalance;
  final double periodIncome;
  final double periodExpenses;
  final double periodNetFlow;
  final int transactionCount;

  WalletContext({
    required this.name,
    required this.currentBalance,
    required this.periodIncome,
    required this.periodExpenses,
    required this.periodNetFlow,
    required this.transactionCount,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'currentBalance': currentBalance,
        'periodIncome': periodIncome,
        'periodExpenses': periodExpenses,
        'periodNetFlow': periodNetFlow,
        'transactionCount': transactionCount,
      };
}
