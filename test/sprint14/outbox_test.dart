import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/models/sync_operation.dart';

void main() {
  late HiveDatabaseService db;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final path = '${DateTime.now().millisecondsSinceEpoch}_outbox_test';
    Hive.init(path);
    db = HiveDatabaseService.instance;
    await db.init();
  });

  tearDownAll(() async {
    await db.close();
  });

  group('Outbox (pending_ops)', () {
    test('addPendingOp stores operation', () async {
      await db.clearPendingOps();
      final op = SyncOperation(
        opId: 'test_op_1',
        entityType: 'transactions',
        entityId: 'txn_1',
        opType: 'upsert',
        payload: {'id': 'txn_1', 'amount': 100.0},
        createdAt: DateTime.now(),
      );

      await db.addPendingOp(op.toJson());
      final ops = db.getPendingOps();
      expect(ops.length, 1);
      expect(ops.first['opId'], 'test_op_1');
      expect(ops.first['entityType'], 'transactions');
    });

    test('removePendingOp clears on success', () async {
      await db.clearPendingOps();
      final op = SyncOperation(
        opId: 'test_op_2',
        entityType: 'wallets',
        entityId: 'w_1',
        opType: 'upsert',
        payload: {'id': 'w_1'},
        createdAt: DateTime.now(),
      );

      await db.addPendingOp(op.toJson());
      expect(db.pendingOpsCount, 1);

      await db.removePendingOp('test_op_2');
      expect(db.pendingOpsCount, 0);
    });

    test('updatePendingOp updates retry count', () async {
      await db.clearPendingOps();
      final op = SyncOperation(
        opId: 'test_op_3',
        entityType: 'categories',
        entityId: 'c_1',
        opType: 'upsert',
        payload: {'id': 'c_1'},
        createdAt: DateTime.now(),
      );

      await db.addPendingOp(op.toJson());
      final incremented = op.incrementRetry();
      await db.updatePendingOp(incremented.toJson());

      final ops = db.getPendingOps();
      expect(ops.first['retryCount'], 1);
    });

    test('clearPendingOps removes all', () async {
      await db.addPendingOp(SyncOperation(
        opId: 'a', entityType: 't', entityId: '1',
        opType: 'upsert', payload: {}, createdAt: DateTime.now(),
      ).toJson());
      await db.addPendingOp(SyncOperation(
        opId: 'b', entityType: 't', entityId: '2',
        opType: 'upsert', payload: {}, createdAt: DateTime.now(),
      ).toJson());

      expect(db.pendingOpsCount, greaterThanOrEqualTo(2));
      await db.clearPendingOps();
      expect(db.pendingOpsCount, 0);
    });

    test('pendingOpsCount reflects actual count', () async {
      await db.clearPendingOps();
      expect(db.pendingOpsCount, 0);

      await db.addPendingOp(SyncOperation(
        opId: 'count_1', entityType: 't', entityId: '1',
        opType: 'upsert', payload: {}, createdAt: DateTime.now(),
      ).toJson());
      expect(db.pendingOpsCount, 1);

      await db.addPendingOp(SyncOperation(
        opId: 'count_2', entityType: 't', entityId: '2',
        opType: 'upsert', payload: {}, createdAt: DateTime.now(),
      ).toJson());
      expect(db.pendingOpsCount, 2);
    });
  });
}
