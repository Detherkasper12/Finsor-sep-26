import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/models/sync_operation.dart';

void main() {
  group('SyncOperation', () {
    test('fromJson/toJson roundtrip', () {
      final op = SyncOperation(
        opId: 'op_1',
        entityType: 'transactions',
        entityId: 'txn_1',
        opType: 'upsert',
        payload: {'id': 'txn_1', 'amount': 50.0},
        createdAt: DateTime(2026, 1, 1),
      );

      final json = op.toJson();
      final restored = SyncOperation.fromJson(json);

      expect(restored.opId, 'op_1');
      expect(restored.entityType, 'transactions');
      expect(restored.entityId, 'txn_1');
      expect(restored.opType, 'upsert');
      expect(restored.payload['amount'], 50.0);
      expect(restored.retryCount, 0);
      expect(restored.failed, false);
    });

    test('incrementRetry increases count', () {
      final op = SyncOperation(
        opId: 'op_2',
        entityType: 'wallets',
        entityId: 'w_1',
        opType: 'upsert',
        payload: {},
        createdAt: DateTime.now(),
      );

      final r1 = op.incrementRetry();
      expect(r1.retryCount, 1);
      expect(r1.failed, false);

      final r2 = r1.incrementRetry();
      expect(r2.retryCount, 2);
      expect(r2.failed, false);
    });

    test('marks failed after maxRetries', () {
      var op = SyncOperation(
        opId: 'op_3',
        entityType: 'wallets',
        entityId: 'w_1',
        opType: 'upsert',
        payload: {},
        createdAt: DateTime.now(),
        retryCount: SyncOperation.maxRetries - 1,
      );

      final failed = op.incrementRetry();
      expect(failed.retryCount, SyncOperation.maxRetries);
      expect(failed.failed, true);
    });

    test('backoffDuration increases exponentially', () {
      final op = SyncOperation(
        opId: 'op_4',
        entityType: 'wallets',
        entityId: 'w_1',
        opType: 'upsert',
        payload: {},
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      expect(op.backoffDuration, const Duration(seconds: 1));

      final r1 = op.incrementRetry();
      expect(r1.backoffDuration, const Duration(seconds: 2));

      final r2 = r1.incrementRetry();
      expect(r2.backoffDuration, const Duration(seconds: 4));
    });

    test('markFailed sets failed flag', () {
      final op = SyncOperation(
        opId: 'op_5',
        entityType: 'goals',
        entityId: 'g_1',
        opType: 'delete',
        payload: {'id': 'g_1'},
        createdAt: DateTime.now(),
      );

      final failed = op.markFailed();
      expect(failed.failed, true);
      expect(failed.retryCount, 0);
    });
  });
}
