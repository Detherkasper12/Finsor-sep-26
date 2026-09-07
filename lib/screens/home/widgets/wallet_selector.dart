import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../models/wallet.dart';
import '../../../utils/currency_formatter.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/animated_wallet_card.dart';
import '../../../utils/page_transitions.dart';
import '../../../models/user_settings.dart';
import '../../../constants/app_theme.dart';

/// Wallet selector widget with horizontal scrolling
class WalletSelector extends ConsumerWidget {
  final List<Wallet> wallets;
  final String? selectedWalletId;
  final ValueChanged<String?> onWalletSelected;

  const WalletSelector({
    super.key,
    required this.wallets,
    required this.selectedWalletId,
    required this.onWalletSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currency = settings.when(
      data: (userSettings) => userSettings.primaryCurrency,
      loading: () => DefaultCurrencies.popular.first,
      error: (_, __) => DefaultCurrencies.popular.first,
    );
    
    return SizedBox(
      height: 120, // Reduced height since no header
      child: SizedBox(
        height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
            itemCount: wallets.length + 1, // +1 for "All Wallets"
                          itemBuilder: (context, index) {
                if (index == 0) {
                  // "All Wallets" option
                  return AnimatedListItem(
                    index: index,
                    child: AllWalletsCard(
                      totalBalance: wallets.fold(0.0, (sum, w) => sum + w.currentBalance),
                      currency: currency,
                      isSelected: selectedWalletId == null,
                      onTap: () => onWalletSelected(null),
                    ),
                  );
                }

                final wallet = wallets[index - 1];
                return AnimatedListItem(
                  index: index,
                  child: AnimatedWalletCard(
                    wallet: wallet,
                    currency: currency,
                    isSelected: selectedWalletId == wallet.id,
                    onTap: () => onWalletSelected(wallet.id),
                    onLongPress: () => _showWalletOptions(context, wallet),
                  ),
                );
              },
          ),
        ),
    );
  }

  void _showWalletOptions(BuildContext context, Wallet wallet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(16),
            Text(
              wallet.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(24),
            ListTile(
              leading: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
              title: const Text('Edit Wallet'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit wallet screen
              },
            ),
            ListTile(
              leading: Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary),
              title: const Text('View Transactions'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to wallet transactions
              },
            ),
            if (!wallet.isDefault)
              ListTile(
                leading: Icon(Icons.star, color: Theme.of(context).colorScheme.secondary),
                title: const Text('Set as Default'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Set as default wallet
                },
              ),
            const Gap(16),
          ],
        ),
      ),
    );
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
