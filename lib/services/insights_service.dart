import 'insight_context_builder.dart';

/// Structured insight with prioritization and explainability
class Insight {
  final String text;
  final double impactScore;
  final String reason;
  final String category;

  const Insight({
    required this.text,
    required this.impactScore,
    required this.reason,
    required this.category,
  });
}

/// Generates insight text from analytics context
/// Uses ONLY aggregated context - no raw transactions
/// Prioritized, de-duplicated, explainable
class InsightsService {
  /// Generate insights from context - prioritized by impact, de-duplicated
  static List<Insight> generateFromContext(InsightContext context) {
    if (context.transactionCount == 0) {
      return [
        const Insight(
          text: 'Start tracking your expenses to get personalized insights.',
          impactScore: 0,
          reason: 'No transactions in this period.',
          category: 'empty',
        ),
      ];
    }

    final raw = _generateRawInsights(context);
    final deduped = _deduplicate(raw);
    deduped.sort((a, b) => b.impactScore.compareTo(a.impactScore));
    return deduped;
  }

  static List<Insight> _generateRawInsights(InsightContext context) {
    final insights = <Insight>[];
    final comp = context.comparison;
    final totalIncome = context.totalIncome;
    final totalExpenses = context.totalExpenses;

    if (totalIncome > 0) {
      final savingsRate = ((totalIncome - totalExpenses) / totalIncome) * 100;
      final impact = (savingsRate - 20).abs();
      if (savingsRate > 20) {
        insights.add(Insight(
          text: 'You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income this month — great job!',
          impactScore: impact,
          reason: 'Because savings rate (${savingsRate.toStringAsFixed(1)}%) exceeds the 20% target.',
          category: 'savings_positive',
        ));
      } else if (savingsRate > 0) {
        insights.add(Insight(
          text: 'You\'re saving ${savingsRate.toStringAsFixed(1)}% this month. Try to reach 20% for better financial health.',
          impactScore: 10 + impact,
          reason: 'Because savings rate is ${savingsRate.toStringAsFixed(1)}% — below the 20% target.',
          category: 'savings_improve',
        ));
      } else {
        insights.add(Insight(
          text: 'You\'re spending more than you earn this month. Consider reviewing your expenses.',
          impactScore: 50,
          reason: 'Because expenses (\$${totalExpenses.toStringAsFixed(0)}) exceed income (\$${totalIncome.toStringAsFixed(0)}).',
          category: 'overspend',
        ));
      }
    }

    if (context.topCategories.isNotEmpty) {
      final top = context.topCategories.first;
      final impact = top.percentage;
      insights.add(Insight(
        text: 'Your top spending category is ${top.name} (\$${top.amount.toStringAsFixed(0)}, ${top.percentage.toStringAsFixed(0)}% of total).',
        impactScore: impact,
        reason: 'Because ${top.name} represents ${top.percentage.toStringAsFixed(0)}% of total spending.',
        category: 'top_category',
      ));
    }

    if (comp.previousExpenses > 0 && comp.expensesPercentageChange.abs() > 5) {
      final absChange = comp.expensesPercentageChange.abs();
      if (comp.expensesDelta > 0) {
        insights.add(Insight(
          text: 'Your spending increased ${comp.expensesPercentageChange.toStringAsFixed(0)}% compared to last month.',
          impactScore: absChange,
          reason: 'Because current month expenses (\$${totalExpenses.toStringAsFixed(0)}) are ${comp.expensesPercentageChange.toStringAsFixed(0)}% higher than last month (\$${comp.previousExpenses.toStringAsFixed(0)}).',
          category: 'expenses_up',
        ));
      } else {
        insights.add(Insight(
          text: 'Your spending decreased ${(-comp.expensesPercentageChange).toStringAsFixed(0)}% compared to last month.',
          impactScore: absChange * 0.8,
          reason: 'Because current month expenses (\$${totalExpenses.toStringAsFixed(0)}) are ${(-comp.expensesPercentageChange).toStringAsFixed(0)}% lower than last month.',
          category: 'expenses_down',
        ));
      }
    }

    if (comp.previousIncome > 0 && comp.incomePercentageChange.abs() > 10) {
      final absChange = comp.incomePercentageChange.abs();
      insights.add(Insight(
        text: 'Your income ${comp.incomeDelta > 0 ? 'increased' : 'decreased'} ${comp.incomePercentageChange.abs().toStringAsFixed(0)}% vs last month.',
        impactScore: absChange * 0.5,
        reason: 'Because income changed from \$${comp.previousIncome.toStringAsFixed(0)} to \$${totalIncome.toStringAsFixed(0)}.',
        category: 'income_change',
      ));
    }

    if (context.walletSummaries.isNotEmpty) {
      final totalBalance = context.walletSummaries
          .fold<double>(0, (sum, w) => sum + w.currentBalance);
      insights.add(Insight(
        text: 'Total balance across all wallets: \$${totalBalance.toStringAsFixed(0)}.',
        impactScore: 5,
        reason: 'Aggregate of ${context.walletSummaries.length} wallet(s).',
        category: 'balance_summary',
      ));
    }

    insights.add(Insight(
      text: 'You made ${context.transactionCount} transactions this period.',
      impactScore: 1,
      reason: 'Transaction count for the period.',
      category: 'transaction_count',
    ));

    return insights;
  }

  static List<Insight> _deduplicate(List<Insight> insights) {
    final seen = <String>{};
    return insights.where((i) {
      if (seen.contains(i.category)) return false;
      seen.add(i.category);
      return true;
    }).toList();
  }

  /// Legacy: returns plain strings for backward compatibility
  static List<String> generateFromContextAsStrings(InsightContext context) {
    return generateFromContext(context).map((i) => i.text).toList();
  }
}
