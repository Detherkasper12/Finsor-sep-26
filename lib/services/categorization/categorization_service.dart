import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/categorization_rule.dart';
import '../../models/transaction.dart';
import '../hive_database_service.dart';
import 'categorization_metrics.dart';
import 'local_rule_engine.dart';

enum CategorizationSource { local, none }

class CategorizationResult {
  final String? categoryId;
  final CategorizationSource source;

  const CategorizationResult({
    this.categoryId,
    required this.source,
  });
}

/// Orchestrates local rules for categorization. Learns from corrections.
class CategorizationService {
  CategorizationService({
    required HiveDatabaseService db,
    required void Function({
      required String entityType,
      required String entityId,
      required String opType,
      required Map<String, dynamic> payload,
    }) enqueueSync,
    required CategorizationMetrics metrics,
  })  : _db = db,
        _enqueueSync = enqueueSync,
        _metrics = metrics;

  final HiveDatabaseService _db;
  final void Function({
    required String entityType,
    required String entityId,
    required String opType,
    required Map<String, dynamic> payload,
  }) _enqueueSync;
  final CategorizationMetrics _metrics;

  /// Suggests category using local rules only.
  Future<CategorizationResult> suggest({
    required String description,
    required TransactionType transactionType,
  }) async {
    if (description.trim().isEmpty) {
      return const CategorizationResult(source: CategorizationSource.none);
    }

    final rules = await _db.getCategorizationRules();
    final localCategoryId = LocalRuleEngine.suggest(
      description: description,
      transactionType: transactionType,
      rules: rules,
    );
    if (localCategoryId != null) {
      _metrics.recordLocalMatch();
      return CategorizationResult(categoryId: localCategoryId, source: CategorizationSource.local);
    }
    return const CategorizationResult(source: CategorizationSource.none);
  }

  /// Call when user corrects an auto-assigned category. Saves a learned rule and syncs.
  Future<void> handleCorrection({
    required String description,
    required String correctCategoryId,
    required TransactionType transactionType,
  }) async {
    final normalized = CategorizationRule.normalize(description);
    if (normalized.isEmpty) return;

    final now = DateTime.now();
    final rule = CategorizationRule(
      id: const Uuid().v4(),
      pattern: description.trim(),
      normalizedPattern: normalized,
      categoryId: correctCategoryId,
      transactionType: transactionType,
      source: CategorizationRuleSource.userLearned,
      priority: 100,
      hitCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    await _db.addCategorizationRule(rule);
    _enqueueSync(
      entityType: 'categorization_rules',
      entityId: rule.id,
      opType: 'upsert',
      payload: rule.toJson(),
    );
    if (kDebugMode) {
      debugPrint('[Categorization] Learned rule: "${rule.pattern}" -> $correctCategoryId');
    }
  }

  CategorizationMetrics get metrics => _metrics;
}
