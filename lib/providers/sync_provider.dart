import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';

final syncServiceProvider = StateProvider<SyncService?>((ref) => null);

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.offline);

final lastSyncAtProvider = StateProvider<DateTime?>((ref) => null);

final pendingOpsCountProvider = StateProvider<int>((ref) => 0);

Timer? _syncDebounceTimer;

void enqueueSyncOp(
  Ref ref, {
  required String entityType,
  required String entityId,
  required String opType,
  required Map<String, dynamic> payload,
}) {
  final syncService = ref.read(syncServiceProvider);
  if (syncService == null) return;
  syncService.enqueueOp(
    entityType: entityType,
    entityId: entityId,
    opType: opType,
    payload: payload,
  );
  ref.read(pendingOpsCountProvider.notifier).state = syncService.pendingCount;

  _syncDebounceTimer?.cancel();
  final svc = syncService;
  _syncDebounceTimer = Timer(const Duration(milliseconds: 400), () {
    _syncDebounceTimer = null;
    if (svc.status != SyncStatus.syncing) {
      svc.sync();
    }
  });
}
