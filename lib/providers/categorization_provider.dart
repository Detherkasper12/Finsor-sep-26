import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/categorization/categorization_metrics.dart';
import '../services/categorization/categorization_service.dart';
import 'database_provider.dart';
import 'sync_provider.dart';

final categorizationMetricsProvider = Provider<CategorizationMetrics>((ref) => CategorizationMetrics());

final categorizationServiceProvider = Provider<CategorizationService>((ref) {
  final db = ref.watch(databaseServiceProvider);
  void enqueueSync({
    required String entityType,
    required String entityId,
    required String opType,
    required Map<String, dynamic> payload,
  }) {
    enqueueSyncOp(ref, entityType: entityType, entityId: entityId, opType: opType, payload: payload);
  }
  return CategorizationService(
    db: db,
    enqueueSync: enqueueSync,
    metrics: ref.watch(categorizationMetricsProvider),
  );
});
