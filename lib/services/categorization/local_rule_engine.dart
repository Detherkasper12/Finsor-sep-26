import '../../models/categorization_rule.dart';
import '../../models/transaction.dart';

const _minPatternLength = 3;

const _stopwords = {
  'the', 'a', 'an', 'of', 'to', 'and', 'or', 'for', 'in', 'on', 'at', 'by',
  'with', 'from', 'payment', 'purchase', 'transaction', 'monthly', 'annual',
  'subscription', 'recurring', 'debit', 'credit', 'card', 'bank', 'transfer',
};

/// Pure local rule engine: token/word-based matching.
/// No I/O. Priority: exact > token match > contains.
class LocalRuleEngine {
  /// Returns the best matching category ID, or null if no rule matches.
  /// Rules sorted by: priority (desc), source (userLearned first).
  /// Pattern must be >= 3 chars. Stopwords filtered from tokens.
  static String? suggest({
    required String description,
    required TransactionType transactionType,
    required List<CategorizationRule> rules,
  }) {
    if (description.trim().isEmpty) return null;
    final normalized = CategorizationRule.normalize(description);
    if (normalized.isEmpty) return null;

    final filtered = rules
        .where((r) => r.transactionType == transactionType && r.normalizedPattern.length >= _minPatternLength)
        .toList();
    if (filtered.isEmpty) return null;

    filtered.sort((a, b) {
      final priorityCmp = b.priority.compareTo(a.priority);
      if (priorityCmp != 0) return priorityCmp;
      if (a.source == CategorizationRuleSource.userLearned &&
          b.source != CategorizationRuleSource.userLearned) return -1;
      if (a.source != CategorizationRuleSource.userLearned &&
          b.source == CategorizationRuleSource.userLearned) return 1;
      return 0;
    });

    final inputTokens = _tokenize(normalized);

    for (final rule in filtered) {
      final p = rule.normalizedPattern;
      if (p.length < _minPatternLength) continue;
      if (_matchesExact(normalized, p)) return rule.categoryId;
      if (_matchesToken(inputTokens, p)) return rule.categoryId;
      if (_matchesContains(normalized, p)) return rule.categoryId;
    }
    return null;
  }

  static Set<String> _tokenize(String normalized) {
    return normalized
        .split(' ')
        .where((w) => w.length >= _minPatternLength && !_stopwords.contains(w))
        .toSet();
  }

  static bool _matchesExact(String input, String pattern) {
    return input == pattern;
  }

  static bool _matchesToken(Set<String> inputTokens, String pattern) {
    final patternTokens = pattern.split(' ').where((w) => w.length >= _minPatternLength && !_stopwords.contains(w)).toList();
    if (patternTokens.isEmpty) return false;
    return patternTokens.every((t) => inputTokens.contains(t));
  }

  static bool _matchesContains(String input, String pattern) {
    if (pattern.length < _minPatternLength) return false;
    return input.contains(pattern);
  }
}
