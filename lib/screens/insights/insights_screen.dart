import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../premium/premium_features.dart';
import '../../providers/insights_providers.dart';
import '../../providers/premium_provider.dart';
import '../../repositories/transaction_repository.dart';
import '../../providers/repository_providers.dart';
import '../../services/insights_service.dart';
import '../../services/observability_service.dart';
import '../../widgets/premium/premium_gate.dart';

/// AI Insights screen - read-only cards from analytics context
/// Premium-gated. No chat UI. No raw transactions.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = ref.watch(isFeatureLockedProvider(PremiumFeature.aiInsights));

    return Scaffold(
      appBar: AppBar(title: const Text('AI Insights')),
      body: isLocked
          ? const Center(child: PremiumLockedCard(feature: PremiumFeature.aiInsights))
          : const _InsightsContent(),
    );
  }
}

class _InsightsContent extends ConsumerWidget {
  const _InsightsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(insightsProvider, (prev, next) {
      if (next.hasValue && next.value!.isNotEmpty && (prev == null || !prev.hasValue)) {
        ObservabilityService.trackAiInsightViewed();
      }
    });
    final insightsAsync = ref.watch(insightsProvider);
    final periodType = ref.watch(periodTypeProvider);
    final walletId = ref.watch(selectedWalletIdProvider);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final last = ref.read(lastInsightRefreshProvider);
              if (last != null && DateTime.now().difference(last) < const Duration(seconds: 10)) return;
              ref.read(lastInsightRefreshProvider.notifier).state = DateTime.now();
              ref.invalidate(insightsProvider);
            },
          ),
        ),
        Expanded(
          child: insightsAsync.when(
            data: (insights) => _buildContent(context, insights, periodType, walletId),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const Gap(16),
                  Text('Could not load insights', style: Theme.of(context).textTheme.titleMedium),
                  const Gap(8),
                  Text(e.toString(), style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Insight> insights,
    PeriodType periodType,
    String? walletId,
  ) {
    final periodLabel = periodType == PeriodType.month ? 'this month' : 'this period';

    if (insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights_outlined, size: 64, color: Colors.grey.shade400),
            const Gap(16),
            Text(
              'No insights yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(8),
            Text(
              'Add transactions to get personalized insights.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.primary),
                const Gap(8),
                Text(
                  'Generated for $periodLabel${walletId != null ? ' (filtered)' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const Gap(24),
          Text(
            'Insights',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Gap(16),
          ...insights.map((insight) => _InsightCard(insight: insight)),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Insight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber.shade700),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Gap(6),
                Text(
                  insight.reason,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
