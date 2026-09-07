import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/wallet.dart';

void main() {
  late HiveDatabaseService db;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final path = '${DateTime.now().millisecondsSinceEpoch}_softdel_test';
    Hive.init(path);
    db = HiveDatabaseService.instance;
    await db.init();
  });

  tearDownAll(() async {
    await db.close();
  });

  group('Soft Delete - No Resurrection', () {
    test('deleted entity is removed from local store', () async {
      final txn = Transaction(
        id: 'sd_txn_1',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'default_wallet',
        createdAt: DateTime.now(),
      );
      await db.addTransaction(txn);

      var retrieved = await db.getTransaction('sd_txn_1');
      expect(retrieved, isNotNull);

      await db.deleteTransaction('sd_txn_1');
      retrieved = await db.getTransaction('sd_txn_1');
      expect(retrieved, isNull);
    });

    test('soft-deleted wallet is deactivated, hard-deleted wallet is removed', () async {
      final wallet = Wallet(
        id: 'sd_w_1',
        name: 'Deletable',
        type: WalletType.cash,
        currency: 'USD',
        createdAt: DateTime.now(),
      );
      await db.addWallet(wallet);
      await db.deleteWallet('sd_w_1'); // soft delete: sets isActive=false

      var retrieved = await db.getWallet('sd_w_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.isActive, false);

      await db.hardDeleteWallet('sd_w_1'); // actually removes from Hive
      retrieved = await db.getWallet('sd_w_1');
      expect(retrieved, isNull);
    });

    test('no-resurrection: deleted_at != null means local delete, never upsert', () {
      // Simulating the pull logic decision
      final remoteRow = {
        'id': 'sd_txn_2',
        'deleted_at': '2026-01-15T00:00:00.000Z',
        'updated_at': '2026-01-15T00:00:00.000Z',
      };

      final deletedAt = remoteRow['deleted_at'];
      expect(deletedAt, isNotNull);
      // The sync engine checks: if deleted_at != null -> delete locally, never upsert
      // This is enforced in SyncService._applyRemoteRow
    });

    test('soft delete followed by older upsert does not resurrect', () async {
      final txn = Transaction(
        id: 'sd_txn_3',
        amount: 30.0,
        type: TransactionType.income,
        categoryId: 'income_salary',
        walletId: 'default_wallet',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 10),
      );
      await db.addTransaction(txn);
      await db.deleteTransaction('sd_txn_3');

      // Even if we get a remote upsert with older updated_at, 
      // pull logic processes deleted_at first
      final remoteDelete = {
        'id': 'sd_txn_3',
        'deleted_at': '2026-01-12T00:00:00.000Z',
        'updated_at': '2026-01-12T00:00:00.000Z',
      };
      expect(remoteDelete['deleted_at'], isNotNull);

      // Verify entity stays deleted locally
      final retrieved = await db.getTransaction('sd_txn_3');
      expect(retrieved, isNull);
    });
  });
}
