import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/repositories/transaction_repository.dart';

void main() {
  group('PeriodSummary metrics', () {
    test('savingsRatePercent is null when income is 0', () {
      final summary = PeriodSummary(
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
        income: 0,
        expenses: 100,
        balance: -100,
        incomeCount: 0,
        expenseCount: 1,
        totalCount: 1,
      );
      expect(summary.savingsRatePercent, isNull);
    });

    test('savingsRatePercent when income > 0', () {
      final summary = PeriodSummary(
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
        income: 1000,
        expenses: 600,
        balance: 400,
        incomeCount: 1,
        expenseCount: 1,
        totalCount: 2,
      );
      expect(summary.savingsRatePercent, closeTo(40.0, 0.01));
    });

    test('daysInPeriod is at least 1', () {
      final sameDay = PeriodSummary(
        startDate: DateTime(2025, 1, 15),
        endDate: DateTime(2025, 1, 15),
        income: 0,
        expenses: 0,
        balance: 0,
        incomeCount: 0,
        expenseCount: 0,
        totalCount: 0,
      );
      expect(sameDay.daysInPeriod, equals(1));
    });

    test('averageDailySpend avoids division by zero', () {
      final summary = PeriodSummary(
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
        income: 0,
        expenses: 310,
        balance: -310,
        incomeCount: 0,
        expenseCount: 1,
        totalCount: 1,
      );
      expect(summary.daysInPeriod, greaterThanOrEqualTo(1));
      expect(summary.averageDailySpend, closeTo(310 / 31, 0.01));
    });
  });

  group('Overview empty dataset', () {
    test('empty period summary has safe getters', () {
      final summary = PeriodSummary(
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
        income: 0,
        expenses: 0,
        balance: 0,
        incomeCount: 0,
        expenseCount: 0,
        totalCount: 0,
      );
      expect(summary.savingsRatePercent, isNull);
      expect(summary.averageDailySpend, equals(0.0));
      expect(summary.daysInPeriod, greaterThanOrEqualTo(1));
    });
  });
}
