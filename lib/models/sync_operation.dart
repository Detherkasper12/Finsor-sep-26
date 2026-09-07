import '../utils/safe_json_parse.dart';

class SyncOperation {
  final String opId;
  final String entityType; // wallets, categories, transactions, budgets, recurring_transactions, goals, user_settings
  final String entityId;
  final String opType; // upsert, delete
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final bool failed;

  const SyncOperation({
    required this.opId,
    required this.entityType,
    required this.entityId,
    required this.opType,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.failed = false,
  });

  static const int maxRetries = 10;

  SyncOperation incrementRetry() {
    return SyncOperation(
      opId: opId,
      entityType: entityType,
      entityId: entityId,
      opType: opType,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount + 1,
      failed: retryCount + 1 >= maxRetries,
    );
  }

  SyncOperation markFailed() {
    return SyncOperation(
      opId: opId,
      entityType: entityType,
      entityId: entityId,
      opType: opType,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount,
      failed: true,
    );
  }

  Duration get backoffDuration {
    final seconds = 1 << retryCount.clamp(0, 8); // 1, 2, 4, 8 ... 256s max
    return Duration(seconds: seconds);
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      opId: safeStringOr(json['opId'], ''),
      entityType: safeStringOr(json['entityType'], ''),
      entityId: safeStringOr(json['entityId'], ''),
      opType: safeStringOr(json['opType'], 'upsert'),
      payload: Map<String, dynamic>.from(json['payload'] is Map ? json['payload'] as Map : {}),
      createdAt: safeDateTime(json['createdAt']) ?? DateTime.now(),
      retryCount: safeInt(json['retryCount']) ?? 0,
      failed: json['failed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opId': opId,
      'entityType': entityType,
      'entityId': entityId,
      'opType': opType,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'failed': failed,
    };
  }
}
