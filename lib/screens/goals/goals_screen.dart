import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../models/goal.dart';
import '../../providers/goals_provider.dart';
import 'add_edit_goal_screen.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Goals & Debts'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Savings'),
              Tab(text: 'Debts'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GoalListTab(type: GoalType.savings),
            _GoalListTab(type: GoalType.debt),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditGoalScreen()),
          ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _GoalListTab extends ConsumerWidget {
  final GoalType type;
  const _GoalListTab({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = type == GoalType.savings
        ? ref.watch(savingsGoalsProvider)
        : ref.watch(debtGoalsProvider);

    return goalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (goals) => goals.isEmpty
          ? _buildEmpty(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (ctx, i) => _GoalCard(goal: goals[i]),
            ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final label = type == GoalType.savings ? 'savings goals' : 'debts';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type == GoalType.savings ? Icons.savings : Icons.account_balance,
            size: 64,
            color: Colors.grey[300],
          ),
          const Gap(16),
          Text('No $label yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
          const Gap(8),
          Text('Tap + to create one',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(goal.color.replaceAll('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: goal.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(
                      goal.isSavings ? Icons.savings : Icons.account_balance,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(goal.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        if (goal.debtorName != null && goal.debtorName!.isNotEmpty)
                          Text(goal.debtorName!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(
                    '${(goal.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const Gap(12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 8,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${goal.currentAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'of \$${goal.targetAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
