import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet.dart';
import 'database_provider.dart';
import 'repository_providers.dart';
import 'sync_provider.dart';
import 'transaction_provider.dart' hide recentTransactionsProvider;

class WalletHasTransactionsException implements Exception {
  final String walletId;
  final int count;
  WalletHasTransactionsException(this.walletId, this.count);
}

final transactionCountByWalletProvider =
    FutureProvider.family<int, String>((ref, walletId) async {
  final db = ref.read(databaseServiceProvider);
  return await db.getTransactionCountByWallet(walletId);
});

/// Provider for all wallets
final walletsProvider = FutureProvider<List<Wallet>>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  final wallets = await databaseService.getWallets();

  // Sort by creation date
  wallets.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return wallets;
});

/// Provider for single wallet
final walletProvider = FutureProvider.family<Wallet?, String>((ref, id) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getWallet(id);
});

/// Provider for active wallets (included in total)
final activeWalletsProvider = FutureProvider<List<Wallet>>((ref) async {
  final wallets = await ref.read(walletsProvider.future);
  return wallets.where((wallet) => wallet.includeInTotal).toList();
});

/// Provider for total balance across all active wallets
final totalBalanceProvider = FutureProvider<double>((ref) async {
  final activeWallets = await ref.read(activeWalletsProvider.future);
  return activeWallets.fold<double>(
    0.0,
    (sum, wallet) => sum + wallet.currentBalance,
  );
});

/// Provider for wallet balances by currency
final balancesByCurrencyProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final activeWallets = await ref.read(activeWalletsProvider.future);
  final balances = <String, double>{};

  for (final wallet in activeWallets) {
    balances[wallet.currency] =
        (balances[wallet.currency] ?? 0.0) + wallet.currentBalance;
  }

  return balances;
});

/// Provider for default wallet
final defaultWalletProvider = FutureProvider<Wallet?>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  final settings = await databaseService.getUserSettings();

  if (settings.defaultWalletId.isNotEmpty) {
    return await databaseService.getWallet(settings.defaultWalletId);
  }

  // If no default wallet set, return first active wallet
  final wallets = await ref.read(walletsProvider.future);
  return wallets.isNotEmpty ? wallets.first : null;
});

/// Notifier for wallet operations
class WalletNotifier extends StateNotifier<AsyncValue<void>> {
  WalletNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  /// Add new wallet
  Future<void> addWallet(Wallet wallet) async {
    state = const AsyncValue.loading();
    try {
      final databaseService = ref.read(databaseServiceProvider);
      await databaseService.addWallet(wallet);
      enqueueSyncOp(ref,
          entityType: 'wallets',
          entityId: wallet.id,
          opType: 'upsert',
          payload: wallet.toJson());

      ref.invalidate(walletsProvider);
      ref.invalidate(activeWalletsProvider);
      ref.invalidate(totalBalanceProvider);
      ref.invalidate(balancesByCurrencyProvider);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update existing wallet
  Future<void> updateWallet(Wallet wallet) async {
    state = const AsyncValue.loading();
    try {
      final databaseService = ref.read(databaseServiceProvider);
      await databaseService.updateWallet(wallet);
      enqueueSyncOp(ref,
          entityType: 'wallets',
          entityId: wallet.id,
          opType: 'upsert',
          payload: wallet.toJson());

      ref.invalidate(walletsProvider);
      ref.invalidate(activeWalletsProvider);
      ref.invalidate(totalBalanceProvider);
      ref.invalidate(balancesByCurrencyProvider);
      ref.invalidate(walletProvider(wallet.id));

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete wallet. If transactions exist, pass reassignToId.
  Future<void> deleteWallet(String id, {String? reassignToId}) async {
    state = const AsyncValue.loading();
    try {
      final databaseService = ref.read(databaseServiceProvider);
      final count = await databaseService.getTransactionCountByWallet(id);
      if (count > 0) {
        if (reassignToId == null || reassignToId == id) {
          throw WalletHasTransactionsException(id, count);
        }
        await databaseService.reassignTransactionsToWallet(id, reassignToId);
        ref.invalidate(transactionsProvider);
        ref.invalidate(recentTransactionsProvider);
        ref.invalidate(periodSummaryProvider);
      }
      await databaseService.deleteWallet(id);
      enqueueSyncOp(ref,
          entityType: 'wallets',
          entityId: id,
          opType: 'delete',
          payload: {'id': id});
      ref.invalidate(walletsProvider);
      ref.invalidate(activeWalletsProvider);
      ref.invalidate(totalBalanceProvider);
      ref.invalidate(balancesByCurrencyProvider);
      ref.invalidate(walletProvider(id));
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update wallet balance
  Future<void> updateWalletBalance(String walletId, double newBalance) async {
    state = const AsyncValue.loading();
    try {
      final databaseService = ref.read(databaseServiceProvider);
      final wallet = await databaseService.getWallet(walletId);

      if (wallet != null) {
        final updatedWallet = wallet.copyWithNewBalance(newBalance);
        await databaseService.updateWallet(updatedWallet);
        enqueueSyncOp(ref,
            entityType: 'wallets',
            entityId: walletId,
            opType: 'upsert',
            payload: updatedWallet.toJson());

        ref.invalidate(walletsProvider);
        ref.invalidate(activeWalletsProvider);
        ref.invalidate(totalBalanceProvider);
        ref.invalidate(balancesByCurrencyProvider);
        ref.invalidate(walletProvider(walletId));
      }

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for wallet operations
final walletNotifierProvider =
    StateNotifierProvider<WalletNotifier, AsyncValue<void>>((ref) {
  return WalletNotifier(ref);
});
