import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recurring_transaction.dart';
import '../services/recurring_service.dart';
import 'database_provider.dart';
import 'sync_provider.dart';

final recurringTransactionsProvider =
    FutureProvider<List<RecurringTransaction>>((ref) async {
  final db = ref.read(databaseServiceProvider);
  return await db.getRecurringTransactions();
});

final recurringTransactionProvider =
    FutureProvider.family<RecurringTransaction?, String>((ref, id) async {
  final db = ref.read(databaseServiceProvider);
  return await db.getRecurringTransaction(id);
});

final recurringServiceProvider = Provider<RecurringService>((ref) {
  return RecurringService(ref.read(databaseServiceProvider));
});

class RecurringNotifier extends StateNotifier<AsyncValue<void>> {
  RecurringNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<void> addRecurring(RecurringTransaction rt) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseServiceProvider);
      await db.addRecurringTransaction(rt);
      enqueueSyncOp(ref, entityType: 'recurring_transactions', entityId: rt.id,
          opType: 'upsert', payload: rt.toJson());
      ref.invalidate(recurringTransactionsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateRecurring(RecurringTransaction rt) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseServiceProvider);
      await db.updateRecurringTransaction(rt);
      enqueueSyncOp(ref, entityType: 'recurring_transactions', entityId: rt.id,
          opType: 'upsert', payload: rt.toJson());
      ref.invalidate(recurringTransactionsProvider);
      ref.invalidate(recurringTransactionProvider(rt.id));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRecurring(String id) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseServiceProvider);
      await db.deleteRecurringTransaction(id);
      enqueueSyncOp(ref, entityType: 'recurring_transactions', entityId: id,
          opType: 'delete', payload: {'id': id});
      ref.invalidate(recurringTransactionsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> togglePause(String id) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseServiceProvider);
      final rt = await db.getRecurringTransaction(id);
      if (rt != null) {
        final updated = rt.copyWith(
          isPaused: !rt.isPaused,
          updatedAt: DateTime.now(),
        );
        await db.updateRecurringTransaction(updated);
        enqueueSyncOp(ref, entityType: 'recurring_transactions', entityId: id,
            opType: 'upsert', payload: updated.toJson());
        ref.invalidate(recurringTransactionsProvider);
        ref.invalidate(recurringTransactionProvider(id));
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final recurringNotifierProvider =
    StateNotifierProvider<RecurringNotifier, AsyncValue<void>>((ref) {
  return RecurringNotifier(ref);
});
