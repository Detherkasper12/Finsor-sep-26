import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../models/budget.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/premium_provider.dart';
import '../../repositories/budget_repository.dart';
import '../../widgets/premium/premium_gate.dart';
import 'budget_detail_screen.dart';
import 'create_budget_screen.dart';
import '../main_screen.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(activeBudgetsProvider);
    final summaryAsync = ref.watch(budgetSummaryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, ref),
            const Gap(8),
            _buildSummaryCard(context, summaryAsync),
            const Gap(16),
            Expanded(
              child: budgetsAsync.when(
                data: (budgets) => budgets.isEmpty
                    ? _BudgetsEmptyState(onAdd: () => _navigateToCreate(context))
                    : _BudgetsList(
                        budgets: budgets,
                        onTap: (cb) => _navigateToDetail(context, cb),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: budgetsAsync.maybeWhen(
        data: (b) => b.isNotEmpty
            ? FloatingActionButton(
                onPressed: () => _navigateToCreate(context),
                child: const Icon(Icons.add),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
          ),
          Text(
            'Budgets',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
          if (!isPremium) ...[
            const Gap(8),
            const PremiumBadge(size: PremiumBadgeSize.small),
          ],
          const Spacer(),
          IconButton(
            onPressed: () => _showBudgetHelp(context),
            icon: Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, AsyncValue<BudgetSummary> summaryAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: summaryAsync.when(
        data: (summary) => _BudgetSummaryCard(summary: summary),
        loading: () => Container(
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateBudgetScreen()),
    );
  }

  void _navigateToDetail(BuildContext context, ComputedBudget cb) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BudgetDetailScreen(budgetId: cb.budget.id)),
    );
  }

  void _showBudgetHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About Budgets'),
        content: const Text(
          'Set spending limits for categories to track your expenses.\n\n'
          '• Green = Under budget\n'
          '• Orange = Approaching limit (80%+)\n'
          '• Red = Exceeded\n\n'
          'Note: Transfers don\'t count toward budgets.',
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
}

class _BudgetSummaryCard extends StatelessWidget {
  final BudgetSummary summary;

  const _BudgetSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart, color: Colors.white, size: 20),
              const Gap(8),
              Text(
                'Budget Overview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (summary.hasAlerts)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.amber, size: 14),
                      const Gap(4),
                      Text(
                        '${summary.exceededCount + summary.nearLimitCount} alerts',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Total Budget',
                  value: formatter.format(summary.totalBudgetAmount),
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Spent',
                  value: formatter.format(summary.totalSpent),
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Used',
                  value: '${summary.overallPercentage.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const Gap(4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BudgetsEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _BudgetsEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.savings_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(150),
              ),
            ),
            const Gap(24),
            Text(
              'No budgets yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Gap(8),
            Text(
              'Create budgets to track your spending\nand stay on top of your finances',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const Gap(32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Budget'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetsList extends StatelessWidget {
  final List<ComputedBudget> budgets;
  final ValueChanged<ComputedBudget> onTap;

  const _BudgetsList({required this.budgets, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: budgets.length,
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (context, index) {
        final cb = budgets[index];
        return _BudgetCard(budget: cb, onTap: () => onTap(cb));
      },
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final ComputedBudget budget;
  final VoidCallback onTap;

  const _BudgetCard({required this.budget, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final statusColor = Color(int.parse(budget.statusColor.replaceAll('#', '0xFF')));
    final progress = (budget.percentageUsed / 100).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.account_balance_wallet, color: statusColor, size: 22),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.budget.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Gap(2),
                      Text(
                        '${budget.budget.periodDisplayName}${budget.categoryName != null ? ' • ${budget.categoryName}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: budget.status),
              ],
            ),
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${formatter.format(budget.spent)}',
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                ),
                Text(
                  'of ${formatter.format(budget.budget.amount)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const Gap(10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const Gap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${budget.percentageUsed.toStringAsFixed(1)}% used',
                  style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                ),
                if (budget.remaining > 0)
                  Text(
                    '${formatter.format(budget.remaining)} left',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  )
                else
                  Text(
                    'Over by ${formatter.format(-budget.remaining)}',
                    style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BudgetStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status) {
      BudgetStatus.underBudget => (Colors.green, Icons.check_circle, 'On Track'),
      BudgetStatus.nearLimit => (Colors.orange, Icons.warning_amber, 'Warning'),
      BudgetStatus.exceeded => (Colors.red, Icons.error, 'Exceeded'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const Gap(4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
