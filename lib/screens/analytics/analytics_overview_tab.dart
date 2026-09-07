import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../providers/analytics_providers.dart';
import '../../widgets/analytics/analytics_shared_widgets.dart';

/// Overview tab showing period comparison and top spending categories
class AnalyticsOverviewTab extends ConsumerWidget {
  const AnalyticsOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(currentMonthCategoryBreakdownProvider);
    final comparisonAsync = ref.watch(monthOverMonthComparisonProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Comparison Section
          comparisonAsync.when(
            data: (comparison) => AnalyticsComparisonCard(comparison: comparison),
            loading: () => const AnalyticsSkeletonBox(height: 130),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const Gap(24),

          // Top Spending Section
          const AnalyticsSectionHeader(title: 'Top Spending'),

          breakdownAsync.when(
            data: (breakdown) {
              if (breakdown.isEmpty) {
                return const AnalyticsEmptyState(
                  message: 'No expenses yet\nAdd transactions to see your spending breakdown',
                  icon: Icons.receipt_long_outlined,
                );
              }
              final top = breakdown.topCategories(5);
              return Column(
                children: top
                    .map((cat) => AnalyticsCategoryRow(category: cat))
                    .toList(),
              );
            },
            loading: () => Column(
              children: List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: AnalyticsSkeletonBox(height: 72),
                ),
              ),
            ),
            error: (_, __) => const AnalyticsErrorCard(
              message: 'Failed to load spending data',
            ),
          ),

          const Gap(16),
        ],
      ),
    );
  }
}
