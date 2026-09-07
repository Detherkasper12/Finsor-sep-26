import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/services/insight_context_builder.dart';
import 'package:finsor/repositories/analytics_repository.dart';

void main() {
  group('InsightContextBuilder', () {
    late Directory tempDir;
    late HiveDatabaseService db;
    late AnalyticsRepository repo;
    late InsightContextBuilder builder;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('insight_context_test_');
      Hive.init(tempDir.path);
      db = HiveDatabaseService.instance;
      await db.init();
      repo = AnalyticsRepository(db);
      builder = InsightContextBuilder(repo);
    });

    tearDownAll(() async {
      await db.close();
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('builds context with aggregated data only', () async {
      final context = await builder.buildCurrentMonthContext();
      expect(context.periodStart, isNotEmpty);
      expect(context.periodEnd, isNotEmpty);
      expect(context.totalIncome, isNonNegative);
      expect(context.totalExpenses, isNonNegative);
      expect(context.transactionCount, isNonNegative);
    });

    test('context toJson produces valid structure', () async {
      final context = await builder.buildCurrentMonthContext();
      final json = context.toJson();
      expect(json, containsPair('periodStart', context.periodStart));
      expect(json, containsPair('totalIncome', context.totalIncome));
      expect(json['topCategories'], isA<List>());
    });

    test('no raw transactions in context', () async {
      final context = await builder.buildCurrentMonthContext();
      final json = context.toJson();
      expect(json.containsKey('transactions'), isFalse);
      expect(json.containsKey('rawTransactions'), isFalse);
    });
  });
}
