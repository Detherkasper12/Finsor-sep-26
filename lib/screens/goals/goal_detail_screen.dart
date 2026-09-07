import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../models/goal.dart';
import '../../models/transaction.dart';
import '../../providers/goals_provider.dart';
import '../../providers/wallet_provider.dart';
import 'add_edit_goal_screen.dart';

class GoalDetailScreen extends ConsumerWidget {
  final String goalId;
  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(goalProvider(goalId));
    final txsAsync = ref.watch(goalTransactionsProvider(goalId));

    return goalAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (goal) {
        if (goal == null) {
          return const Scaffold(body: Center(child: Text('Goal not found')));
        }
        final color = Color(int.parse(goal.color.replaceAll('#', '0xFF')));

        return Scaffold(
          appBar: AppBar(
            title: Text(goal.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddEditGoalScreen(goal: goal)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(context, ref, goal),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressCard(context, goal, color),
                const Gap(24),
                _buildQuickAction(context, ref, goal),
                const Gap(24),
                Text('Payment History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Gap(12),
                txsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (txs) => txs.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text('No payments yet',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                          ),
                        )
                      : Column(
                          children: txs.map((tx) => _buildTxTile(context, tx)).toList(),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(BuildContext context, Goal goal, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(goal.isSavings ? 'Savings Goal' : 'Debt',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
              if (goal.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Completed',
                      style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const Gap(16),
          Text(
            '\$${goal.currentAmount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color),
          ),
          Text('of \$${goal.targetAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const Gap(16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 12,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const Gap(8),
          Text(
            '${(goal.progress * 100).toStringAsFixed(1)}%',
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
          if (goal.dueDate != null) ...[
            const Gap(8),
            Text('Due: ${DateFormat('MMM dd, yyyy').format(goal.dueDate!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, WidgetRef ref, Goal goal) {
    if (goal.isCompleted) return const SizedBox.shrink();

    final label = goal.isSavings ? 'Add Funds' : 'Record Payment';
    final icon = goal.isSavings ? Icons.add_circle : Icons.payment;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddFundsDialog(context, ref, goal),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildTxTile(BuildContext context, Transaction tx) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.green.withOpacity(0.1),
        child: const Icon(Icons.payment, size: 16, color: Colors.green),
      ),
      title: Text(tx.description ?? 'Payment',
          style: Theme.of(context).textTheme.bodyMedium),
      subtitle: Text(DateFormat('MMM dd, yyyy').format(tx.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
      trailing: Text('\$${tx.amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  void _showAddFundsDialog(BuildContext context, WidgetRef ref, Goal goal) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String? selectedWalletId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            final walletsAsync = ref.watch(walletsProvider);
            final wallets = walletsAsync.valueOrNull ?? [];

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.isSavings ? 'Add Funds' : 'Record Payment',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const Gap(16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    autofocus: true,
                  ),
                  const Gap(12),
                  DropdownButtonFormField<String>(
                    value: selectedWalletId ?? (wallets.isNotEmpty ? wallets.first.id : null),
                    decoration: InputDecoration(
                      labelText: 'From Wallet',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: wallets.map((w) => DropdownMenuItem(
                      value: w.id,
                      child: Text('${w.name} (\$${w.currentBalance.toStringAsFixed(2)})'),
                    )).toList(),
                    onChanged: (v) => setLocalState(() => selectedWalletId = v),
                  ),
                  const Gap(12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Note (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const Gap(16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(amountController.text);
                        final wId = selectedWalletId ?? (wallets.isNotEmpty ? wallets.first.id : null);
                        if (amount == null || amount <= 0 || wId == null) return;
                        Navigator.pop(ctx);
                        if (goal.isSavings) {
                          ref.read(goalNotifierProvider.notifier).addFunds(
                            goalId: goal.id,
                            amount: amount,
                            walletId: wId,
                            description: descController.text.isNotEmpty ? descController.text : null,
                          );
                        } else {
                          ref.read(goalNotifierProvider.notifier).recordPayment(
                            goalId: goal.id,
                            amount: amount,
                            walletId: wId,
                            description: descController.text.isNotEmpty ? descController.text : null,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(goal.isSavings ? 'Add Funds' : 'Record Payment'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Goal goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete "${goal.name}"? Linked transactions will remain.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(goalNotifierProvider.notifier).deleteGoal(goal.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
