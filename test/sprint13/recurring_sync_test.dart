import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/services/recurring_service.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/recurring_transaction.dart';
import 'package:finsor/models/wallet.dart';

void main() {
  late HiveDatabaseService db;
  late RecurringService recurringService;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('recurring_sync_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    await Hive.deleteFromDisk();
    Hive.init(tempDir.path);
    db = HiveDatabaseService.instance;
    await db.init();
    recurringService = RecurringService(db);
  });

  tearDown(() async {
    await db.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Recurring transaction generation', () {
    late Wallet wallet;

    setUp(() async {
      wallet = Wallet(
        id: 'wallet_rec_test',
        name: 'RecTest',
        type: WalletType.cash,
        currency: 'USD',
        initialBalance: 1000.0,
        currentBalance: 1000.0,
        createdAt: DateTime.now(),
      );
      await db.addWallet(wallet);
    });

    test('generates daily recurring transactions idempotently', () async {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final rt = RecurringTransaction(
        id: 'rec_daily_1',
        amount: 10.0,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        walletId: wallet.id,
        frequency: RecurringFrequency.daily,
        interval: 1,
        startDate: threeDaysAgo,
        nextRunDate: threeDaysAgo,
        createdAt: DateTime.now(),
      );
      await db.addRecurringTransaction(rt);

      final generated = await recurringService.generateDueTransactions();
      expect(generated.length, greaterThanOrEqualTo(3));

      // Run again — idempotent, no new transactions
      final secondRun = await recurringService.generateDueTransactions();
      expect(secondRun.length, equals(0));
    });

    test('paused recurring does not generate', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final rt = RecurringTransaction(
        id: 'rec_paused_1',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        walletId: wallet.id,
        frequency: RecurringFrequency.daily,
        interval: 1,
        startDate: yesterday,
        nextRunDate: yesterday,
        isPaused: true,
        createdAt: DateTime.now(),
      );
      await db.addRecurringTransaction(rt);

      final generated = await recurringService.generateDueTransactions();
      expect(generated.length, equals(0));
    });

    test('generated transaction has recurringId link', () async {
      final today = DateTime.now();
      final startDate = DateTime(today.year, today.month, today.day);
      final rt = RecurringTransaction(
        id: 'rec_link_1',
        amount: 25.0,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        walletId: wallet.id,
        frequency: RecurringFrequency.daily,
        interval: 1,
        startDate: startDate,
        nextRunDate: startDate,
        createdAt: DateTime.now(),
      );
      await db.addRecurringTransaction(rt);

      final generated = await recurringService.generateDueTransactions();
      expect(generated.isNotEmpty, isTrue);
      expect(generated.first.recurringId, equals('rec_link_1'));
      expect(generated.first.isRecurring, isTrue);
    });

    test('recurring updates wallet balance through addTransaction', () async {
      final today = DateTime.now();
      final startDate = DateTime(today.year, today.month, today.day);
      final rt = RecurringTransaction(
        id: 'rec_balance_1',
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        walletId: wallet.id,
        frequency: RecurringFrequency.daily,
        interval: 1,
        startDate: startDate,
        nextRunDate: startDate,
        createdAt: DateTime.now(),
      );
      await db.addRecurringTransaction(rt);

      await recurringService.generateDueTransactions();
      final updatedWallet = await db.getWallet(wallet.id);
      expect(updatedWallet!.currentBalance, equals(900.0));
    });

    test('expired recurring does not generate past endDate', () async {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final rt = RecurringTransaction(
        id: 'rec_expired_1',
        amount: 10.0,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        walletId: wallet.id,
        frequency: RecurringFrequency.daily,
        interval: 1,
        startDate: twoDaysAgo,
        nextRunDate: twoDaysAgo,
        endDate: DateTime(yesterday.year, yesterday.month, yesterday.day),
        createdAt: DateTime.now(),
      );
      await db.addRecurringTransaction(rt);

      final generated = await recurringService.generateDueTransactions();
      // Should generate for twoDaysAgo and yesterday only (endDate is yesterday)
      expect(generated.length, lessThanOrEqualTo(2));
    });
  });
}
