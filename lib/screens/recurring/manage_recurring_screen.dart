import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../models/recurring_transaction.dart';
import '../../models/transaction.dart';
import '../../providers/recurring_provider.dart';
import '../../constants/app_theme.dart';

class ManageRecurringScreen extends ConsumerWidget {
  const ManageRecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Transactions')),
      body: recurringAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (ctx, i) => _RecurringTile(rt: list[i]),
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.repeat, size: 64, color: Colors.grey[300]),
          const Gap(16),
          Text('No recurring transactions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
          const Gap(8),
          Text('Enable "Repeat" when adding a transaction',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _RecurringTile extends ConsumerWidget {
  final RecurringTransaction rt;
  const _RecurringTile({required this.rt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = rt.type == TransactionType.income
        ? Colors.green
        : rt.type == TransactionType.expense
            ? Colors.red
            : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.repeat, color: color, size: 20),
                const Gap(8),
                Expanded(
                  child: Text(
                    rt.description ?? rt.type.name.toUpperCase(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rt.isPaused ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rt.isPaused ? 'Paused' : 'Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: rt.isPaused ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(8),
            Row(
              children: [
                Text(
                  '\$${rt.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  rt.frequencyLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const Gap(8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const Gap(4),
                Text(
                  'Next: ${DateFormat('MMM dd, yyyy').format(rt.nextRunDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (rt.endDate != null) ...[
                  const Gap(12),
                  Text(
                    'Until: ${DateFormat('MMM dd').format(rt.endDate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => ref.read(recurringNotifierProvider.notifier).togglePause(rt.id),
                  icon: Icon(rt.isPaused ? Icons.play_arrow : Icons.pause, size: 18),
                  label: Text(rt.isPaused ? 'Resume' : 'Pause'),
                ),
                const Gap(8),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recurring'),
        content: const Text('This will stop generating future transactions. Existing transactions remain.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(recurringNotifierProvider.notifier).deleteRecurring(rt.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
