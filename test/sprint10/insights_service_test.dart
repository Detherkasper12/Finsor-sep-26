import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/services/insights_service.dart';
import 'package:finsor/services/insight_context_builder.dart';

void main() {
  group('InsightsService', () {
    test('generates fallback for empty context', () {
      final context = InsightContext(
        periodStart: '2024-01-01',
        periodEnd: '2024-01-31',
        walletId: null,
        totalIncome: 0,
        totalExpenses: 0,
        netFlow: 0,
        transactionCount: 0,
        topCategories: [],
        comparison: PeriodContext(
          previousIncome: 0,
          previousExpenses: 0,
          incomeDelta: 0,
          incomePercentageChange: 0,
          expensesDelta: 0,
          expensesPercentageChange: 0,
        ),
        walletSummaries: [],
      );
      final insights = InsightsService.generateFromContext(context);
      expect(insights, isNotEmpty);
      expect(insights.first.text.toLowerCase(), contains('track'));
    });

    test('generates savings insight from context', () {
      final context = InsightContext(
        periodStart: '2024-01-01',
        periodEnd: '2024-01-31',
        walletId: null,
        totalIncome: 5000,
        totalExpenses: 3500,
        netFlow: 1500,
        transactionCount: 25,
        topCategories: [
          CategoryContext(
            name: 'Food',
            amount: 800,
            percentage: 22.8,
            transactionCount: 12,
          ),
        ],
        comparison: PeriodContext(
          previousIncome: 4500,
          previousExpenses: 4000,
          incomeDelta: 500,
          incomePercentageChange: 11.1,
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
            transactionCount: 25,
          ),
        ],
      );
      final insights = InsightsService.generateFromContext(context);
      expect(insights, isNotEmpty);
      expect(insights.any((i) => i.text.contains('30') || i.text.contains('saving')), isTrue);
      expect(insights.any((i) => i.text.contains('Food')), isTrue);
    });

    test('numbers come from context only - no hallucination', () {
      final context = InsightContext(
        periodStart: '2024-02-01',
        periodEnd: '2024-02-29',
        walletId: null,
        totalIncome: 1000,
        totalExpenses: 1200,
        netFlow: -200,
        transactionCount: 5,
        topCategories: [
          CategoryContext(name: 'Transport', amount: 400, percentage: 33.3, transactionCount: 2),
        ],
        comparison: PeriodContext(
          previousIncome: 900,
          previousExpenses: 800,
          incomeDelta: 100,
          incomePercentageChange: 11.1,
          expensesDelta: 400,
          expensesPercentageChange: 50,
        ),
        walletSummaries: [],
      );
      final insights = InsightsService.generateFromContext(context);
      expect(insights.any((i) => i.text.contains('Transport')), isTrue);
      expect(insights.any((i) => i.text.contains('400') || i.text.contains('33')), isTrue);
    });
  });
}
