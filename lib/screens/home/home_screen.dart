import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/repository_providers.dart';
import '../../repositories/transaction_repository.dart';
import '../../models/transaction.dart';
import '../../models/wallet.dart';
import 'widgets/balance_card.dart';
import '../transactions/transactions_screen.dart';

/// Home screen showing balance, period summary, and recent transactions
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final summaryAsync = ref.watch(periodSummaryProvider);
    final recentTxAsync = ref.watch(recentTransactionsProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final selectedWalletId = ref.watch(selectedWalletIdProvider);
    final periodType = ref.watch(periodTypeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(walletsProvider);
            ref.invalidate(periodSummaryProvider);
            ref.invalidate(recentTransactionsProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(child: _buildHeader(context)),

              const SliverGap(8),

              // Wallet Selector
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: walletsAsync.when(
                    data: (wallets) => _WalletSelector(
                      wallets: wallets,
                      selectedId: selectedWalletId,
                      onSelected: (id) =>
                          ref.read(selectedWalletIdProvider.notifier).state = id,
                    ),
                    loading: () => const SizedBox(height: 48),
                    error: (_, __) => const SizedBox(height: 48),
                  ),
                ),
              ),

              const SliverGap(16),

              // Balance Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: walletsAsync.when(
                    data: (wallets) {
                      final balance = _calculateBalance(wallets, selectedWalletId);
                      final showBalance = settingsAsync.maybeWhen(
                        data: (s) => s.showBalanceOnHome,
                        orElse: () => true,
                      );
                      return BalanceCard(
                        balance: balance,
                        showBalance: showBalance,
                        onToggleVisibility: () {},
                      );
                    },
                    loading: () => const _BalanceCardSkeleton(),
                    error: (_, __) => const _ErrorCard(message: 'Failed to load balance'),
                  ),
                ),
              ),

              const SliverGap(16),

              // Period Filter
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PeriodFilter(
                    selected: periodType,
                    onChanged: (type) =>
                        ref.read(periodTypeProvider.notifier).state = type,
                  ),
                ),
              ),

              const SliverGap(12),

              // Income/Expense Summary
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: summaryAsync.when(
                    data: (summary) => _SummaryCards(summary: summary),
                    loading: () => const _SummaryCardsSkeleton(),
                    error: (_, __) => const _ErrorCard(message: 'Failed to load summary'),
                  ),
                ),
              ),

              const SliverGap(20),

              // Recent Transactions Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                        ),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ),
              ),

              // Transaction List
              recentTxAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: _EmptyTransactions(),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = transactions[index] as Transaction;
                        return _TransactionTile(transaction: tx);
                      },
                      childCount: transactions.length,
                    ),
                  );
                },
                loading: () => SliverToBoxAdapter(
                  child: _buildTransactionsSkeleton(),
                ),
                error: (_, __) => const SliverToBoxAdapter(
                  child: _ErrorCard(message: 'Failed to load transactions'),
                ),
              ),

              const SliverGap(100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_getGreeting()}!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const Gap(4),
              Text(
                'Finsor',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  double _calculateBalance(List<Wallet> wallets, String? selectedId) {
    if (selectedId == null) {
      return wallets
          .where((w) => w.includeInTotal)
          .fold(0.0, (sum, w) => sum + w.currentBalance);
    }
    final wallet = wallets.where((w) => w.id == selectedId).firstOrNull;
    return wallet?.currentBalance ?? 0.0;
  }

  Widget _buildTransactionsSkeleton() {
    return Column(
      children: List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _SkeletonBox(height: 64),
        ),
      ),
    );
  }
}

// ==================== WALLET SELECTOR ====================

class _WalletSelector extends StatelessWidget {
  final List<Wallet> wallets;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _WalletSelector({
    required this.wallets,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _WalletChip(
            label: 'All Wallets',
            isSelected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          const Gap(8),
          ...wallets.map((w) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _WalletChip(
                  label: w.name,
                  isSelected: selectedId == w.id,
                  onTap: () => onSelected(w.id),
                ),
              )),
        ],
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _WalletChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ==================== PERIOD FILTER ====================

class _PeriodFilter extends StatelessWidget {
  final PeriodType selected;
  final ValueChanged<PeriodType> onChanged;

  const _PeriodFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: 'Week',
          isSelected: selected == PeriodType.week,
          onTap: () => onChanged(PeriodType.week),
        ),
        const Gap(8),
        _FilterChip(
          label: 'Month',
          isSelected: selected == PeriodType.month,
          onTap: () => onChanged(PeriodType.month),
        ),
        const Gap(8),
        _FilterChip(
          label: 'Custom',
          isSelected: selected == PeriodType.custom,
          onTap: () => onChanged(PeriodType.custom),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ==================== SUMMARY CARDS ====================

class _SummaryCards extends StatelessWidget {
  final PeriodSummary summary;

  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Income',
            amount: formatter.format(summary.income),
            color: Colors.green,
            icon: Icons.arrow_downward,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _StatCard(
            title: 'Expenses',
            amount: formatter.format(summary.expenses),
            color: Colors.red,
            icon: Icons.arrow_upward,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _StatCard(
            title: 'Balance',
            amount: formatter.format(summary.balance),
            color: summary.isPositive ? Colors.blue : Colors.orange,
            icon: summary.isPositive ? Icons.trending_up : Icons.trending_down,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const Gap(4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCardsSkeleton extends StatelessWidget {
  const _SummaryCardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _SkeletonBox(height: 72)),
        Gap(12),
        Expanded(child: _SkeletonBox(height: 72)),
        Gap(12),
        Expanded(child: _SkeletonBox(height: 72)),
      ],
    );
  }
}

// ==================== TRANSACTION TILE ====================

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final isIncome = transaction.type == TransactionType.income;
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormatter = DateFormat('MMM d, h:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isExpense ? Colors.red : Colors.green).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isExpense
                    ? Icons.arrow_upward
                    : isIncome
                        ? Icons.arrow_downward
                        : Icons.swap_horiz,
                color: isExpense ? Colors.red : Colors.green,
                size: 20,
              ),
            ),
            const Gap(12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? transaction.categoryId,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dateFormatter.format(transaction.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '${isExpense ? '-' : '+'}${formatter.format(transaction.amount)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isExpense ? Colors.red : Colors.green,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== EMPTY & ERROR STATES ====================

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          const Gap(16),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
          const Gap(8),
          Text(
            'Tap + to add your first transaction',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const Gap(12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCardSkeleton extends StatelessWidget {
  const _BalanceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const _SkeletonBox(height: 120);
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;

  const _SkeletonBox({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
