import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/category.dart';
import '../providers/categories_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../constants/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../providers/settings_provider.dart';
import '../screens/edit_transaction_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../utils/page_transitions.dart';
import '../utils/category_icon_mapper.dart';
import 'add_transaction_bottom_sheet.dart';

enum TransactionFilter {
  all,
  today,
  yesterday,
  thisWeek,
  thisMonth,
  income,
  expense,
  transfer,
}

class EnhancedTransactionList extends ConsumerStatefulWidget {
  final bool showHeader;
  final int? limit;
  final String? searchQuery;
  final String? walletFilter;

  const EnhancedTransactionList({
    super.key,
    this.showHeader = true,
    this.limit,
    this.searchQuery,
    this.walletFilter,
  });

  @override
  ConsumerState<EnhancedTransactionList> createState() => _EnhancedTransactionListState();
}

class _EnhancedTransactionListState extends ConsumerState<EnhancedTransactionList> {
  TransactionFilter _selectedFilter = TransactionFilter.all;
  final Map<String, bool> _expandedSections = {};

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(recentTransactionsProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final transactions = transactionsAsync.valueOrNull ?? [];
    final wallets = walletsAsync.valueOrNull ?? [];
    final categories = categoriesAsync.valueOrNull ?? [];

    if (transactionsAsync.isLoading && transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    var filtered = _filterTransactions(transactions);
    if (widget.walletFilter != null) {
      filtered = filtered
          .where((t) =>
              t.walletId == widget.walletFilter ||
              t.toWalletId == widget.walletFilter)
          .toList();
    }
    if (widget.searchQuery != null && widget.searchQuery!.trim().isNotEmpty) {
      final q = widget.searchQuery!.trim().toLowerCase();
      final parsedAmount = _tryParseAmount(q);
      filtered = filtered.where((t) {
        final desc = (t.description ?? '').toLowerCase();
        final match = categories.where((c) => c.id == t.categoryId);
        final catName = (match.isEmpty ? '' : match.first.name).toLowerCase();
        if (parsedAmount != null) {
          if ((t.amount - parsedAmount).abs() < 0.01) return true;
        }
        return desc.contains(q) || catName.contains(q);
      }).toList();
    }
    final filteredTransactions = filtered;
    final groupedTransactions = _groupTransactionsByDate(filteredTransactions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          _buildHeader(),
          _buildFilterChips(),
          const Gap(16),
        ],
        
        if (groupedTransactions.isEmpty)
          _buildEmptyState()
        else
          ...groupedTransactions.entries.map((entry) {
            final date = entry.key;
            final dayTransactions = entry.value;
            final isExpanded = _expandedSections[date] ?? true;

            return Column(
              children: [
                _buildDateHeader(date, dayTransactions, isExpanded),
                if (isExpanded)
                  ...dayTransactions.map((transaction) => 
                    _buildTransactionItem(transaction, wallets, categories)
                  ),
                const Gap(8),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Transactions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton.icon(
            onPressed: _showAllTransactions,
            icon: const Icon(Icons.list_alt),
            label: const Text('See All'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: TransactionFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getFilterLabel(filter)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateHeader(String date, List<Transaction> transactions, bool isExpanded) {
    final totalAmount = transactions.fold<double>(
      0.0,
      (sum, transaction) => sum + _getSignedAmount(transaction),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _expandedSections[date] = !isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const Gap(8),
                Text(
                  _formatDateHeader(date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${transactions.length} transaction${transactions.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(8),
                Text(
                  _formatCurrency(totalAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: totalAmount >= 0 
                        ? AppTheme.getTransactionColor('income', isDark: Theme.of(context).brightness == Brightness.dark)
                        : AppTheme.getTransactionColor('expense', isDark: Theme.of(context).brightness == Brightness.dark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    Transaction transaction,
    List<Wallet> wallets,
    List<Category> categories,
  ) {
    final wallet = wallets.firstWhere(
      (w) => w.id == transaction.walletId,
      orElse: () => Wallet(
        id: 'unknown',
        name: 'Unknown Wallet',
        type: WalletType.other,
        currency: 'USD',
        createdAt: DateTime.now(),
      ),
    );

    final category = categories.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => Category(
        id: 'unknown',
        name: 'Unknown',
        type: transaction.type,
        iconName: 'category',
        color: '#666666',
        createdAt: DateTime.now(),
      ),
    );

    final signedAmount = _getSignedAmount(transaction);
    final categoryColor = Color(int.parse(category.color.replaceAll('#', '0xFF')));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showTransactionDetails(transaction),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Category icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(category.iconName),
                    color: categoryColor,
                    size: 20,
                  ),
                ),
                
                const Gap(12),
                
                // Transaction details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              transaction.description ?? category.name,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatCurrency(signedAmount),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getAmountColor(transaction.type, context),
                            ),
                          ),
                        ],
                      ),
                      const Gap(2),
                      Row(
                        children: [
                          Icon(
                            _getWalletIcon(wallet.type),
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const Gap(4),
                          Text(
                            wallet.name,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            DateFormat('HH:mm').format(transaction.createdAt),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // More options button
                IconButton(
                  onPressed: () => _showTransactionOptions(transaction),
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const Gap(16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const Gap(8),
          Text(
            'Try adjusting your filters or add your first transaction',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    List<Transaction> filtered;

    switch (_selectedFilter) {
      case TransactionFilter.all:
        filtered = transactions;
        break;
      case TransactionFilter.today:
        filtered = transactions.where((t) => 
          t.createdAt.isAfter(today.subtract(const Duration(microseconds: 1)))
        ).toList();
        break;
      case TransactionFilter.yesterday:
        filtered = transactions.where((t) => 
          t.createdAt.isAfter(yesterday.subtract(const Duration(microseconds: 1))) &&
          t.createdAt.isBefore(today)
        ).toList();
        break;
      case TransactionFilter.thisWeek:
        filtered = transactions.where((t) => 
          t.createdAt.isAfter(weekStart.subtract(const Duration(microseconds: 1)))
        ).toList();
        break;
      case TransactionFilter.thisMonth:
        filtered = transactions.where((t) => 
          t.createdAt.isAfter(monthStart.subtract(const Duration(microseconds: 1)))
        ).toList();
        break;
      case TransactionFilter.income:
        filtered = transactions.where((t) => t.type == TransactionType.income).toList();
        break;
      case TransactionFilter.expense:
        filtered = transactions.where((t) => t.type == TransactionType.expense).toList();
        break;
      case TransactionFilter.transfer:
        filtered = transactions.where((t) => t.type == TransactionType.transfer).toList();
        break;
    }

    if (widget.limit != null) {
      filtered = filtered.take(widget.limit!).toList();
    }

    return filtered;
  }

  Map<String, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    final grouped = <String, List<Transaction>>{};
    
    for (final transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(transaction);
    }

    // Sort by date (newest first)
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Map.fromEntries(sortedEntries);
  }

  String _getFilterLabel(TransactionFilter filter) {
    switch (filter) {
      case TransactionFilter.all:
        return 'All';
      case TransactionFilter.today:
        return 'Today';
      case TransactionFilter.yesterday:
        return 'Yesterday';
      case TransactionFilter.thisWeek:
        return 'This Week';
      case TransactionFilter.thisMonth:
        return 'This Month';
      case TransactionFilter.income:
        return 'Income';
      case TransactionFilter.expense:
        return 'Expense';
      case TransactionFilter.transfer:
        return 'Transfer';
    }
  }

  String _formatDateHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(today)) {
      return 'Today';
    } else if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  double _getSignedAmount(Transaction transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        return transaction.amount;
      case TransactionType.expense:
        return -transaction.amount;
      case TransactionType.transfer:
        return 0; // Transfers are neutral for display
    }
  }

  Color _getAmountColor(TransactionType type, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case TransactionType.income:
        return AppTheme.getTransactionColor('income', isDark: isDark);
      case TransactionType.expense:
        return AppTheme.getTransactionColor('expense', isDark: isDark);
      case TransactionType.transfer:
        return AppTheme.getTransactionColor('transfer', isDark: isDark);
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount);
  }

  void _showAllTransactions() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransactionsScreen()),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transaction: transaction),
      ),
    );
  }


  void _showTransactionOptions(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(16),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Transaction'),
              onTap: () {
                Navigator.pop(context);
                _editTransaction(transaction);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.green),
              title: const Text('Duplicate Transaction'),
              onTap: () {
                Navigator.pop(context);
                _duplicateTransaction(transaction);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Transaction'),
              onTap: () {
                Navigator.pop(context);
                _deleteTransaction(transaction);
              },
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }

  void _editTransaction(Transaction transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(transaction: transaction),
      ),
    );
  }

  void _duplicateTransaction(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionBottomSheet(
        initialType: transaction.type,
        initialCategoryId: transaction.categoryId,
        initialWalletId: transaction.walletId,
        initialAmount: transaction.amount.toString(),
        initialDescription: transaction.description,
        initialDate: transaction.createdAt,
        initialToWalletId: transaction.toWalletId,
      ),
    );
  }

  void _deleteTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete this transaction?\n\n'
          '${transaction.description ?? transaction.categoryId}\n'
          '${_formatCurrency(transaction.type == TransactionType.expense ? -transaction.amount : transaction.amount)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final deleted = transaction;
              try {
                await ref.read(transactionNotifierProvider.notifier).deleteTransaction(transaction.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Transaction deleted'),
                      backgroundColor: Colors.grey[800],
                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: Colors.white,
                        onPressed: () async {
                          await ref.read(transactionNotifierProvider.notifier).addTransaction(deleted);
                        },
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) => CategoryIcons.fromName(iconName);

  static double? _tryParseAmount(String input) {
    final normalized = input.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  IconData _getWalletIcon(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return Icons.payments;
      case WalletType.bank:
        return Icons.account_balance;
      case WalletType.card:
        return Icons.credit_card;
      case WalletType.savings:
        return Icons.savings;
      case WalletType.investment:
        return Icons.trending_up;
      case WalletType.crypto:
        return Icons.currency_bitcoin;
      case WalletType.other:
        return Icons.account_balance_wallet;
    }
  }
}
