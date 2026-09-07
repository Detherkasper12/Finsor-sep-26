import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/models/categorization_rule.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/services/categorization/local_rule_engine.dart';

void main() {
  late List<CategorizationRule> rules;

  setUp(() {
    rules = [
      CategorizationRule(
        id: 'r1',
        pattern: 'netflix',
        normalizedPattern: 'netflix',
        categoryId: 'expense_entertainment',
        transactionType: TransactionType.expense,
        source: CategorizationRuleSource.userLearned,
        priority: 100,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      CategorizationRule(
        id: 'r2',
        pattern: 'amazon',
        normalizedPattern: 'amazon',
        categoryId: 'expense_shopping',
        transactionType: TransactionType.expense,
        source: CategorizationRuleSource.systemDefault,
        priority: 50,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      CategorizationRule(
        id: 'r3',
        pattern: 'salary',
        normalizedPattern: 'salary',
        categoryId: 'income_salary',
        transactionType: TransactionType.income,
        source: CategorizationRuleSource.systemDefault,
        priority: 50,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    ];
  });

  group('LocalRuleEngine.suggest', () {
    test('returns null for empty description', () {
      expect(
        LocalRuleEngine.suggest(
          description: '',
          transactionType: TransactionType.expense,
          rules: rules,
        ),
        isNull,
      );
      expect(
        LocalRuleEngine.suggest(
          description: '   ',
          transactionType: TransactionType.expense,
          rules: rules,
        ),
        isNull,
      );
    });

    test('exact normalized match returns category', () {
      expect(
        LocalRuleEngine.suggest(
          description: 'Netflix',
          transactionType: TransactionType.expense,
          rules: rules,
        ),
        'expense_entertainment',
      );
    });

    test('contains match: description contains pattern', () {
      expect(
        LocalRuleEngine.suggest(
          description: 'Netflix monthly subscription',
          transactionType: TransactionType.expense,
          rules: rules,
        ),
        'expense_entertainment',
      );
    });

    test('filters by transaction type', () {
      expect(
        LocalRuleEngine.suggest(
          description: 'salary',
          transactionType: TransactionType.income,
          rules: rules,
        ),
        'income_salary',
      );
      expect(
        LocalRuleEngine.suggest(
          description: 'salary',
          transactionType: TransactionType.expense,
          rules: rules,
        ),
        isNull,
      );
    });

    test('returns null when no rules match', () {
      expect(
        LocalRuleEngine.suggest(
          description: 'unknown merchant xyz',
          transactionType: TransactionType.expense,
          rules: rules,
        ),
        isNull,
      );
    });

    test('returns null for empty rules', () {
      expect(
        LocalRuleEngine.suggest(
          description: 'netflix',
          transactionType: TransactionType.expense,
          rules: [],
        ),
        isNull,
      );
    });

    test('higher priority rule wins', () {
      final withConflict = [
        ...rules,
        CategorizationRule(
          id: 'r4',
          pattern: 'netflix',
          normalizedPattern: 'netflix',
          categoryId: 'expense_other',
          transactionType: TransactionType.expense,
          source: CategorizationRuleSource.systemDefault,
          priority: 200,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];
      expect(
        LocalRuleEngine.suggest(
          description: 'netflix',
          transactionType: TransactionType.expense,
          rules: withConflict,
        ),
        'expense_other',
      );
    });

    test('userLearned wins over systemDefault when priority equal', () {
      final samePriority = [
        CategorizationRule(
          id: 'sys',
          pattern: 'coffee',
          normalizedPattern: 'coffee',
          categoryId: 'expense_food',
          transactionType: TransactionType.expense,
          source: CategorizationRuleSource.systemDefault,
          priority: 50,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        CategorizationRule(
          id: 'user',
          pattern: 'starbucks',
          normalizedPattern: 'starbucks',
          categoryId: 'expense_entertainment',
          transactionType: TransactionType.expense,
          source: CategorizationRuleSource.userLearned,
          priority: 50,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];
      expect(
        LocalRuleEngine.suggest(
          description: 'starbucks',
          transactionType: TransactionType.expense,
          rules: samePriority,
        ),
        'expense_entertainment',
      );
    });

    test('word overlap match: pattern word in description', () {
      final wordRule = [
        CategorizationRule(
          id: 'w1',
          pattern: 'amazon prime',
          normalizedPattern: 'amazon prime',
          categoryId: 'expense_shopping',
          transactionType: TransactionType.expense,
          source: CategorizationRuleSource.systemDefault,
          priority: 50,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];
      expect(
        LocalRuleEngine.suggest(
          description: 'AMAZON PRIME VIDEO',
          transactionType: TransactionType.expense,
          rules: wordRule,
        ),
        'expense_shopping',
      );
    });

    test('skips pattern shorter than 3 chars', () {
      final shortRule = [
        CategorizationRule(
          id: 's1',
          pattern: 'ab',
          normalizedPattern: 'ab',
          categoryId: 'expense_other',
          transactionType: TransactionType.expense,
          source: CategorizationRuleSource.systemDefault,
          priority: 100,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];
      expect(
        LocalRuleEngine.suggest(
          description: 'ab cd',
          transactionType: TransactionType.expense,
          rules: shortRule,
        ),
        isNull,
      );
    });

    test('stopword filtering: meaningful tokens still match', () {
      final rule = [
        CategorizationRule(
          id: 'r1',
          pattern: 'netflix',
          normalizedPattern: 'netflix',
          categoryId: 'expense_entertainment',
          transactionType: TransactionType.expense,
          source: CategorizationRuleSource.systemDefault,
          priority: 50,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];
      expect(
        LocalRuleEngine.suggest(
          description: 'netflix monthly subscription payment',
          transactionType: TransactionType.expense,
          rules: rule,
        ),
        'expense_entertainment',
      );
    });
  });
}
