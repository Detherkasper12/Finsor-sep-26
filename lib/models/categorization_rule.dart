import '../utils/safe_json_parse.dart';
import 'transaction.dart';

/// Source of a categorization rule: user correction vs system default.
enum CategorizationRuleSource {
  userLearned,
  systemDefault,
}

/// A rule that maps a description pattern to a category.
/// Stored in Hive and synced to Supabase.
class CategorizationRule {
  final String id;
  final String pattern;
  final String normalizedPattern;
  final String categoryId;
  final TransactionType transactionType;
  final CategorizationRuleSource source;
  final int priority;
  final int hitCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategorizationRule({
    required this.id,
    required this.pattern,
    required this.normalizedPattern,
    required this.categoryId,
    required this.transactionType,
    required this.source,
    required this.priority,
    this.hitCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  static String normalize(String input) {
    if (input.isEmpty) return '';
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s\-]'), '');
  }

  factory CategorizationRule.fromJson(Map<String, dynamic> json) {
    return CategorizationRule(
      id: safeStringOr(json['id'], ''),
      pattern: safeStringOr(json['pattern'], ''),
      normalizedPattern: safeStringOr(json['normalizedPattern'], ''),
      categoryId: safeStringOr(json['categoryId'], ''),
      transactionType: TransactionType.values.byName(safeStringOr(json['transactionType'], 'expense')),
      source: _parseSource(safeString(json['source'])),
      priority: safeInt(json['priority']) ?? 100,
      hitCount: safeInt(json['hitCount']) ?? 0,
      createdAt: safeDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: safeDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pattern': pattern,
      'normalizedPattern': normalizedPattern,
      'categoryId': categoryId,
      'transactionType': transactionType.name,
      'source': source.name,
      'priority': priority,
      'hitCount': hitCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CategorizationRule copyWith({
    String? id,
    String? pattern,
    String? normalizedPattern,
    String? categoryId,
    TransactionType? transactionType,
    CategorizationRuleSource? source,
    int? priority,
    int? hitCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategorizationRule(
      id: id ?? this.id,
      pattern: pattern ?? this.pattern,
      normalizedPattern: normalizedPattern ?? this.normalizedPattern,
      categoryId: categoryId ?? this.categoryId,
      transactionType: transactionType ?? this.transactionType,
      source: source ?? this.source,
      priority: priority ?? this.priority,
      hitCount: hitCount ?? this.hitCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  CategorizationRule incrementHitCount() {
    return copyWith(
      hitCount: hitCount + 1,
      updatedAt: DateTime.now(),
    );
  }

  static CategorizationRuleSource _parseSource(String? v) {
    if (v == null) return CategorizationRuleSource.userLearned;
    final n = v.replaceAll('_', '');
    if (n == 'userLearned' || n == 'userlearned') return CategorizationRuleSource.userLearned;
    if (n == 'systemDefault' || n == 'systemdefault') return CategorizationRuleSource.systemDefault;
    return CategorizationRuleSource.userLearned;
  }
}
