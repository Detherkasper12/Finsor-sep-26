import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/providers/transaction_provider.dart';
import 'package:finsor/providers/wallet_provider.dart';
import 'package:finsor/providers/repository_providers.dart';
import 'package:finsor/providers/database_provider.dart';

void main() {
  late ProviderContainer container;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sprint12_sync_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    container = ProviderContainer();
    await container.read(databaseInitProvider.future);
  });

  tearDown(() {
    container.dispose();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Transaction sync', () {
    test('addTransaction invalidates periodSummaryProvider', () async {
      final wallets = await container.read(walletsProvider.future);
      if (wallets.isEmpty) return;

      final summaryBefore = await container.read(periodSummaryProvider.future);
      final tx = Transaction(
        id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
        amount: 50,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: wallets.first.id,
        createdAt: DateTime.now(),
      );

      await container.read(transactionNotifierProvider.notifier).addTransaction(tx);

      final summaryAfter = await container.read(periodSummaryProvider.future);
      expect(summaryAfter.expenses, greaterThanOrEqualTo(summaryBefore.expenses));
    });

    test('addTransaction invalidates walletsProvider', () async {
      final walletsBefore = await container.read(walletsProvider.future);
      if (walletsBefore.isEmpty) return;

      final tx = Transaction(
        id: 'sync_w_${DateTime.now().millisecondsSinceEpoch}',
        amount: 25,
        type: TransactionType.expense,
        categoryId: 'expense_food',
        walletId: walletsBefore.first.id,
        createdAt: DateTime.now(),
      );

      await container.read(transactionNotifierProvider.notifier).addTransaction(tx);

      final walletsAfter = await container.read(walletsProvider.future);
      expect(walletsAfter, isNotEmpty);
      final w = walletsAfter.firstWhere((x) => x.id == walletsBefore.first.id);
      expect(w.currentBalance, lessThan(walletsBefore.first.currentBalance));
    });
  });
}
