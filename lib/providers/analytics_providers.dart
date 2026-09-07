import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/analytics_models.dart';
import 'categories_provider.dart';
import 'database_provider.dart';
import 'repository_providers.dart';
import '../utils/safe_json_parse.dart';

/// Provider for AnalyticsRepository
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final db = ref.read(databaseServiceProvider);
  return AnalyticsRepository(db);
});

// ==================== CATEGORY BREAKDOWN ====================

/// Provider for current month expense breakdown
final currentMonthCategoryBreakdownProvider =
    FutureProvider<CategoryBreakdown>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final walletId = ref.watch(selectedWalletIdProvider);
  return repo.getCurrentMonthCategoryBreakdown(walletId: walletId);
});

/// Provider for custom period category breakdown
final categoryBreakdownProvider = FutureProvider.family<
    CategoryBreakdown,
    ({DateTime startDate, DateTime endDate, String? walletId})>((ref, params) async {
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getCategoryBreakdown(
    startDate: params.startDate,
    endDate: params.endDate,
    walletId: params.walletId,
  );
});

// ==================== TIME SERIES ====================

/// Provider for current month daily series
final currentMonthDailySeriesProvider = FutureProvider<TimeSeries>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final walletId = ref.watch(selectedWalletIdProvider);
  return repo.getCurrentMonthDailySeries(walletId: walletId);
});

/// Provider for weekly series (last 12 weeks)
final weeklySeriesProvider = FutureProvider<TimeSeries>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final walletId = ref.watch(selectedWalletIdProvider);
  return repo.getWeeklySeries(walletId: walletId);
});

/// Provider for monthly series (last 12 months)
final monthlySeriesProvider = FutureProvider<TimeSeries>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final walletId = ref.watch(selectedWalletIdProvider);
  return repo.getMonthlySeries(walletId: walletId);
});

// ==================== PERIOD COMPARISON ====================

/// Provider for month-over-month comparison
final monthOverMonthComparisonProvider =
    FutureProvider<PeriodComparison>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final walletId = ref.watch(selectedWalletIdProvider);
  return repo.getMonthOverMonthComparison(walletId: walletId);
});

/// Provider for week-over-week comparison
final weekOverWeekComparisonProvider =
    FutureProvider<PeriodComparison>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final walletId = ref.watch(selectedWalletIdProvider);
  return repo.getWeekOverWeekComparison(walletId: walletId);
});

// ==================== OVERVIEW METRICS ====================

/// Provider for overview metrics (savings rate, biggest expense, avg daily).
final overviewMetricsProvider = FutureProvider<OverviewMetrics>((ref) async {
  final summary = await ref.watch(periodSummaryProvider.future);
  final repo = ref.read(transactionRepositoryProvider);
  final walletId = ref.watch(selectedWalletIdProvider);
  final categories = await ref.watch(categoriesProvider.future);
  final categoryMap = {for (var c in categories) c.id: c.name};

  final biggest = await repo.getBiggestExpense(
    startDate: summary.startDate,
    endDate: summary.endDate,
    walletId: walletId,
  );
  String label = '—';
  double? amount;
  if (biggest != null) {
    amount = biggest.amount;
    final merchant = safeString(biggest.metadata['merchantNormalized']);
    final catName = categoryMap[biggest.categoryId];
    label = merchant ?? catName ?? 'Unknown';
  }

  return OverviewMetrics(
    savingsRatePercent: summary.savingsRatePercent,
    biggestExpenseAmount: amount,
    biggestExpenseLabel: label,
    averageDailySpend: summary.averageDailySpend,
    daysInPeriod: summary.daysInPeriod,
  );
});

// ==================== NET WORTH & VELOCITY ====================

/// Current net worth (assets - liabilities)
final netWorthProvider = FutureProvider<NetWorthSnapshot>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);
  return repo.getCurrentNetWorth();
});

/// Spending velocity for current month
final spendingVelocityProvider = FutureProvider<SpendingVelocity>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final walletId = ref.watch(selectedWalletIdProvider);
  return repo.getSpendingVelocity(walletId: walletId);
});

// ==================== WALLET ANALYTICS ====================

/// Provider for wallet analytics (current month)
final walletAnalyticsProvider =
    FutureProvider<List<WalletAnalytics>>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);
  final now = DateTime.now();
  return repo.getWalletAnalytics(
    startDate: DateTime(now.year, now.month, 1),
    endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
  );
});
