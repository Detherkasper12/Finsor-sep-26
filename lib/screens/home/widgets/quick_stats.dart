import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction.dart';

/// Quick stats widget showing income, expenses, and savings
class QuickStats extends StatelessWidget {
  final List<Transaction> transactions;

  const QuickStats({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final thisMonth = DateTime.now();
    final startOfMonth = DateTime(thisMonth.year, thisMonth.month, 1);
    final endOfMonth = DateTime(thisMonth.year, thisMonth.month + 1, 0);

    final monthTransactions = transactions.where((t) =>
        t.createdAt.isAfter(startOfMonth) && t.createdAt.isBefore(endOfMonth)
    ).toList();

    final income = monthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final expenses = monthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final savings = income - expenses;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Income',
            amount: income,
            color: Colors.green,
            icon: Icons.trending_up,
          ),
        ),
        const Gap(12),
        Expanded(
          child: StatCard(
            title: 'Expenses',
            amount: expenses,
            color: Colors.red,
            icon: Icons.trending_down,
          ),
        ),
        const Gap(12),
        Expanded(
          child: StatCard(
            title: 'Savings',
            amount: savings,
            color: savings >= 0 ? Colors.blue : Colors.orange,
            icon: savings >= 0 ? Icons.savings : Icons.warning,
          ),
        ),
      ],
    );
  }
}

/// Individual stat card
class StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
