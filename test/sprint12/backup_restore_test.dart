import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/wallet.dart';

void main() {
  late HiveDatabaseService db;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sprint12_bak_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    await Hive.deleteFromDisk();
    Hive.init(tempDir.path);
    db = HiveDatabaseService.instance;
    await db.init();
  });

  tearDown(() async {
    await db.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Backup/Restore integrity', () {
    test('exportData returns all required keys', () async {
      final exportData = await db.exportData();

      expect(exportData.containsKey('transactions'), isTrue);
      expect(exportData.containsKey('wallets'), isTrue);
      expect(exportData.containsKey('categories'), isTrue);
      expect(exportData.containsKey('budgets'), isTrue);
      expect(exportData.containsKey('settings'), isTrue);
      expect(exportData.containsKey('export_date'), isTrue);
      expect(exportData.containsKey('app_version'), isTrue);
    });

    test('importData restores transactions correctly', () async {
      await db.addTransaction(Transaction(
        id: 'backup_tx_1',
        amount: 100,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: 'wallet_default',
        description: 'Test backup',
        createdAt: DateTime.now(),
      ));

      final exportData = await db.exportData();
      await db.clearAllData();

      final txBefore = await db.getTransactions();
      expect(txBefore.any((t) => t.id == 'backup_tx_1'), isFalse);

      await db.importData(exportData);

      final txAfter = await db.getTransactions();
      final restored = txAfter.where((t) => t.id == 'backup_tx_1').toList();
      expect(restored.length, equals(1));
      expect(restored.first.amount, equals(100));
      expect(restored.first.description, equals('Test backup'));
    });

    test('importData restores wallets and categories', () async {
      final wallet = Wallet(
        id: 'custom_wallet',
        name: 'Custom',
        type: WalletType.savings,
        currency: 'USD',
        currentBalance: 500,
        createdAt: DateTime.now(),
      );
      await db.addWallet(wallet);

      final exportData = await db.exportData();
      await db.clearAllData();

      await db.importData(exportData);

      final restoredWallet = await db.getWallet('custom_wallet');
      expect(restoredWallet, isNotNull);
      expect(restoredWallet!.name, equals('Custom'));
      expect(restoredWallet.currentBalance, equals(500));

      final categories = await db.getCategories();
      expect(categories.isNotEmpty, isTrue);
    });

    test('export then import preserves data integrity', () async {
      await db.addTransaction(Transaction(
        id: 'int_tx_a',
        amount: 25.5,
        type: TransactionType.income,
        categoryId: 'income_salary',
        walletId: 'wallet_default',
        createdAt: DateTime.now(),
      ));
      await db.addTransaction(Transaction(
        id: 'int_tx_b',
        amount: 33.33,
        type: TransactionType.expense,
        categoryId: 'expense_transport',
        walletId: 'wallet_default',
        createdAt: DateTime.now(),
      ));

      final export = await db.exportData();
      await db.clearAllData();
      await db.importData(export);

      final transactions = await db.getTransactions();
      final listA = transactions.where((t) => t.id == 'int_tx_a').toList();
      final listB = transactions.where((t) => t.id == 'int_tx_b').toList();
      final a = listA.isNotEmpty ? listA.first : null;
      final b = listB.isNotEmpty ? listB.first : null;

      expect(a, isNotNull);
      expect(b, isNotNull);
      expect(a!.amount, equals(25.5));
      expect(a.type, equals(TransactionType.income));
      expect(b!.amount, equals(33.33));
      expect(b.type, equals(TransactionType.expense));
    });
  });
}
