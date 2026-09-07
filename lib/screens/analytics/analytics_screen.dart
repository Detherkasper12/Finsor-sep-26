import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../providers/analytics_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/repository_providers.dart';
import '../../repositories/transaction_repository.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/analytics/analytics_shared_widgets.dart';
import 'analytics_overview_tab.dart';
import 'analytics_categories_tab.dart';
import 'analytics_trends_tab.dart';
import '../main_screen.dart';

/// Main Analytics screen with period/wallet selection and tabs
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final periodType = ref.watch(periodTypeProvider);
    final selectedWalletId = ref.watch(selectedWalletIdProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final summaryAsync = ref.watch(periodSummaryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const Gap(8),
            _AnalyticsPeriodPicker(
              selected: periodType,
              onChanged: (p) => ref.read(periodTypeProvider.notifier).state = p,
            ),
            const Gap(12),
            _AnalyticsWalletPicker(
              walletsAsync: walletsAsync,
              selectedId: selectedWalletId,
              onWalletSelected: (id) =>
                  ref.read(selectedWalletIdProvider.notifier).state = id,
            ),
            const Gap(8),
            _AnalyticsSummarySection(summaryAsync: summaryAsync),
            const Gap(8),
            _OverviewMetricsSection(),
            const Gap(8),
            _buildTabBar(context),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  AnalyticsOverviewTab(),
                  AnalyticsCategoriesTab(),
                  AnalyticsTrendsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
          ),
          Text(
            'Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _showFilterHelp,
            icon: Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            tooltip: 'About analytics',
          ),
        ],
      ),
    );
  }

  void _showFilterHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Analytics Filters'),
        content: const Text(
          'Use the period selector to filter by week or month.\n\n'
          'Use the wallet selector to view specific wallet analytics.\n\n'
          'Note: Transfers are excluded from income/expense totals to avoid double-counting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        labelPadding: EdgeInsets.zero,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Categories'),
          Tab(text: 'Trends'),
        ],
      ),
    );
  }
}

/// Period selector widget (Week / Month / Custom)
class _AnalyticsPeriodPicker extends StatelessWidget {
  final PeriodType selected;
  final ValueChanged<PeriodType> onChanged;

  const _AnalyticsPeriodPicker({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: PeriodType.values.map((period) {
            final isSelected = selected == period;
            final label = period.name[0].toUpperCase() + period.name.substring(1);
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(period),
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
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Wallet selector horizontal chips
class _AnalyticsWalletPicker extends StatelessWidget {
  final AsyncValue<List<dynamic>> walletsAsync;
  final String? selectedId;
  final ValueChanged<String?> onWalletSelected;

  const _AnalyticsWalletPicker({
    required this.walletsAsync,
    required this.selectedId,
    required this.onWalletSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 40,
        child: walletsAsync.when(
          data: (wallets) => ListView(
            scrollDirection: Axis.horizontal,
            children: [
              AnalyticsWalletChip(
                label: 'All Wallets',
                isSelected: selectedId == null,
                onTap: () => onWalletSelected(null),
              ),
              const Gap(8),
              ...wallets.map((w) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnalyticsWalletChip(
                      label: w.name,
                      isSelected: selectedId == w.id,
                      onTap: () => onWalletSelected(w.id),
                    ),
                  )),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Summary cards section (Income / Expenses / Net)
class _AnalyticsSummarySection extends StatelessWidget {
  final AsyncValue<PeriodSummary> summaryAsync;

  const _AnalyticsSummarySection({required this.summaryAsync});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: summaryAsync.when(
        data: (summary) => Row(
          children: [
            Expanded(
              child: AnalyticsSummaryCard(
                title: 'Income',
                amount: summary.income,
                color: Colors.green,
                icon: Icons.arrow_downward,
              ),
            ),
            const Gap(10),
            Expanded(
              child: AnalyticsSummaryCard(
                title: 'Expenses',
                amount: summary.expenses,
                color: Colors.red,
                icon: Icons.arrow_upward,
              ),
            ),
            const Gap(10),
            Expanded(
              child: AnalyticsSummaryCard(
                title: 'Net',
                amount: summary.balance,
                color: summary.isPositive ? Colors.green : Colors.red,
                icon: summary.isPositive ? Icons.trending_up : Icons.trending_down,
              ),
            ),
          ],
        ),
        loading: () => const AnalyticsSummaryCardsSkeleton(),
        error: (_, __) => const AnalyticsErrorCard(message: 'Failed to load summary'),
      ),
    );
  }
}

/// Overview metrics row: Savings Rate %, Biggest Expense, Avg Daily Spend
class _OverviewMetricsSection extends ConsumerWidget {
  const _OverviewMetricsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(overviewMetricsProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: metricsAsync.when(
        data: (m) {
          final currency = settingsAsync.valueOrNull?.primaryCurrency;
          final format = (double amount) => currency != null
              ? CurrencyFormatter.formatAmount(amount, currency)
              : '\$${amount.toStringAsFixed(0)}';

          return Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Savings Rate',
                  value: m.savingsRatePercent != null
                      ? '${m.savingsRatePercent!.toStringAsFixed(1)}%'
                      : '—',
                  subtitle: null,
                ),
              ),
              const Gap(8),
              Expanded(
                child: _MetricCard(
                  title: 'Biggest Expense',
                  value: m.biggestExpenseAmount != null
                      ? format(m.biggestExpenseAmount!)
                      : '—',
                  subtitle: m.biggestExpenseAmount != null ? m.biggestExpenseLabel : null,
                ),
              ),
              const Gap(8),
              Expanded(
                child: _MetricCard(
                  title: 'Avg Daily',
                  value: m.daysInPeriod > 0 ? format(m.averageDailySpend) : '—',
                  subtitle: null,
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(height: 72),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const Gap(4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const Gap(2),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }
}
