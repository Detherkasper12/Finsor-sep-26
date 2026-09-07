import 'package:flutter/foundation.dart' show debugPrint;
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import 'hive_database_service.dart';

class RecurringService {
  final HiveDatabaseService _db;

  RecurringService(this._db);

  /// Generate all due recurring transactions (idempotent).
  /// Uses tx ID pattern `{recurringId}_{YYYYMMDD}` to prevent duplicates.
  Future<List<Transaction>> generateDueTransactions() async {
    final recurring = await _db.getRecurringTransactions();
    final settings = await _db.getUserSettings();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final generated = <Transaction>[];

    for (final rt in recurring) {
      if (rt.isPaused) continue;
      if (rt.endDate != null && today.isAfter(rt.endDate!)) continue;

      var nextRun = DateTime(rt.nextRunDate.year, rt.nextRunDate.month, rt.nextRunDate.day);

      while (!nextRun.isAfter(today)) {
        final txId = '${rt.id}_${_dateKey(nextRun)}';

        final existing = await _db.getTransaction(txId);
        if (existing == null) {
          final tx = Transaction(
            id: txId,
            amount: rt.amount,
            type: rt.type,
            categoryId: rt.categoryId,
            walletId: rt.walletId,
            toWalletId: rt.toWalletId,
            description: rt.description,
            createdAt: nextRun,
            recurringId: rt.id,
          );
          await _db.addTransaction(tx);
          generated.add(tx);
          debugPrint('[Recurring] Generated tx $txId for recurring ${rt.id}');
        }

        nextRun = _computeNextDate(nextRun, rt.frequency, rt.interval, settings.startOfMonthDay);

        if (rt.endDate != null && nextRun.isAfter(rt.endDate!)) break;
      }

      // Update recurring template with new nextRunDate
      final updated = rt.copyWith(
        nextRunDate: nextRun,
        lastGeneratedDate: today,
        updatedAt: DateTime.now(),
      );
      await _db.updateRecurringTransaction(updated);
    }

    if (generated.isNotEmpty) {
      debugPrint('[Recurring] Generated ${generated.length} transactions');
    }
    return generated;
  }

  /// Compute the next occurrence date after [current].
  static DateTime _computeNextDate(
    DateTime current,
    RecurringFrequency frequency,
    int interval,
    int startOfMonthDay,
  ) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return current.add(Duration(days: interval));
      case RecurringFrequency.weekly:
        return current.add(Duration(days: 7 * interval));
      case RecurringFrequency.monthly:
        var month = current.month + interval;
        var year = current.year;
        while (month > 12) {
          month -= 12;
          year++;
        }
        final day = current.day.clamp(1, _daysInMonth(year, month));
        return DateTime(year, month, day);
      case RecurringFrequency.yearly:
        final year = current.year + interval;
        final day = current.day.clamp(1, _daysInMonth(year, current.month));
        return DateTime(year, current.month, day);
    }
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static String _dateKey(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}
