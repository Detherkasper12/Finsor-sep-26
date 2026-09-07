import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/transaction_repository.dart';
import 'database_provider.dart';

/// Provider for TransactionRepository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.read(databaseServiceProvider);
  return TransactionRepository(db);
});

/// Provider for current period summary (configurable)
final periodTypeProvider = StateProvider<PeriodType>((ref) => PeriodType.month);

/// Provider for selected wallet filter (null = all wallets)
final selectedWalletIdProvider = StateProvider<String?>((ref) => null);

/// Provider for period summary based on current filters
final periodSummaryProvider = FutureProvider<PeriodSummary>((ref) async {
  final repository = ref.read(transactionRepositoryProvider);
  final periodType = ref.watch(periodTypeProvider);
  final walletId = ref.watch(selectedWalletIdProvider);

  switch (periodType) {
    case PeriodType.month:
      return repository.getCurrentMonthSummary(walletId: walletId);
    case PeriodType.week:
      return repository.getCurrentWeekSummary(walletId: walletId);
    case PeriodType.custom:
      // For custom, use month as default (custom range picker will override)
      return repository.getCurrentMonthSummary(walletId: walletId);
  }
});

/// Provider for recent transactions based on wallet filter
final recentTransactionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.read(transactionRepositoryProvider);
  final walletId = ref.watch(selectedWalletIdProvider);
  return repository.getRecent(limit: 10, walletId: walletId);
});
