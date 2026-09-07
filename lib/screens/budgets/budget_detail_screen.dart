import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../models/budget.dart';
import '../../providers/budgets_provider.dart';
import '../../repositories/budget_repository.dart';
import 'create_budget_screen.dart';

class BudgetDetailScreen extends ConsumerWidget {
  final String budgetId;

  const BudgetDetailScreen({super.key, required this.budgetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(computedBudgetProvider(budgetId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Details'),
        actions: [
          budgetAsync.maybeWhen(
            data: (cb) => cb != null
                ? PopupMenuButton<String>(
                    onSelected: (action) => _handleAction(context, ref, action, cb),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit Budget')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: budgetAsync.when(
        data: (cb) => cb != null
            ? _BudgetDetailContent(budget: cb)
            : const Center(child: Text('Budget not found')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action, ComputedBudget cb) {
    if (action == 'delete') {
      _showDeleteConfirmation(context, ref, cb);
    } else if (action == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreateBudgetScreen(budget: cb.budget)),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, ComputedBudget cb) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Are you sure you want to delete "${cb.budget.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(budgetNotifierProvider.notifier).deleteBudget(cb.budget.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _BudgetDetailContent extends StatelessWidget {
  final ComputedBudget budget;

  const _BudgetDetailContent({required this.budget});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final statusColor = Color(int.parse(budget.statusColor.replaceAll('#', '0xFF')));
    final progress = (budget.percentageUsed / 100).clamp(0.0, 1.0);
    final dateFormat = DateFormat('MMM d, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor.withAlpha(200), statusColor],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  budget.budget.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    budget.statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Gap(24),
                Text(
                  formatter.format(budget.spent),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'of ${formatter.format(budget.budget.amount)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const Gap(20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white.withAlpha(60),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const Gap(8),
                Text(
                  '${budget.percentageUsed.toStringAsFixed(1)}% used',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const Gap(24),

          // Details Section
          _SectionCard(
            title: 'Budget Details',
            children: [
              _DetailRow(label: 'Budget Limit', value: formatter.format(budget.budget.amount)),
              _DetailRow(label: 'Spent', value: formatter.format(budget.spent)),
              _DetailRow(
                label: 'Remaining',
                value: formatter.format(budget.remaining),
                valueColor: budget.remaining >= 0 ? Colors.green : Colors.red,
              ),
              const Divider(height: 24),
              _DetailRow(label: 'Period', value: budget.budget.periodDisplayName),
              _DetailRow(label: 'Start Date', value: dateFormat.format(budget.budget.startDate)),
              _DetailRow(label: 'End Date', value: dateFormat.format(budget.budget.endDate)),
            ],
          ),

          const Gap(16),

          // Scope Section
          _SectionCard(
            title: 'Scope',
            children: [
              _DetailRow(
                label: 'Category',
                value: budget.categoryName ?? 'All Categories',
              ),
              _DetailRow(
                label: 'Wallet',
                value: budget.walletName ?? 'All Wallets',
              ),
            ],
          ),

          const Gap(16),

          // Alert Settings
          _SectionCard(
            title: 'Alert Settings',
            children: [
              _DetailRow(
                label: 'Warning Threshold',
                value: '${budget.budget.warningThreshold.toStringAsFixed(0)}%',
              ),
              _DetailRow(
                label: 'Notifications',
                value: budget.budget.notifyWhenExceeded ? 'Enabled' : 'Disabled',
              ),
            ],
          ),

          const Gap(32),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Gap(12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
