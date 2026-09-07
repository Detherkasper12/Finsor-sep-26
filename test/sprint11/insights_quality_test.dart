import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/services/insights_service.dart';
import 'package:finsor/services/insight_context_builder.dart';

void main() {
  group('InsightsService prioritization & de-duplication', () {
    test('insights sorted by impactScore descending', () {
      final context = InsightContext(
        periodStart: '2024-01-01',
        periodEnd: '2024-01-31',
        walletId: null,
        totalIncome: 5000,
        totalExpenses: 4500,
        netFlow: 500,
        transactionCount: 20,
        topCategories: [
          CategoryContext(name: 'Food', amount: 2000, percentage: 44, transactionCount: 10),
        ],
        comparison: PeriodContext(
          previousIncome: 4000,
          previousExpenses: 3000,
          incomeDelta: 1000,
          incomePercentageChange: 25,
          expensesDelta: 1500,
          expensesPercentageChange: 50,
        ),
        walletSummaries: [],
      );
      final insights = InsightsService.generateFromContext(context);
      expect(insights.length, greaterThan(1));
      for (var i = 0; i < insights.length - 1; i++) {
        expect(insights[i].impactScore, greaterThanOrEqualTo(insights[i + 1].impactScore));
      }
    });

    test('one insight per category - no duplicates', () {
      final context = InsightContext(
        periodStart: '2024-01-01',
        periodEnd: '2024-01-31',
        walletId: null,
        totalIncome: 5000,
        totalExpenses: 3500,
        netFlow: 1500,
        transactionCount: 30,
        topCategories: [
          CategoryContext(name: 'Food', amount: 800, percentage: 23, transactionCount: 12),
        ],
        comparison: PeriodContext(
          previousIncome: 4500,
          previousExpenses: 4000,
          incomeDelta: 500,
          incomePercentageChange: 11,
          expensesDelta: -500,
          expensesPercentageChange: -12.5,
        ),
        walletSummaries: [
          WalletContext(
            name: 'Cash',
            currentBalance: 5000,
            periodIncome: 5000,
            periodExpenses: 3500,
            periodNetFlow: 1500,
            transactionCount: 30,
          ),
        ],
      );
      final insights = InsightsService.generateFromContext(context);
      final categories = insights.map((i) => i.category).toList();
      expect(categories.toSet().length, categories.length);
    });

    test('each insight has non-empty reason', () {
      final context = InsightContext(
        periodStart: '2024-01-01',
        periodEnd: '2024-01-31',
        walletId: null,
        totalIncome: 3000,
        totalExpenses: 2500,
        netFlow: 500,
        transactionCount: 15,
        topCategories: [
          CategoryContext(name: 'Transport', amount: 500, percentage: 20, transactionCount: 5),
        ],
        comparison: PeriodContext(
          previousIncome: 3000,
          previousExpenses: 2000,
          incomeDelta: 0,
          incomePercentageChange: 0,
          expensesDelta: 500,
          expensesPercentageChange: 25,
        ),
        walletSummaries: [],
      );
      final insights = InsightsService.generateFromContext(context);
      for (final i in insights) {
        expect(i.reason, isNotEmpty);
        expect(i.text, isNotEmpty);
        expect(i.category, isNotEmpty);
      }
    });
  });
}
