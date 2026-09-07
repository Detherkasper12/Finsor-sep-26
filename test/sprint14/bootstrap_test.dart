import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/wallet.dart';

void main() {
  late HiveDatabaseService db;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final path = '${DateTime.now().millisecondsSinceEpoch}_bootstrap_test';
    Hive.init(path);
    db = HiveDatabaseService.instance;
    await db.init();
  });

  tearDownAll(() async {
    await db.close();
  });

  group('Bootstrap Scenarios', () {
    test('local has data - can be detected', () async {
      // Default wallet is created during init
      final wallets = await db.getWallets();
      expect(wallets.isNotEmpty, true);
    });

    test('local transactions empty after clearAllData', () async {
      // Store and verify transactions
      final txn = Transaction(
        id: 'boot_txn_1',
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'default_wallet',
        createdAt: DateTime.now(),
      );
      await db.addTransaction(txn);
      var txns = await db.getTransactions();
      expect(txns.any((t) => t.id == 'boot_txn_1'), true);

      await db.clearAllData();
      txns = await db.getTransactions();
      expect(txns.any((t) => t.id == 'boot_txn_1'), false);
    });

    test('local data snapshot can be serialized for push', () async {
      final wallet = Wallet(
        id: 'boot_w_1',
        name: 'Bootstrap Wallet',
        type: WalletType.cash,
        currency: 'USD',
        currentBalance: 500.0,
        createdAt: DateTime.now(),
      );
      await db.addWallet(wallet);

      final json = wallet.toJson();
      expect(json['id'], 'boot_w_1');
      expect(json['name'], 'Bootstrap Wallet');
      expect(json['currentBalance'], 500.0);

      final restored = Wallet.fromJson(json);
      expect(restored.id, wallet.id);
      expect(restored.currentBalance, wallet.currentBalance);
    });

    test('settings survive roundtrip serialization', () async {
      final settings = await db.getUserSettings();
      final json = settings.toJson();
      json['id'] = 'default';

      expect(json['startOfMonthDay'], settings.startOfMonthDay);
      expect(json['autoLockTimeout'], settings.autoLockTimeout);
      expect(json['themeMode'], settings.themeMode.name);
    });

    test('pending ops are cleared on clearAllData', () async {
      await db.addPendingOp({'opId': 'boot_op', 'entityType': 't', 'entityId': '1',
        'opType': 'upsert', 'payload': {}, 'createdAt': DateTime.now().toIso8601String()});
      expect(db.pendingOpsCount, greaterThan(0));

      await db.clearAllData();
      expect(db.pendingOpsCount, 0);
    });
  });
}
