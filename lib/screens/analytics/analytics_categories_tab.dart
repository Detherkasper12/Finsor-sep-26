import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/analytics_providers.dart';
import '../../repositories/analytics_models.dart';
import '../../widgets/analytics/analytics_shared_widgets.dart';

/// Categories tab showing pie chart and full category breakdown
/// NOTE: Transfers are excluded from this breakdown per design
class AnalyticsCategoriesTab extends ConsumerWidget {
  const AnalyticsCategoriesTab({super.key});

  static const _categoryColors = [
    Color(0xFFE53935), // Red
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFFB8C00), // Orange
    Color(0xFF8E24AA), // Purple
    Color(0xFF00ACC1), // Cyan
    Color(0xFFD81B60), // Pink
    Color(0xFF3949AB), // Indigo
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(currentMonthCategoryBreakdownProvider);

    return breakdownAsync.when(
      data: (breakdown) {
        if (breakdown.isEmpty) {
          return const AnalyticsEmptyState(
            message: 'No expense data for this period\nTransfers are excluded from category analysis',
            icon: Icons.pie_chart_outline,
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pie Chart Section
              _buildPieChartSection(context, breakdown),
              const Gap(24),

              // Category List Section
              const AnalyticsSectionHeader(title: 'All Categories'),

              ...breakdown.categories.asMap().entries.map((entry) {
                final idx = entry.key;
                final cat = entry.value;
                return AnalyticsCategoryRow(
                  category: cat,
                  color: _categoryColors[idx % _categoryColors.length],
                );
              }),

              const Gap(16),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const AnalyticsErrorCard(
        message: 'Failed to load category breakdown',
      ),
    );
  }

  Widget _buildPieChartSection(BuildContext context, CategoryBreakdown breakdown) {
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
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _buildPieSections(breakdown),
                centerSpaceRadius: 45,
                sectionsSpace: 3,
              ),
            ),
          ),
          const Gap(16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: breakdown.categories.take(4).toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final cat = entry.value;
              return _LegendItem(
                color: _categoryColors[idx % _categoryColors.length],
                label: cat.categoryName,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(CategoryBreakdown breakdown) {
    return breakdown.categories.asMap().entries.map((entry) {
      final idx = entry.key;
      final cat = entry.value;
      return PieChartSectionData(
        value: cat.amount,
        title: cat.percentage >= 8 ? '${cat.percentage.toStringAsFixed(0)}%' : '',
        color: _categoryColors[idx % _categoryColors.length],
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
