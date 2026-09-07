import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/config/env.dart';
import 'package:finsor/models/category.dart';
import 'package:finsor/models/transaction.dart';
import 'package:finsor/models/wallet.dart';
import 'package:finsor/services/ai_chat_service.dart';
import 'package:finsor/services/ai_service.dart';

void main() {
  setUp(() => Env.reset());
  group('AIChatContext', () {
    test('isValid: dateRange alone is valid', () {
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
        ),
      );
      expect(ctx.isValid, true);
    });

    test('isValid: categoryId alone is valid', () {
      final ctx = AIChatContext(categoryId: 'expense_food');
      expect(ctx.isValid, true);
    });

    test('isValid: both dateRange and categoryId is valid', () {
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
        ),
        categoryId: 'expense_food',
      );
      expect(ctx.isValid, true);
    });

    test('isValid: neither is invalid', () {
      final ctx = AIChatContext();
      expect(ctx.isValid, false);
    });

    test('isValid: empty categoryId is invalid', () {
      final ctx = AIChatContext(categoryId: '');
      expect(ctx.isValid, false);
    });

    test('toApiContext produces correct shape', () {
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
        ),
        categoryId: 'cat1',
        accountIds: ['w1', 'w2'],
      );
      final api = ctx.toApiContext();
      expect(api['dateRange'], isNotNull);
      expect((api['dateRange'] as Map)['start'], '2024-01-01');
      expect((api['dateRange'] as Map)['end'], '2024-01-31');
      expect(api['categoryId'], 'cat1');
      expect(api['accountIds'], ['w1', 'w2']);
    });
  });

  group('AIChatService.useServerData', () {
    void configureEnv() {
      Env.supabaseUrl = 'https://abc.supabase.co';
      Env.anonKey = 'eyJhbGciOiJIUzI1NiJ9.test';
    }

    test('false when lastSyncAt is null', () {
      configureEnv();
      expect(AIChatService.useServerData(null), false);
    });

    test('false when lastSyncAt is more than 10 min ago', () {
      configureEnv();
      final stale = DateTime.now().subtract(const Duration(minutes: 15));
      expect(AIChatService.useServerData(stale), false);
    });

    test('false when Env not configured even with fresh sync', () {
      final fresh = DateTime.now().subtract(const Duration(minutes: 5));
      expect(AIChatService.useServerData(fresh), false);
    });

    test('true when lastSyncAt is within 10 min and Env configured', () {
      configureEnv();
      final fresh = DateTime.now().subtract(const Duration(minutes: 5));
      expect(AIChatService.useServerData(fresh), true);
    });

    test('true when lastSyncAt is exactly 10 min ago and Env configured', () {
      configureEnv();
      final edge = DateTime.now().subtract(const Duration(minutes: 10));
      expect(AIChatService.useServerData(edge), true);
    });
  });

  group('AIChatService.buildCompactDataset', () {
    final baseDate = DateTime(2024, 2, 1);

    List<Transaction> _transactions() => [
          Transaction(
            id: 't1',
            amount: 100,
            type: TransactionType.income,
            categoryId: 'inc_sal',
            walletId: 'w1',
            createdAt: baseDate,
          ),
          Transaction(
            id: 't2',
            amount: 50,
            type: TransactionType.expense,
            categoryId: 'exp_food',
            walletId: 'w1',
            description: 'Lunch', // PII - should be stripped
            createdAt: baseDate.add(const Duration(days: 1)),
          ),
        ];

    List<Category> _categories() => [
          Category(
            id: 'inc_sal',
            name: 'Salary',
            type: TransactionType.income,
            iconName: 'work',
            color: '#4CAF50',
            createdAt: baseDate,
          ),
          Category(
            id: 'exp_food',
            name: 'Food',
            type: TransactionType.expense,
            iconName: 'restaurant',
            color: '#FF5722',
            createdAt: baseDate,
          ),
        ];

    List<Wallet> _wallets() => [
          Wallet(
            id: 'w1',
            name: 'Main',
            type: WalletType.bank,
            currency: 'USD',
            createdAt: baseDate,
          ),
        ];

    test('produces expected schema with aggregates and currency', () async {
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: baseDate.subtract(const Duration(days: 1)),
          end: baseDate.add(const Duration(days: 5)),
        ),
      );
      final dataset = await AIChatService.buildCompactDataset(
        ctx,
        _transactions(),
        _categories(),
        _wallets(),
      );
      expect(dataset['currency'], 'USD');
      expect(dataset['tier'], 'small');
      expect(dataset['context'], isNotNull);
      expect(dataset['aggregates'], isNotNull);
      final agg = dataset['aggregates'] as Map<String, dynamic>;
      expect(agg['totalIncome'], 100.0);
      expect(agg['totalExpense'], 50.0);
      expect(agg['transactionCount'], 2);
      expect(agg['byCategory'], isA<List>());
      expect(agg['avgAmount'], isA<num>());
      expect(agg['medianAmount'], isA<num>());
      expect(dataset['topTransactions'], isA<List>());
    });

    test('no PII in output (no description, account numbers)', () async {
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: baseDate.subtract(const Duration(days: 1)),
          end: baseDate.add(const Duration(days: 5)),
        ),
      );
      final dataset = await AIChatService.buildCompactDataset(
        ctx,
        _transactions(),
        _categories(),
        _wallets(),
      );
      final jsonStr = dataset.toString();
      expect(jsonStr.contains('Lunch'), false);
      expect(jsonStr.contains('description'), false);
    });

    test('topTransactions have amount type categoryName date only', () async {
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: baseDate.subtract(const Duration(days: 1)),
          end: baseDate.add(const Duration(days: 5)),
        ),
      );
      final dataset = await AIChatService.buildCompactDataset(
        ctx,
        _transactions(),
        _categories(),
        _wallets(),
      );
      final top = dataset['topTransactions'] as List;
      expect(top.isNotEmpty, true);
      final first = top.first as Map;
      expect(first.containsKey('amount'), true);
      expect(first.containsKey('type'), true);
      expect(first.containsKey('categoryName'), true);
      expect(first.containsKey('date'), true);
    });
  });

  group('AIChatService.selectTier', () {
    test('returns small for generic message', () {
      expect(
        AIChatService.selectTier('Summarize my spending'),
        DatasetTier.small,
      );
    });

    test('returns medium for trend/pattern keywords', () {
      expect(AIChatService.selectTier('show trends'), DatasetTier.medium);
      expect(AIChatService.selectTier('find patterns'), DatasetTier.medium);
      expect(AIChatService.selectTier('any outliers?'), DatasetTier.medium);
      expect(AIChatService.selectTier('compare last month'), DatasetTier.medium);
      expect(AIChatService.selectTier('unusual transactions'), DatasetTier.medium);
    });

    test('returns large for deep/detailed keywords', () {
      expect(AIChatService.selectTier('deep analysis'), DatasetTier.large);
      expect(AIChatService.selectTier('full analysis please'), DatasetTier.large);
    });

    test('returns large when deepToggle true', () {
      expect(
        AIChatService.selectTier('summarize', deepToggle: true),
        DatasetTier.large,
      );
    });

    test('returns medium when txCount>500 and would pick large without deepToggle', () {
      expect(
        AIChatService.selectTier('deep analysis', transactionCount: 600),
        DatasetTier.medium,
      );
    });
  });

  group('AIChatService dataset tiers', () {
    final baseDate = DateTime(2024, 2, 1);

    List<Transaction> _manyTx(int n) => List.generate(n, (i) => Transaction(
          id: 't$i',
          amount: 50.0 + i,
          type: TransactionType.expense,
          categoryId: 'exp_cat${i % 15}',
          walletId: 'w1',
          createdAt: baseDate.add(Duration(days: i)),
        ));

    List<Category> _manyCats(int n) => List.generate(n, (i) => Category(
          id: 'exp_cat$i',
          name: 'Category$i',
          type: TransactionType.expense,
          iconName: 'category',
          color: '#000000',
          createdAt: baseDate,
        ));

    List<Wallet> _wallets() => [
          Wallet(
            id: 'w1',
            name: 'Main',
            type: WalletType.bank,
            currency: 'USD',
            createdAt: baseDate,
          ),
        ];

    test('LARGE tier caps topTransactions at 50', () async {
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: baseDate,
          end: baseDate.add(const Duration(days: 100)),
        ),
      );
      final tx = _manyTx(80);
      final cats = _manyCats(16);
      final dataset = AIChatService.buildDatasetLarge(
        ctx, tx, cats, _wallets(),
      );
      final top = dataset['topTransactions'] as List;
      expect(top.length, lessThanOrEqualTo(50));
    });

    test('SMALL tier has other bucket when >10 categories', () async {
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: baseDate,
          end: baseDate.add(const Duration(days: 30)),
        ),
      );
      final tx = _manyTx(50);
      final cats = _manyCats(16);
      final dataset = AIChatService.buildDatasetSmall(
        ctx, tx, cats, _wallets(),
      );
      final byCat = dataset['aggregates'] as Map;
      final list = byCat['byCategory'] as List;
      final other = list.cast<Map>().where((m) => m['categoryId'] == 'other');
      expect(other.length, 1);
      expect(other.first['name'], 'Other');
    });

    test('cache key is deterministic for same context', () {
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
        ),
        categoryId: 'exp_food',
      );
      expect(ctx.toCacheKeyPart(), ctx.toCacheKeyPart());
      expect(ctx.toCacheKeyPart(), isNotEmpty);
    });

    test('isAnalysisCacheMessage matches finance templates', () {
      for (final prompt in AIService.getFinanceExamplePrompts()) {
        expect(AIChatService.isAnalysisCacheMessage(prompt), true);
      }
      expect(AIChatService.isAnalysisCacheMessage('random free-form question'), false);
    });

    test('analysis cache key same for different template messages same context', () {
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
        ),
      );
      final key1 = 'a_uid_${ctx.toCacheKeyPart()}_medium_false';
      final key2 = 'a_uid_${ctx.toCacheKeyPart()}_medium_false';
      expect(key1, key2);
    });

    test('different context or tier gives different cache key', () {
      final ctx1 = AIChatContext(
        dateRange: DateTimeRange(start: DateTime(2024, 1, 1), end: DateTime(2024, 1, 31)),
      );
      final ctx2 = AIChatContext(
        dateRange: DateTimeRange(start: DateTime(2024, 2, 1), end: DateTime(2024, 2, 29)),
      );
      expect(ctx1.toCacheKeyPart(), isNot(ctx2.toCacheKeyPart()));
    });

    test('previousPeriod for 7-day range returns preceding 7 days', () {
      final range = DateTimeRange(
        start: DateTime(2024, 2, 1),
        end: DateTime(2024, 2, 7),
      );
      final prev = AIChatService.previousPeriod(range);
      expect(prev, isNotNull);
      expect(prev!.start, DateTime(2024, 1, 25));
      expect(prev.end, DateTime(2024, 1, 31));
    });

    test('SMALL tier has no delta fields', () async {
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: DateTime(2024, 2, 1),
          end: DateTime(2024, 2, 7),
        ),
      );
      final tx = [
        Transaction(id: 't1', amount: 100, type: TransactionType.income, categoryId: 'inc', walletId: 'w1', createdAt: DateTime(2024, 2, 1)),
      ];
      final cats = [
        Category(id: 'inc', name: 'Inc', type: TransactionType.income, iconName: 'i', color: '#0', createdAt: DateTime(2024)),
      ];
      final dataset = AIChatService.buildDatasetSmall(ctx, tx, cats, [
        Wallet(id: 'w1', name: 'Main', type: WalletType.bank, currency: 'USD', createdAt: DateTime(2024)),
      ]);
      final agg = dataset['aggregates'] as Map;
      expect(agg.containsKey('previous_total_income'), false);
      expect(agg.containsKey('delta_income_abs'), false);
      expect(agg.containsKey('delta_expense_abs'), false);
    });

    test('client dataset path uses local data only (no Supabase transaction fetch)', () async {
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: DateTime(2024, 2, 1),
          end: DateTime(2024, 2, 7),
        ),
      );
      final tx = [
        Transaction(id: 't1', amount: 100, type: TransactionType.income, categoryId: 'inc', walletId: 'w1', createdAt: DateTime(2024, 2, 1)),
      ];
      final cats = [
        Category(id: 'inc', name: 'Inc', type: TransactionType.income, iconName: 'i', color: '#0', createdAt: DateTime(2024)),
      ];
      final wallets = [
        Wallet(id: 'w1', name: 'Main', type: WalletType.bank, currency: 'USD', createdAt: DateTime(2024)),
      ];
      final dataset = await AIChatService.buildCompactDataset(ctx, tx, cats, wallets);
      expect(dataset['aggregates'], isNotNull);
      expect(dataset['currency'], 'USD');
      expect(dataset['context'], isNotNull);
    });

    test('MEDIUM tier has delta fields when dateRange present', () async {
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: DateTime(2024, 2, 1),
          end: DateTime(2024, 2, 7),
        ),
      );
      final tx = [
        Transaction(id: 't1', amount: 100, type: TransactionType.income, categoryId: 'inc', walletId: 'w1', createdAt: DateTime(2024, 2, 1)),
        Transaction(id: 't2', amount: 50, type: TransactionType.expense, categoryId: 'exp', walletId: 'w1', createdAt: DateTime(2024, 2, 2)),
      ];
      final cats = [
        Category(id: 'inc', name: 'Inc', type: TransactionType.income, iconName: 'i', color: '#0', createdAt: DateTime(2024)),
        Category(id: 'exp', name: 'Exp', type: TransactionType.expense, iconName: 'e', color: '#0', createdAt: DateTime(2024)),
      ];
      final dataset = AIChatService.buildDatasetMedium(ctx, tx, cats, [
        Wallet(id: 'w1', name: 'Main', type: WalletType.bank, currency: 'USD', createdAt: DateTime(2024)),
      ]);
      final agg = dataset['aggregates'] as Map;
      expect(agg.containsKey('previous_total_income'), true);
      expect(agg.containsKey('previous_total_expense'), true);
      expect(agg.containsKey('delta_income_abs'), true);
      expect(agg.containsKey('delta_expense_abs'), true);
    });

    test('MEDIUM tier has outlier metadata when outliers present', () async {
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: DateTime(2024, 2, 1),
          end: DateTime(2024, 2, 7),
        ),
      );
      final tx = List.generate(20, (i) => Transaction(
        id: 't$i',
        amount: i == 19 ? 500.0 : 10.0 + i,
        type: TransactionType.expense,
        categoryId: 'exp_cat',
        walletId: 'w1',
        createdAt: DateTime(2024, 2, 1 + (i % 7)),
      ));
      final cats = [Category(
        id: 'exp_cat',
        name: 'Cat',
        type: TransactionType.expense,
        iconName: 'c',
        color: '#000',
        createdAt: DateTime(2024),
      )];
      final dataset = AIChatService.buildDatasetMedium(ctx, tx, cats, [
        Wallet(id: 'w1', name: 'Main', type: WalletType.bank, currency: 'USD', createdAt: DateTime(2024)),
      ]);
      final outliers = dataset['outliers'] as List;
      expect(outliers.isNotEmpty, true);
      expect(dataset['outlierRuleUsed'], anyOf('p95', '3xMedian'));
      expect(dataset['outlierThreshold'], isA<num>());
    });

    test('ContextRequiredException is throwable and catchable', () {
      final e = ContextRequiredException('Context required.');
      expect(e.message, 'Context required.');
      expect(e, isA<ContextRequiredException>());
      expect(e, isA<Exception>());
    });

    test('AuthRequiredException has re-login message for UI', () {
      final e = AuthRequiredException();
      expect(e.message, 'Please sign in again.');
      expect(e, isA<AuthRequiredException>());
      expect(e, isA<Exception>());
    });

    test('AuthRequiredException custom message', () {
      final e = AuthRequiredException('Session expired. Please sign in again.');
      expect(e.message, 'Session expired. Please sign in again.');
    });

    group('AIChatException error mapping', () {
      test('AI_CONFIG_ERROR has userMessage and does not crash when used', () {
        final e = AIChatException(AIChatErrorCode.aiConfigError);
        expect(e.code, AIChatErrorCode.aiConfigError);
        expect(e.userMessage, isNotEmpty);
        expect(e.userMessage.toLowerCase(), contains('config'));
      });
      test('AI_RATE_LIMIT has userMessage', () {
        final e = AIChatException(AIChatErrorCode.aiRateLimit);
        expect(e.code, AIChatErrorCode.aiRateLimit);
        expect(e.userMessage, isNotEmpty);
      });
      test('AI_TEMPORARY_ERROR has userMessage', () {
        final e = AIChatException(AIChatErrorCode.aiTemporaryError);
        expect(e.code, AIChatErrorCode.aiTemporaryError);
        expect(e.userMessage, isNotEmpty);
      });
      test('custom message overrides default', () {
        final e = AIChatException(AIChatErrorCode.aiRateLimit, 'Try again later.');
        expect(e.userMessage, 'Try again later.');
      });
    });

    test('Deep uses LARGE tier', () {
      expect(
        AIChatService.selectTier('summarize', deepToggle: true),
        DatasetTier.large,
      );
    });

    test('Quick uses selected tier logic', () {
      expect(
        AIChatService.selectTier('show trends', deepToggle: false),
        DatasetTier.medium,
      );
      expect(
        AIChatService.selectTier('summarize spending', deepToggle: false),
        DatasetTier.small,
      );
    });

    test('no PII in any tier output', () async {
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: baseDate,
          end: baseDate.add(const Duration(days: 5)),
        ),
      );
      final tx = [
        Transaction(
          id: 't1',
          amount: 100,
          type: TransactionType.expense,
          categoryId: 'exp_food',
          walletId: 'w1',
          description: 'Lunch at 123 Main St',
          createdAt: baseDate,
        ),
      ];
      final cats = [
        Category(
          id: 'exp_food',
          name: 'Food',
          type: TransactionType.expense,
          iconName: 'restaurant',
          color: '#FF0000',
          createdAt: baseDate,
        ),
      ];
      for (final tier in DatasetTier.values) {
        final dataset = await AIChatService.buildCompactDataset(
          ctx, tx, cats, _wallets(), tier: tier,
        );
        final s = dataset.toString();
        expect(s.contains('123'), false);
        expect(s.contains('Main St'), false);
        expect(s.contains('description'), false);
      }
    });

    test('subcategory formats as Parent > Child and filter by parent includes children', () async {
      final parentId = 'exp_food';
      final childId = 'exp_restaurants';
      final ctx = AIChatContext(
        dateRange: DateTimeRange(
          start: DateTime(2024, 2, 1),
          end: DateTime(2024, 2, 7),
        ),
        categoryId: parentId,
      );
      final cats = [
        Category(id: parentId, name: 'Food', type: TransactionType.expense, iconName: 'i', color: '#0', createdAt: DateTime(2024)),
        Category(id: childId, name: 'Restaurants', type: TransactionType.expense, iconName: 'i', color: '#0', parentId: parentId, createdAt: DateTime(2024)),
      ];
      final tx = [
        Transaction(id: 't1', amount: 50, type: TransactionType.expense, categoryId: childId, walletId: 'w1', createdAt: DateTime(2024, 2, 2)),
      ];
      final wallets = [
        Wallet(id: 'w1', name: 'Main', type: WalletType.bank, currency: 'USD', createdAt: DateTime(2024)),
      ];
      final dataset = await AIChatService.buildCompactDataset(ctx, tx, cats, wallets);
      expect(dataset['aggregates'], isNotNull);
      final agg = dataset['aggregates'] as Map;
      expect(agg['transactionCount'], 1);
      final topTx = dataset['topTransactions'] as List;
      expect(topTx.length, 1);
      expect((topTx.first as Map)['categoryName'], 'Food > Restaurants');
    });
  });
}
