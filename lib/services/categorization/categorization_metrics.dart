import 'package:flutter/foundation.dart';

/// In-memory metrics for categorization (local rules only).
class CategorizationMetrics {
  int localRuleMatches = 0;

  void recordLocalMatch() {
    localRuleMatches++;
  }

  /// Persist today's summary to metadata key categorization_metrics_YYYY-MM-DD
  Future<void> persistDaily(Future<void> Function(String key, String value) setMetadata) async {
    final today = DateTime.now().toUtc();
    final key = 'categorization_metrics_${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final value = 'localRuleMatches=$localRuleMatches';
    await setMetadata(key, value);
    if (kDebugMode) {
      debugPrint('[CategorizationMetrics] persisted $key');
    }
  }

  void reset() {
    localRuleMatches = 0;
  }
}
