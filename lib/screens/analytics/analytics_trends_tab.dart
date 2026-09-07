import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/analytics_providers.dart';
import '../../providers/premium_provider.dart';
import '../../premium/premium_features.dart';
import '../../repositories/analytics_models.dart';
import '../../widgets/analytics/analytics_shared_widgets.dart';
import '../../widgets/premium/premium_gate.dart';

/// Trends tab showing time-series chart with granularity toggle
///
/// NOTE: This tab is gated behind Premium (advancedAnalytics feature).
/// Free users see a locked placeholder with upgrade prompt.
///
/// NOTE on Running Balance:
/// - We intentionally show NET FLOW per bucket rather than cumulative balance
/// - This avoids showing misleading data when opening balance is not available
/// - Net flow = income - expenses for each time bucket
class AnalyticsTrendsTab extends ConsumerStatefulWidget {
  const AnalyticsTrendsTab({super.key});

  @override
  ConsumerState<AnalyticsTrendsTab> createState() => _AnalyticsTrendsTabState();
}

class _AnalyticsTrendsTabState extends ConsumerState<AnalyticsTrendsTab> {
  TimeSeriesGranularity _granularity = TimeSeriesGranularity.daily;

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(isFeatureLockedProvider(PremiumFeature.advancedAnalytics));

    if (isLocked) {
      return const Center(
        child: PremiumLockedCard(feature: PremiumFeature.advancedAnalytics),
      );
    }

    final seriesAsync = _getSeriesProvider();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Granularity Toggle
          _buildGranularitySelector(),
          const Gap(20),

          // Chart Section
          seriesAsync.when(
            data: (series) => _buildChartSection(series),
            loading: () => const AnalyticsSkeletonBox(height: 240),
            error: (_, __) => const AnalyticsErrorCard(
              message: 'Failed to load trends data',
            ),
          ),

          const Gap(24),

          // Period Comparison
          const AnalyticsSectionHeader(title: 'Period Comparison'),
          ref.watch(monthOverMonthComparisonProvider).when(
            data: (comparison) => AnalyticsComparisonCard(comparison: comparison),
            loading: () => const AnalyticsSkeletonBox(height: 130),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const Gap(16),
        ],
      ),
    );
  }

  AsyncValue<TimeSeries> _getSeriesProvider() {
    switch (_granularity) {
      case TimeSeriesGranularity.daily:
        return ref.watch(currentMonthDailySeriesProvider);
      case TimeSeriesGranularity.weekly:
        return ref.watch(weeklySeriesProvider);
      case TimeSeriesGranularity.monthly:
        return ref.watch(monthlySeriesProvider);
    }
  }

  Widget _buildGranularitySelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: TimeSeriesGranularity.values.map((g) {
          final isSelected = _granularity == g;
          final label = g.name[0].toUpperCase() + g.name.substring(1);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _granularity = g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartSection(TimeSeries series) {
    if (series.isEmpty) {
      return const AnalyticsEmptyState(
        message: 'No transaction data for this period',
        icon: Icons.show_chart_outlined,
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            children: [
              _ChartLegend(color: Colors.green, label: 'Income'),
              const Gap(20),
              _ChartLegend(color: Colors.red, label: 'Expenses'),
            ],
          ),
          const Gap(20),
          // Chart
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: _buildBarGroups(series),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) =>
                          _getBottomTitle(value, series),
                      reservedSize: 32,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _getGridInterval(series),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).colorScheme.outline.withAlpha(20),
                    strokeWidth: 1,
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final point = series.points[groupIndex];
                      final isIncome = rodIndex == 0;
                      final value = isIncome ? point.income : point.expenses;
                      final formatter =
                          NumberFormat.currency(symbol: '\$', decimalDigits: 0);
                      return BarTooltipItem(
                        '${isIncome ? 'Income' : 'Expenses'}\n${formatter.format(value)}',
                        TextStyle(
                          color: isIncome ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(TimeSeries series) {
    return series.points.asMap().entries.map((entry) {
      final idx = entry.key;
      final point = entry.value;
      return BarChartGroupData(
        x: idx,
        barsSpace: 2,
        barRods: [
          BarChartRodData(
            toY: point.income,
            color: Colors.green.withAlpha(200),
            width: _getBarWidth(series.points.length),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: point.expenses,
            color: Colors.red.withAlpha(200),
            width: _getBarWidth(series.points.length),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();
  }

  double _getBarWidth(int pointCount) {
    if (pointCount <= 7) return 12;
    if (pointCount <= 14) return 8;
    return 6;
  }

  double _getGridInterval(TimeSeries series) {
    double maxValue = 0;
    for (final point in series.points) {
      if (point.income > maxValue) maxValue = point.income;
      if (point.expenses > maxValue) maxValue = point.expenses;
    }
    if (maxValue <= 0) return 100;
    return (maxValue / 4).ceilToDouble();
  }

  Widget _getBottomTitle(double value, TimeSeries series) {
    final idx = value.toInt();
    if (idx < 0 || idx >= series.points.length) return const SizedBox();

    final point = series.points[idx];
    String label;
    switch (_granularity) {
      case TimeSeriesGranularity.daily:
        label = DateFormat('d').format(point.date);
        break;
      case TimeSeriesGranularity.weekly:
        label = 'W${((idx % 52) + 1)}';
        break;
      case TimeSeriesGranularity.monthly:
        label = DateFormat('MMM').format(point.date);
        break;
    }

    // Adaptive label visibility based on data density
    final step = series.points.length > 12 ? 3 : (series.points.length > 7 ? 2 : 1);
    if (idx % step != 0 && idx != series.points.length - 1) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withAlpha(200),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const Gap(6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
