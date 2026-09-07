import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/models/categorization_rule.dart';
import 'package:finsor/models/transaction.dart';

void main() {
  group('CategorizationRule', () {
    test('normalize trims and lowercases', () {
      expect(CategorizationRule.normalize('  NETFLIX  '), 'netflix');
    });

    test('normalize collapses whitespace', () {
      expect(CategorizationRule.normalize('a  b   c'), 'a b c');
    });

    test('normalize strips punctuation', () {
      expect(CategorizationRule.normalize('café, 2x!'), contains('caf'));
      expect(CategorizationRule.normalize('paypal (fee)'), 'paypal fee');
    });

    test('normalize empty returns empty', () {
      expect(CategorizationRule.normalize(''), '');
      expect(CategorizationRule.normalize('   '), '');
    });

    test('fromJson and toJson roundtrip', () {
      final rule = CategorizationRule(
        id: 'r1',
        pattern: 'Netflix',
        normalizedPattern: 'netflix',
        categoryId: 'expense_entertainment',
        transactionType: TransactionType.expense,
        source: CategorizationRuleSource.userLearned,
        priority: 100,
        hitCount: 2,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );
      final json = rule.toJson();
      final restored = CategorizationRule.fromJson(json);
      expect(restored.id, rule.id);
      expect(restored.categoryId, rule.categoryId);
      expect(restored.source, rule.source);
      expect(restored.priority, rule.priority);
    });

    test('fromJson parses source user_learned from snake_case', () {
      final json = {
        'id': 'r1',
        'pattern': 'x',
        'normalizedPattern': 'x',
        'categoryId': 'cat1',
        'transactionType': 'expense',
        'source': 'user_learned',
        'priority': 100,
        'hitCount': 0,
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };
      final rule = CategorizationRule.fromJson(json);
      expect(rule.source, CategorizationRuleSource.userLearned);
    });

    test('fromJson parses source system_default', () {
      final json = {
        'id': 'r1',
        'pattern': 'x',
        'normalizedPattern': 'x',
        'categoryId': 'cat1',
        'transactionType': 'expense',
        'source': 'system_default',
        'priority': 50,
        'hitCount': 0,
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      };
      final rule = CategorizationRule.fromJson(json);
      expect(rule.source, CategorizationRuleSource.systemDefault);
    });

    test('incrementHitCount returns new rule with hitCount+1', () {
      final rule = CategorizationRule(
        id: 'r1',
        pattern: 'x',
        normalizedPattern: 'x',
        categoryId: 'c1',
        transactionType: TransactionType.expense,
        source: CategorizationRuleSource.userLearned,
        priority: 100,
        hitCount: 3,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final next = rule.incrementHitCount();
      expect(next.hitCount, 4);
      expect(rule.hitCount, 3);
    });
  });
}
