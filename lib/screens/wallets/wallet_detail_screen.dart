import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../models/wallet.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/category_icon_mapper.dart';
import '../../utils/category_colors.dart';
import '../../widgets/wallet_reassignment_dialog.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/enhanced_transaction_list.dart';
import 'add_edit_wallet_screen.dart';

class WalletDetailScreen extends ConsumerWidget {
  final String walletId;
  const WalletDetailScreen({super.key, required this.walletId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider(walletId));
    final txAsync = ref.watch(transactionsByWalletProvider(walletId));

    return walletAsync.when(
      data: (wallet) {
        if (wallet == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Wallet not found')),
          );
        }
        final color = CategoryColors.fromHex(wallet.color ?? '#4CAF50');

        return Scaffold(
          appBar: AppBar(
            title: Text(wallet.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddEditWalletScreen(wallet: wallet)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.archive_outlined, color: Colors.orange),
                onPressed: () => _handleDelete(context, ref, wallet),
                tooltip: 'Archive wallet',
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withAlpha(180)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(CategoryIcons.walletIcon(wallet.type.name),
                        color: Colors.white, size: 40),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(wallet.typeDisplayName,
                              style: const TextStyle(color: Colors.white70)),
                          const Gap(4),
                          Text(
                            CurrencyFormatter.formatWalletBalance(wallet),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Transactions',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ),
              const Gap(8),
              Expanded(
                child: txAsync.when(
                  data: (transactions) => transactions.isEmpty
                      ? const Center(child: Text('No transactions'))
                      : EnhancedTransactionList(
                          showHeader: false,
                          walletFilter: walletId,
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Wallet wallet) async {
    final wallets = await ref.read(walletsProvider.future);
    if (wallets.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot archive the last wallet')),
      );
      return;
    }

    final count = await ref.read(transactionCountByWalletProvider(wallet.id).future);
    if (count == 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Archive Wallet'),
          content: Text(
            'Archive "${wallet.name}"? It will be hidden from the main list but preserved.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Archive'),
            ),
          ],
        ),
      );
      if (ok == true) {
        await ref.read(walletNotifierProvider.notifier).deleteWallet(wallet.id);
        if (context.mounted) Navigator.pop(context);
      }
    } else {
      if (!context.mounted) return;
      final targetId = await showWalletReassignmentDialog(
        context: context,
        walletName: wallet.name,
        transactionCount: count,
        availableWallets: wallets.where((w) => w.id != wallet.id && w.isActive).toList(),
      );
      if (targetId != null && context.mounted) {
        await ref.read(walletNotifierProvider.notifier)
            .deleteWallet(wallet.id, reassignToId: targetId);
        if (context.mounted) Navigator.pop(context);
      }
    }
  }
}
