import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/currency_formatter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../models/wallet.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/category_icon_mapper.dart';
import '../../utils/category_colors.dart';
import '../../models/transaction.dart';
import '../../widgets/add_transaction_bottom_sheet.dart';
import '../main_screen.dart';
import 'add_edit_wallet_screen.dart';
import 'wallet_detail_screen.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final totalAsync = ref.watch(totalBalanceProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, totalAsync),
            Expanded(
              child: walletsAsync.when(
                data: (wallets) => wallets.isEmpty
                    ? _buildEmptyState(context)
                    : _buildWalletList(context, wallets),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'transfer_btn',
            onPressed: () => _openTransfer(context),
            child: const Icon(Icons.swap_horiz),
          ),
          const Gap(8),
          FloatingActionButton(
            heroTag: 'add_wallet_btn',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditWalletScreen()),
            ),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<double> totalAsync) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
              ),
              Text(
                'Accounts',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total balance',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const Gap(2),
                    totalAsync.when(
                      data: (total) => Text(
                        formatter.format(total),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      loading: () => const Text('...'),
                      error: (_, __) => const Text('\$0.00'),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(100)),
          const Gap(16),
          Text('No accounts yet',
              style: Theme.of(context).textTheme.titleLarge),
          const Gap(8),
          Text('Add your first account to start tracking',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildWalletList(BuildContext context, List<Wallet> wallets) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: wallets.length,
      separatorBuilder: (_, __) => const Gap(8),
      itemBuilder: (context, index) {
        final wallet = wallets[index];
        return _WalletCard(wallet: wallet);
      },
    );
  }

  void _openTransfer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const AddTransactionBottomSheet(initialType: TransactionType.transfer),
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final Wallet wallet;
  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final color = CategoryColors.fromHex(wallet.color ?? '#4CAF50');

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(CategoryIcons.walletIcon(wallet.type.name), color: color),
        ),
        title: Text(wallet.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(wallet.typeDisplayName),
        trailing: Text(
          CurrencyFormatter.formatWalletBalance(wallet),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: wallet.currentBalance >= 0 ? Colors.green : Colors.red,
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => WalletDetailScreen(walletId: wallet.id)),
        ),
      ),
    );
  }
}
