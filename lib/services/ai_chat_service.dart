import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import '../utils/safe_json_parse.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/category.dart';
import 'ai_service.dart';

/// Thrown when the user must sign in again (no session, expired token, or 401 after refresh).
class AuthRequiredException implements Exception {
  final String message;
  AuthRequiredException([this.message = 'Please sign in again.']);
}

enum DatasetTier { small, medium, large }

class ContextRequiredException implements Exception {
  final String? message;
  ContextRequiredException([this.message]);
}

enum AIChatErrorCode { aiConfigError, aiRateLimit, aiTemporaryError }

class AIChatException implements Exception {
  final AIChatErrorCode code;
  final String message;
  AIChatException(this.code, [this.message = '']);
  static String _defaultMessage(AIChatErrorCode c) {
    switch (c) {
      case AIChatErrorCode.aiConfigError: return 'AI is not configured. Contact support.';
      case AIChatErrorCode.aiRateLimit: return 'Too many requests. Try again in a moment.';
      case AIChatErrorCode.aiTemporaryError: return 'Temporary error. Please try again.';
    }
  }
  String get userMessage => message.isNotEmpty ? message : _defaultMessage(code);
}

const int _maxTransactionsCap = 50;
const int _largeTierTransactionThreshold = 500;

class AIChatContext {
  final DateTimeRange? dateRange;
  final String? categoryId;
  final List<String>? accountIds;

  const AIChatContext({
    this.dateRange,
    this.categoryId,
    this.accountIds,
  });

  bool get isValid =>
      dateRange != null ||
      (categoryId != null && categoryId!.trim().isNotEmpty);

  Map<String, dynamic> toApiContext() {
    return {
      if (dateRange != null)
        'dateRange': {
          'start': dateRange!.start.toIso8601String().split('T').first,
          'end': dateRange!.end.toIso8601String().split('T').first,
        },
      if (categoryId != null && categoryId!.trim().isNotEmpty)
        'categoryId': categoryId,
      if (accountIds != null && accountIds!.isNotEmpty) 'accountIds': accountIds,
    };
  }

  String toCacheKeyPart() {
    final parts = <String>[];
    if (dateRange != null) {
      parts.add('${dateRange!.start.toIso8601String()}|${dateRange!.end.toIso8601String()}');
    }
    if (categoryId != null) parts.add(categoryId!);
    if (accountIds != null) parts.add(accountIds!.join(','));
    return parts.join('|');
  }
}

class AIChatService {
  static const Duration _cacheTtl = Duration(minutes: 15);

  static final Map<String, _CacheEntry> _responseCache = {};

  static bool useServerData(DateTime? lastSyncedAt) =>
      Env.isConfigured &&
      lastSyncedAt != null &&
      DateTime.now().difference(lastSyncedAt) <= const Duration(minutes: 10);

  static DatasetTier selectTier(
    String message, {
    bool deepToggle = false,
    int transactionCount = 0,
  }) {
    final lower = message.toLowerCase().trim();
    if (deepToggle) {
      if (transactionCount > _largeTierTransactionThreshold) return DatasetTier.large;
      return DatasetTier.large;
    }
    if (RegExp(r'\b(deep|detailed|full analysis)\b').hasMatch(lower)) {
      if (transactionCount > _largeTierTransactionThreshold && !deepToggle) {
        return DatasetTier.medium;
      }
      return DatasetTier.large;
    }
    const mediumKeywords = ['compare', 'why', 'trend', 'pattern', 'unusual', 'outlier', 'anomaly'];
    if (mediumKeywords.any((k) => lower.contains(k))) {
      return DatasetTier.medium;
    }
    return DatasetTier.small;
  }

  static String _normalizeMerchant(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'General';
    final s = raw
        .replaceAll(RegExp(r'[0-9]'), '')
        .replaceAll(RegExp(r'[^\w\s-]'), ' ')
        .trim();
    if (s.isEmpty) return 'General';
    return s.length > 32 ? '${s.substring(0, 32)}' : s;
  }

  static int getFilteredCount(
    AIChatContext context,
    List<Transaction> transactions,
    List<Category> categories,
  ) =>
      _filterTransactions(context, transactions, categories).length;

  /// Computes previous period for MEDIUM/LARGE tiers. Exposed for tests.
  static DateTimeRange? previousPeriod(DateTimeRange range) {
    final start = range.start;
    final end = range.end;
    final days = end.difference(start).inDays + 1;
    if (days <= 10) {
      return DateTimeRange(
        start: start.subtract(Duration(days: days)),
        end: start.subtract(const Duration(days: 1)),
      );
    }
    final isCalendarMonth = start.day == 1 &&
        end.day >= 28 &&
        end.month == start.month &&
        end.year == start.year;
    if (isCalendarMonth) {
      final prevMonth = DateTime(start.year, start.month - 1, 1);
      final prevMonthEnd = DateTime(start.year, start.month - 1 + 1, 0);
      return DateTimeRange(start: prevMonth, end: prevMonthEnd);
    }
    return DateTimeRange(
      start: start.subtract(Duration(days: days)),
      end: start.subtract(const Duration(days: 1)),
    );
  }

  static List<Transaction> _filterTransactions(
    AIChatContext context,
    List<Transaction> transactions,
    List<Category> categories,
  ) {
    List<Transaction> filtered = transactions;
    if (context.dateRange != null) {
      final start = context.dateRange!.start;
      final end = context.dateRange!.end;
      filtered = filtered.where((t) {
        final d = t.createdAt;
        return (d.isAfter(start.subtract(const Duration(days: 1))) ||
                d.isAtSameMomentAs(start)) &&
            (d.isBefore(end.add(const Duration(days: 1))) ||
                d.isAtSameMomentAs(end));
      }).toList();
    }
    if (context.categoryId != null && context.categoryId!.trim().isNotEmpty) {
      final parentId = context.categoryId!;
      final childIds = categories
          .where((c) => c.parentId == parentId)
          .map((c) => c.id)
          .toSet();
      final allowedIds = {parentId, ...childIds};
      filtered =
          filtered.where((t) => allowedIds.contains(t.categoryId)).toList();
    }
    if (context.accountIds != null && context.accountIds!.isNotEmpty) {
      final ids = context.accountIds!.toSet();
      filtered =
          filtered.where((t) => ids.contains(t.walletId)).toList();
    }
    return filtered;
  }

  static Map<String, String> _buildCategoryDisplayMap(List<Category> categories) {
    final idToCat = {for (final c in categories) c.id: c};
    return {
      for (final c in categories)
        c.id: c.parentId != null
            ? '${idToCat[c.parentId]?.name ?? 'Unknown'} > ${c.name}'
            : c.name,
    };
  }

  static Map<String, dynamic> buildDatasetSmall(
    AIChatContext context,
    List<Transaction> transactions,
    List<Category> categories,
    List<Wallet> wallets,
  ) {
    final filtered = _filterTransactions(context, transactions, categories);
    final catMap = _buildCategoryDisplayMap(categories);
    return _buildSmall(filtered, context, catMap);
  }

  static Map<String, dynamic> buildDatasetMedium(
    AIChatContext context,
    List<Transaction> transactions,
    List<Category> categories,
    List<Wallet> wallets,
  ) {
    final filtered = _filterTransactions(context, transactions, categories);
    final catMap = _buildCategoryDisplayMap(categories);
    final small = _buildSmall(filtered, context, catMap);
    List<Transaction>? prevFiltered;
    if (context.dateRange != null) {
      final prev = previousPeriod(context.dateRange!);
      prevFiltered = _filterTransactions(
        AIChatContext(
          dateRange: prev,
          categoryId: context.categoryId,
          accountIds: context.accountIds,
        ),
        transactions,
        categories,
      );
    }
    return _buildMedium(small, filtered, catMap, context, prevFiltered);
  }

  static Map<String, dynamic> buildDatasetLarge(
    AIChatContext context,
    List<Transaction> transactions,
    List<Category> categories,
    List<Wallet> wallets,
  ) {
    final filtered = _filterTransactions(context, transactions, categories);
    final catMap = _buildCategoryDisplayMap(categories);
    final small = _buildSmall(filtered, context, catMap);
    List<Transaction>? prevFiltered;
    if (context.dateRange != null) {
      final prev = previousPeriod(context.dateRange!);
      prevFiltered = _filterTransactions(
        AIChatContext(
          dateRange: prev,
          categoryId: context.categoryId,
          accountIds: context.accountIds,
        ),
        transactions,
        categories,
      );
    }
    final medium = _buildMedium(small, filtered, catMap, context, prevFiltered);
    return _buildLarge(medium, filtered, catMap, context);
  }

  static Future<Map<String, dynamic>> buildCompactDataset(
    AIChatContext context,
    List<Transaction> transactions,
    List<Category> categories,
    List<Wallet> wallets, {
    DatasetTier tier = DatasetTier.small,
  }) async {
    switch (tier) {
      case DatasetTier.small:
        return buildDatasetSmall(context, transactions, categories, wallets);
      case DatasetTier.medium:
        return buildDatasetMedium(context, transactions, categories, wallets);
      case DatasetTier.large:
        return buildDatasetLarge(context, transactions, categories, wallets);
    }
  }

  static Map<String, dynamic> _buildSmall(
    List<Transaction> filtered,
    AIChatContext context,
    Map<String, String> catMap,
  ) {
    final income = filtered.where((t) => t.type == TransactionType.income);
    final expense = filtered.where((t) => t.type == TransactionType.expense);
    final totalIncome = income.fold<double>(0, (s, t) => s + t.amount);
    final totalExpense = expense.fold<double>(0, (s, t) => s + t.amount);
    final expenseAmounts = expense.map((t) => t.amount).toList();
    final amounts = filtered
        .where((t) => t.type != TransactionType.transfer)
        .map((t) => t.amount)
        .where((a) => a != 0)
        .toList();
    final sorted =
        List<double>.from(amounts)..sort((a, b) => b.abs().compareTo(a.abs()));
    final avg = amounts.isEmpty
        ? 0.0
        : amounts.reduce((a, b) => a + b) / amounts.length;
    final median = sorted.isEmpty
        ? 0.0
        : sorted.length % 2 == 1
            ? sorted[sorted.length ~/ 2]
            : (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2;
    final avgExpense = expenseAmounts.isEmpty
        ? 0.0
        : expenseAmounts.reduce((a, b) => a + b) / expenseAmounts.length;
    final medianExpense = expenseAmounts.isEmpty
        ? 0.0
        : () {
            final s = List<double>.from(expenseAmounts)..sort();
            return s.length % 2 == 1
                ? s[s.length ~/ 2]
                : (s[s.length ~/ 2 - 1] + s[s.length ~/ 2]) / 2;
          }();

    final byCategory = <String, Map<String, dynamic>>{};
    for (final t in filtered) {
      if (t.type == TransactionType.transfer) continue;
      final name = catMap[t.categoryId] ?? 'Unknown';
      final key = '${t.categoryId}|$name';
      final cur = byCategory[key] ??
          {'categoryId': t.categoryId, 'name': name, 'total': 0.0, 'count': 0};
      cur['total'] = (cur['total'] as num) + t.amount;
      cur['count'] = (cur['count'] as int) + 1;
      byCategory[key] = cur;
    }
    final catList = byCategory.values.toList()
      ..sort((a, b) => (b['total'] as num).abs().compareTo((a['total'] as num).abs()));
    final topCats = catList.take(10).map((v) => {
          'categoryId': v['categoryId'],
          'name': v['name'],
          'total': v['total'],
          'count': v['count'],
        }).toList();
    final otherTotal = catList.skip(10).fold<double>(
        0, (s, v) => s + (v['total'] as num));
    final otherCount = catList.skip(10).fold<int>(0, (s, v) => s + (v['count'] as int));
    if (otherTotal != 0 || otherCount != 0) {
      topCats.add({'categoryId': 'other', 'name': 'Other', 'total': otherTotal, 'count': otherCount});
    }

    final topTx = filtered
        .where((t) => t.type != TransactionType.transfer)
        .toList()
      ..sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
    final top10 = topTx.take(10).map((t) => {
          'amount': t.amount,
          'type': t.type.name,
          'currency': 'USD',
          'categoryName': catMap[t.categoryId] ?? 'Unknown',
          'merchant': _normalizeMerchant(catMap[t.categoryId]),
          'date': t.createdAt.toIso8601String().split('T').first,
        }).toList();

    return {
      'context': context.toApiContext(),
      'currency': 'USD',
      'tier': 'small',
      'aggregates': {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'transactionCount': filtered.length,
        'avgAmount': avg,
        'medianAmount': median,
        'avgExpense': avgExpense,
        'medianExpense': medianExpense,
        'byCategory': topCats,
      },
      'topTransactions': top10,
    };
  }

  static Map<String, dynamic> _buildMedium(
    Map<String, dynamic> small,
    List<Transaction> filtered,
    Map<String, String> catMap,
    AIChatContext context, [
    List<Transaction>? prevFiltered,
  ]) {
    final byDay = <String, Map<String, dynamic>>{};
    for (final t in filtered) {
      final d = t.createdAt.toIso8601String().split('T').first;
      final cur = byDay[d] ?? {'income': 0.0, 'expense': 0.0};
      if (t.type == TransactionType.income) {
        cur['income'] = (cur['income'] as num) + t.amount;
      } else if (t.type == TransactionType.expense) {
        cur['expense'] = (cur['expense'] as num) + t.amount;
      }
      byDay[d] = cur;
    }
    final byDayList = byDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final byDayAgg = byDayList
        .map((e) => {
              'date': e.key,
              'income': e.value['income'],
              'expense': e.value['expense'],
            })
        .toList();

    final merchantCounts = <String, int>{};
    for (final t in filtered) {
      if (t.type == TransactionType.transfer) continue;
      final m = _normalizeMerchant(catMap[t.categoryId]);
      merchantCounts[m] = (merchantCounts[m] ?? 0) + 1;
    }
    final topMerchants = merchantCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5Merchants = topMerchants.take(5).map((e) => {'name': e.key, 'count': e.value}).toList();

    final amounts = filtered
        .where((t) => t.type != TransactionType.transfer)
        .map((t) => t.amount.abs())
        .where((a) => a > 0)
        .toList();
    final median = amounts.isEmpty
        ? 0.0
        : () {
            final s = List<double>.from(amounts)..sort();
            return s.length % 2 == 1
                ? s[s.length ~/ 2]
                : (s[s.length ~/ 2 - 1] + s[s.length ~/ 2]) / 2;
          }();
    final p95Idx = (amounts.length * 0.95).floor();
    final p95 = amounts.isEmpty ? 0.0 : (List<double>.from(amounts)..sort())[math.min(p95Idx, amounts.length - 1)];
    final threshold3x = median * 3;
    final threshold = math.max(p95, threshold3x);
    final ruleUsed = p95 >= threshold3x ? 'p95' : '3xMedian';
    final outlierTx = filtered
        .where((t) =>
            t.type != TransactionType.transfer && t.amount.abs() >= threshold)
        .toList()
      ..sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
    final outliers = outlierTx.take(10).map((t) => {
          'amount': t.amount,
          'type': t.type.name,
          'categoryName': catMap[t.categoryId] ?? 'Unknown',
          'date': t.createdAt.toIso8601String().split('T').first,
        }).toList();

    Map<String, dynamic> prevDelta = {};
    if (prevFiltered != null) {
      final prevIncome = prevFiltered.where((t) => t.type == TransactionType.income).fold<double>(0, (s, t) => s + t.amount);
      final prevExpense = prevFiltered.where((t) => t.type == TransactionType.expense).fold<double>(0, (s, t) => s + t.amount);
      final agg = small['aggregates'] as Map<String, dynamic>;
      final currIncome = agg['totalIncome'] as num;
      final currExpense = agg['totalExpense'] as num;
      prevDelta = {
        'previous_total_income': prevIncome,
        'previous_total_expense': prevExpense,
        'delta_income_abs': (currIncome - prevIncome).toDouble(),
        'delta_income_pct': prevIncome != 0 ? ((currIncome - prevIncome) / prevIncome * 100) : 0.0,
        'delta_expense_abs': (currExpense - prevExpense).toDouble(),
        'delta_expense_pct': prevExpense != 0 ? ((currExpense - prevExpense) / prevExpense * 100) : 0.0,
      };
      final currByCat = <String, double>{};
      for (final e in (agg['byCategory'] as List?) ?? []) {
        final m = e as Map;
        final name = safeStringOr(m['name'], '');
        final total = safeDouble(m['total']) ?? 0.0;
        currByCat[name] = (currByCat[name] ?? 0) + total;
      }
      final prevByCat = <String, double>{};
      for (final t in prevFiltered) {
        if (t.type == TransactionType.transfer) continue;
        final name = catMap[t.categoryId] ?? 'Unknown';
        prevByCat[name] = (prevByCat[name] ?? 0) + t.amount;
      }
      final allCats = {...currByCat.keys, ...prevByCat.keys};
      final catDeltas = allCats.map((name) {
        final curr = currByCat[name] ?? 0.0;
        final prev = prevByCat[name] ?? 0.0;
        final delta = curr - prev;
        final pct = prev != 0 ? (delta / prev * 100) : 0.0;
        return {'category': name, 'delta_abs': delta, 'delta_pct': pct};
      }).toList()
        ..sort((a, b) => (b['delta_abs'] as num).abs().compareTo((a['delta_abs'] as num).abs()));
      prevDelta['top_category_deltas'] = catDeltas.take(5).toList();
    }

    final outlierMeta = outliers.isNotEmpty
        ? {'outlierRuleUsed': ruleUsed, 'outlierThreshold': threshold}
        : <String, dynamic>{};

    return {
      ...small,
      'tier': 'medium',
      'aggregates': {
        ...(small['aggregates'] as Map<String, dynamic>),
        'byDay': byDayAgg,
        ...prevDelta,
      },
      'topMerchants': top5Merchants,
      'outliers': outliers,
      ...outlierMeta,
    };
  }

  static Map<String, dynamic> _buildLarge(
    Map<String, dynamic> medium,
    List<Transaction> filtered,
    Map<String, String> catMap,
    AIChatContext context,
  ) {
    final topTx = filtered
        .where((t) => t.type != TransactionType.transfer)
        .toList()
      ..sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));
    final top50 = topTx
        .take(_maxTransactionsCap)
        .map((t) => {
              'amount': t.amount,
              'type': t.type.name,
              'currency': 'USD',
              'categoryName': catMap[t.categoryId] ?? 'Unknown',
              'merchant': _normalizeMerchant(catMap[t.categoryId]),
              'date': t.createdAt.toIso8601String().split('T').first,
            })
        .toList();
    medium['topTransactions'] = top50;

    final byCatDay = <String, double>{};
    for (final t in filtered) {
      if (t.type == TransactionType.transfer) continue;
      final cat = catMap[t.categoryId] ?? 'Unknown';
      final d = t.createdAt.toIso8601String().split('T').first;
      final key = '$cat|$d';
      byCatDay[key] = (byCatDay[key] ?? 0.0) + t.amount;
    }
    final matrix = <Map<String, dynamic>>[];
    final cats = <String>{};
    final days = <String>{};
    for (final k in byCatDay.keys) {
      final parts = k.split('|');
      if (parts.length >= 2) {
        cats.add(parts[0]);
        days.add(parts[1]);
      }
    }
    final dayList = days.toList()..sort();
    for (final cat in cats) {
      final row = <String, dynamic>{'category': cat};
      for (final d in dayList) {
        row[d] = byCatDay['$cat|$d'] ?? 0;
      }
      matrix.add(row);
    }

    return {
      ...medium,
      'tier': 'large',
      'categoryByDay': matrix,
    };
  }

  static String? _getCachedResponse(String key) {
    final entry = _responseCache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.at) > _cacheTtl) {
      _responseCache.remove(key);
      return null;
    }
    return entry.content;
  }

  static void _setCachedResponse(String key, String content) {
    _responseCache[key] = _CacheEntry(content: content, at: DateTime.now());
    if (_responseCache.length > 100) {
      final expired =
          _responseCache.entries.where((e) => DateTime.now().difference(e.value.at) > _cacheTtl).map((e) => e.key).toList();
      for (final k in expired) _responseCache.remove(k);
    }
  }

  static bool isAnalysisCacheMessage(String message) {
    final templates = AIService.getFinanceExamplePrompts();
    final normalized = message.toLowerCase().trim();
    return templates.any((t) =>
        normalized == t.toLowerCase().trim() ||
        normalized.contains(t.toLowerCase().trim()));
  }

  static void _logSessionDebug(String phase, Session? session) {
    if (!kDebugMode) return;
    if (session == null) {
      debugPrint('AIChat: [$phase] session=null');
      return;
    }
    final expiresAtSec = session.expiresAt;
    final expiresAtDt = expiresAtSec != null ? DateTime.fromMillisecondsSinceEpoch(expiresAtSec * 1000) : null;
    final secsUntil = expiresAtDt != null ? expiresAtDt.difference(DateTime.now()).inSeconds : null;
    debugPrint('AIChat: [$phase] session=exists expiresAt=${expiresAtDt?.toIso8601String()} secondsUntilExpiry=$secsUntil');
  }

  static Future<FunctionResponse> _invokeWithAuthRetry(
    SupabaseClient client,
    Map<String, dynamic> body,
  ) async {
    Session? session = client.auth.currentSession;
    if (session == null || session.accessToken.isEmpty) {
      _logSessionDebug('before_invoke', null);
      throw AuthRequiredException('Please sign in again.');
    }
    _logSessionDebug('before_invoke', session);
    if (kDebugMode) debugPrint('AIChat: request via supabase.functions.invoke(ai-chat)');

    FunctionResponse response;
    try {
      response = await client.functions.invoke(
        'ai-chat',
        body: body,
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
    } on FunctionException catch (e) {
      if (e.status != 401) {
        throw AIChatException(AIChatErrorCode.aiTemporaryError, e.reasonPhrase ?? 'Request failed.');
      }
      if (kDebugMode) debugPrint('AIChat: 401 on invoke, refreshSession + retry once');
      final refreshed = await client.auth.refreshSession();
      session = refreshed.session;
      if (session == null || session.accessToken.isEmpty) {
        if (kDebugMode) debugPrint('AIChat: session null after refresh -> signOut + AuthRequired');
        await client.auth.signOut();
        throw AuthRequiredException('Session expired, sign in again.');
      }
      try {
        response = await client.functions.invoke(
          'ai-chat',
          body: body,
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
        );
      } on FunctionException catch (e2) {
        if (e2.status == 401) {
          if (kDebugMode) debugPrint('AIChat: still 401 after retry -> signOut + AuthRequired');
          await client.auth.signOut();
          throw AuthRequiredException('Session expired, sign in again.');
        }
        throw AIChatException(AIChatErrorCode.aiTemporaryError, e2.reasonPhrase ?? 'Request failed.');
      }
      if (response.status == 401) {
        if (kDebugMode) debugPrint('AIChat: retry returned 401 -> signOut + AuthRequired');
        await client.auth.signOut();
        throw AuthRequiredException('Session expired, sign in again.');
      }
      if (kDebugMode) debugPrint('AIChat: response status=${response.status} (after retry)');
      return response;
    }

    if (response.status == 401) {
      if (kDebugMode) debugPrint('AIChat: 401 in body, refreshSession + retry once');
      final refreshed = await client.auth.refreshSession();
      session = refreshed.session;
      if (session == null || session.accessToken.isEmpty) {
        if (kDebugMode) debugPrint('AIChat: session null after refresh -> signOut + AuthRequired');
        await client.auth.signOut();
        throw AuthRequiredException('Session expired, sign in again.');
      }
      response = await client.functions.invoke(
        'ai-chat',
        body: body,
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      if (response.status == 401) {
        if (kDebugMode) debugPrint('AIChat: still 401 after retry -> signOut + AuthRequired');
        await client.auth.signOut();
        throw AuthRequiredException('Session expired, sign in again.');
      }
    }

    if (kDebugMode) debugPrint('AIChat: response status=${response.status}');
    return response;
  }

  static Future<String> sendMessage(
    String mode,
    String message, {
    AIChatContext? context,
    Map<String, dynamic>? dataset,
    bool useServerData = false,
    bool deepToggle = false,
    DatasetTier? tierOverride,
    bool useAnalysisCache = false,
  }) async {
    if (!Env.isConfigured) {
      throw StateError('Supabase not configured. Cannot call AI chat.');
    }
    final client = Supabase.instance.client;
    Session? session = client.auth.currentSession;
    if (session == null || session.accessToken.isEmpty) {
      _logSessionDebug('gate', null);
      throw AuthRequiredException('Please sign in again.');
    }
    _logSessionDebug('gate', session);
    final userId = session.user.id;

    DatasetTier? resolvedTier;
    if (mode == 'finance' && context != null) {
      int txCount = 0;
      if (dataset != null) {
        final agg = dataset['aggregates'];
        if (agg is Map) txCount = agg['transactionCount'] as int? ?? 0;
      }
      resolvedTier = tierOverride ??
          selectTier(
            message,
            deepToggle: deepToggle,
            transactionCount: txCount,
          );
      final useAnalysis = useAnalysisCache || isAnalysisCacheMessage(message);
      final cacheKey = useAnalysis
          ? 'a_${userId}_${context.toCacheKeyPart()}_${resolvedTier.name}_$deepToggle'
          : 'm_${userId}_${context.toCacheKeyPart()}_${resolvedTier.name}_${deepToggle}_${message.hashCode}';
      final cached = _getCachedResponse(cacheKey);
      if (cached != null) return cached;
    }
    if (kDebugMode && mode == 'finance' && resolvedTier != null) {
      debugPrint('AIChat: tier=${resolvedTier.name}');
    }

    final body = <String, dynamic>{
      'mode': mode,
      'message': message,
    };

    if (mode == 'finance') {
      if (useServerData && context != null && context.isValid) {
        body['useServerData'] = true;
        body['context'] = context.toApiContext();
        body['deepToggle'] = deepToggle;
        if (resolvedTier != null) body['tier'] = resolvedTier.name;
      } else if (dataset != null) {
        body['dataset'] = dataset;
      } else {
        throw ArgumentError(
          'Finance mode requires either useServerData+context or dataset.',
        );
      }
    }

    final response = await _invokeWithAuthRetry(client, body);

    if (response.status == 200) {
      final data = response.data;
      final map = data is Map ? data as Map<String, dynamic> : (data is String ? jsonDecode(data) as Map<String, dynamic> : null);
      if (map == null) return 'No response.';
      final content = safeString(map['content']);
      if (content == null) return 'No response.';

      if (mode == 'finance' && context != null && resolvedTier != null) {
        final useAnalysis = useAnalysisCache || isAnalysisCacheMessage(message);
        final cacheKey = useAnalysis
            ? 'a_${userId}_${context.toCacheKeyPart()}_${resolvedTier.name}_$deepToggle'
            : 'm_${userId}_${context.toCacheKeyPart()}_${resolvedTier.name}_${deepToggle}_${message.hashCode}';
        _setCachedResponse(cacheKey, content);
      }
      return content;
    }

    final err = response.data is Map
        ? response.data as Map<String, dynamic>
        : (response.data is String
            ? (jsonDecode(response.data as String) as Map<String, dynamic>? ?? <String, dynamic>{})
            : <String, dynamic>{});
    final errorCode = safeString(err['code']) ?? safeString(err['error']);
    final msg = safeString(err['message']) ?? safeString(err['error']);
    if (response.status == 400 && errorCode == 'CONTEXT_REQUIRED') {
      throw ContextRequiredException(msg ?? 'Context required.');
    }
    if (response.status == 401) {
      throw AuthRequiredException(msg ?? 'Please sign in again.');
    }
    switch (errorCode) {
      case 'AI_CONFIG_ERROR':
        if (kDebugMode) debugPrint('AIChat: mapped to AI_CONFIG_ERROR');
        throw AIChatException(AIChatErrorCode.aiConfigError, msg ?? '');
      case 'AI_RATE_LIMIT':
        if (kDebugMode) debugPrint('AIChat: mapped to AI_RATE_LIMIT');
        throw AIChatException(AIChatErrorCode.aiRateLimit, msg ?? '');
      case 'AI_TEMPORARY_ERROR':
        if (kDebugMode) debugPrint('AIChat: mapped to AI_TEMPORARY_ERROR');
        throw AIChatException(AIChatErrorCode.aiTemporaryError, msg ?? '');
      default:
        throw AIChatException(
          AIChatErrorCode.aiTemporaryError,
          msg ?? 'AI chat failed: ${response.status}',
        );
    }
  }
}

class _CacheEntry {
  final String content;
  final DateTime at;
  _CacheEntry({required this.content, required this.at});
}
