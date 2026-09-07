import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction.dart';
import '../../../models/wallet.dart';
import '../../../models/category.dart';
import '../../../utils/category_icon_mapper.dart';

/// Transaction list widget for home screen
class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final List<Category> categories;
  final List<Wallet> wallets;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.categories,
    required this.wallets,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyTransactionState(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final transaction = transactions[index];
          final category = categories.firstWhere(
            (c) => c.id == transaction.categoryId,
            orElse: () => categories.first,
          );
          final wallet = wallets.firstWhere(
            (w) => w.id == transaction.walletId,
            orElse: () => wallets.first,
          );

          return TransactionItem(
            transaction: transaction,
            category: category,
            wallet: wallet,
            onTap: () => _showTransactionDetails(context, transaction, category, wallet),
          );
        },
        childCount: transactions.length,
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, Transaction transaction, Category category, Wallet wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailsSheet(
        transaction: transaction,
        category: category,
        wallet: wallet,
      ),
    );
  }
}

/// Individual transaction item
class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final Category category;
  final Wallet wallet;
  final VoidCallback onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.category,
    required this.wallet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getTransactionColor();
    final categoryColor = Color(int.parse(category.color.replaceAll('#', '0xFF')));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(),
                    color: categoryColor,
                    size: 20,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description?.isNotEmpty == true
                            ? transaction.description!
                            : category.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(2),
                      Text(
                        transaction.isRecurring
                            ? '${category.name} • Recurring • ${_formatRelativeTime()}'
                            : '${category.name} • ${_formatRelativeTime()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatAmount(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (transaction.isRecurring) ...[
                      const Gap(2),
                      Tooltip(
                        message: 'Recurring',
                        child: Icon(
                          Icons.repeat,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTransactionColor() {
    switch (transaction.type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon() => CategoryIcons.fromName(category.iconName);

  String _formatAmount() {
    final prefix = transaction.type == TransactionType.expense ? '-' : '+';
    return '$prefix${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(transaction.amount)}';
  }

  String _formatRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(transaction.createdAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(transaction.createdAt);
    }
  }
}

/// Empty state widget
class EmptyTransactionState extends StatelessWidget {
  const EmptyTransactionState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const Gap(16),
          Text(
            'No Transactions Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const Gap(8),
          Text(
            'Start by adding your first transaction',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to add transaction
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
          ),
        ],
      ),
    );
  }
}

/// Transaction details bottom sheet
class TransactionDetailsSheet extends StatelessWidget {
  final Transaction transaction;
  final Category category;
  final Wallet wallet;

  const TransactionDetailsSheet({
    super.key,
    required this.transaction,
    required this.category,
    required this.wallet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(24),

                DetailRow('Amount', NumberFormat.currency(symbol: '\$').format(transaction.amount)),
                DetailRow('Category', category.name),
                DetailRow('Wallet', wallet.name),
                DetailRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(transaction.createdAt)),
                
                if (transaction.description?.isNotEmpty == true)
                  DetailRow('Description', transaction.description!),

                const Gap(32),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Edit transaction
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Delete transaction
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
