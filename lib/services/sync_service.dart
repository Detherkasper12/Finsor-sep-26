import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import '../utils/safe_json_parse.dart';
import '../models/sync_operation.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/category.dart' as cat;
import '../models/budget.dart';
import '../models/recurring_transaction.dart';
import '../models/goal.dart';
import '../models/user_settings.dart';
import '../models/categorization_rule.dart';
import '../models/transaction_subcategory_link.dart';
import 'hive_database_service.dart';

enum SyncStatus { idle, syncing, offline, error }

class SyncService {
  final SupabaseClient _client;
  final HiveDatabaseService _db;
  final void Function()? onSyncComplete;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;
  DateTime? _lastSyncAt;
  DateTime? get lastSyncAt => _lastSyncAt;
  bool _disposed = false;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  final List<RealtimeChannel> _channels = [];

  static const List<String> _tables = [
    'wallets',
    'categories',
    'transactions',
    'budgets',
    'recurring_transactions',
    'goals',
    'user_settings',
    'categorization_rules',
    'transaction_subcategories',
  ];

  SyncService(this._client, this._db, {this.onSyncComplete}) {
    final uid = _client.auth.currentUser?.id;
    if (uid != null) {
      final raw = _db.getMetadata('lastSyncAt_$uid');
      if (raw != null) _lastSyncAt = DateTime.tryParse(raw);
    }
  }

  String? get _userId => _client.auth.currentUser?.id;

  void _debugLog(String msg) {
    if (kDebugMode) debugPrint(msg);
  }

  // ==================== OUTBOX ====================

  void enqueueOp({
    required String entityType,
    required String entityId,
    required String opType,
    required Map<String, dynamic> payload,
  }) {
    final op = SyncOperation(
      opId: '${entityType}_${entityId}_${DateTime.now().microsecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      opType: opType,
      payload: payload,
      createdAt: DateTime.now(),
    );
    _db.addPendingOp(op.toJson());
    _debugLog('[Sync] Enqueue $entityType $opType $entityId');
  }

  int get pendingCount => _db.pendingOpsCount;

  // ==================== PUSH ====================

  Future<void> pushPending() async {
    if (_userId == null) return;
    final ops = _db.getPendingOps()
        .map((j) => SyncOperation.fromJson(j))
        .where((op) => !op.failed)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _debugLog('[Sync] Push start, pending=${ops.length}');

    int removed = 0;
    for (final op in ops) {
      if (_disposed) return;
      try {
        if (op.opType == 'delete') {
          await _pushDelete(op);
        } else {
          await _pushUpsert(op);
        }
        await _db.removePendingOp(op.opId);
        removed++;
        _debugLog('[Sync] Pushed ${op.entityType} ${op.entityId}');
      } catch (e) {
        if (e is PostgrestException) {
          _debugLog('[Sync] Push failed table=${op.entityType} statusCode=${e.code} message=${e.message} details=${e.details}');
        } else {
          _debugLog('[Sync] Push failed for ${op.opId}: $e');
        }
        final updated = op.incrementRetry();
        await _db.updatePendingOp(updated.toJson());
        if (updated.failed) {
          _debugLog('[Sync] Op ${op.opId} marked as failed after ${SyncOperation.maxRetries} retries');
        } else {
          await Future.delayed(updated.backoffDuration);
        }
      }
    }
    _debugLog('[Sync] Push end, removed=$removed');
  }

  Future<void> _pushUpsert(SyncOperation op) async {
    final remoteData = localToRemote(op.entityType, op.payload);
    remoteData['user_id'] = _userId;
    remoteData['device_id'] = Env.deviceId;
    remoteData['updated_at'] = DateTime.now().toUtc().toIso8601String();
    if (kDebugMode) assert(remoteData['user_id'] == _userId);

    final onConflict = op.entityType == 'transaction_subcategories' ? 'id' : 'id,user_id';
    await _client.from(op.entityType).upsert(remoteData, onConflict: onConflict);
  }

  Future<void> _pushDelete(SyncOperation op) async {
    if (op.entityType == 'transaction_subcategories') {
      await _client.from(op.entityType).delete().eq('id', op.entityId).eq('user_id', _userId!);
      return;
    }
    await _client.from(op.entityType).update({
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
      'device_id': Env.deviceId,
    }).eq('id', op.entityId).eq('user_id', _userId!);
  }

  // ==================== PULL (DELTA ONLY) ====================

  Future<void> pullChanges() async {
    if (_userId == null) return;
    _debugLog('[Sync] Pull start userId=$_userId lastSyncAt=$_lastSyncAt');

    for (final table in _tables) {
      if (_disposed) return;
      try {
        var query = _client.from(table).select().eq('user_id', _userId!);
        if (_lastSyncAt != null) {
          query = query.gt('updated_at', _lastSyncAt!.toUtc().toIso8601String());
        }
        final rows = await query.order('updated_at', ascending: true);
        _debugLog('[Sync] Pull $table: ${rows.length} rows');

        for (final row in rows) {
          await _applyRemoteRow(table, row);
        }
      } catch (e) {
        if (e is PostgrestException) {
          _debugLog('[Sync] Pull failed table=$table statusCode=${e.code} message=${e.message} details=${e.details}');
        } else {
          _debugLog('[Sync] Pull error for $table: $e');
        }
      }
    }

    _lastSyncAt = DateTime.now().toUtc();
    final key = 'lastSyncAt_$_userId';
    await _db.setMetadata(key, _lastSyncAt!.toIso8601String());
    _debugLog('[Sync] Pull end');
  }

  Future<void> _applyRemoteRow(String table, Map<String, dynamic> row) async {
    final id = safeStringOr(row['id'], '');
    if (id.isEmpty) return;
    final deletedAt = row['deleted_at'];

    if (deletedAt != null) {
      await _deleteLocally(table, id);
      return;
    }

    final remoteUpdatedAt = safeDateTime(row['updated_at']);
    if (remoteUpdatedAt == null) return;
    final localUpdatedAt = _getLocalUpdatedAt(table, id);

    if (localUpdatedAt != null) {
      if (remoteUpdatedAt.isBefore(localUpdatedAt)) return;
      if (remoteUpdatedAt.isAtSameMomentAs(localUpdatedAt)) {
        final remoteDevice = safeString(row['device_id']) ?? '';
        if (Env.deviceId.compareTo(remoteDevice) > 0) return;
      }
    }

    await _upsertLocally(table, row);
  }

  DateTime? _getLocalUpdatedAt(String table, String id) {
    try {
      switch (table) {
        case 'transactions':
          final raw = _db.getMetadata('_raw_transactions_$id');
          if (raw == null) return null;
          final json = jsonDecode(raw) as Map<String, dynamic>;
          return safeDateTime(json['updatedAt']);
        case 'wallets':
          final raw = _db.getMetadata('_raw_wallets_$id');
          if (raw == null) return null;
          final json = jsonDecode(raw) as Map<String, dynamic>;
          return safeDateTime(json['updatedAt']);
        default:
          return null; // For entities without cached timestamps, always accept remote
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteLocally(String table, String id) async {
    switch (table) {
      case 'transactions':
        await _db.deleteTransaction(id);
      case 'wallets':
        await _db.deleteWallet(id);
      case 'categories':
        await _db.deleteCategory(id);
      case 'budgets':
        await _db.deleteBudget(id);
      case 'recurring_transactions':
        await _db.deleteRecurringTransaction(id);
      case 'goals':
        await _db.deleteGoal(id);
      case 'user_settings':
        break; // Don't delete settings, just update
      case 'categorization_rules':
        await _db.deleteCategorizationRule(id);
        break;
      case 'transaction_subcategories':
        await _db.deleteTransactionSubcategoryLink(id);
        break;
    }
  }

  Future<void> _upsertLocally(String table, Map<String, dynamic> row) async {
    final localJson = _remoteToLocal(table, row);

    switch (table) {
      case 'transactions':
        final t = Transaction.fromJson(localJson);
        final existing = await _db.getTransaction(t.id);
        if (existing != null) {
          await _db.updateTransaction(t);
        } else {
          await _db.addTransaction(t);
        }
      case 'wallets':
        final w = Wallet.fromJson(localJson);
        final existing = await _db.getWallet(w.id);
        if (existing != null) {
          await _db.updateWallet(w);
        } else {
          await _db.addWallet(w);
        }
      case 'categories':
        final c = cat.Category.fromJson(localJson);
        final existing = await _db.getCategory(c.id);
        if (existing != null) {
          await _db.updateCategory(c);
        } else {
          await _db.addCategory(c);
        }
      case 'budgets':
        final b = Budget.fromJson(localJson);
        final existing = await _db.getBudget(b.id);
        if (existing != null) {
          await _db.updateBudget(b);
        } else {
          await _db.addBudget(b);
        }
      case 'recurring_transactions':
        final r = RecurringTransaction.fromJson(localJson);
        final existing = await _db.getRecurringTransaction(r.id);
        if (existing != null) {
          await _db.updateRecurringTransaction(r);
        } else {
          await _db.addRecurringTransaction(r);
        }
      case 'goals':
        final g = Goal.fromJson(localJson);
        final existing = await _db.getGoal(g.id);
        if (existing != null) {
          await _db.updateGoal(g);
        } else {
          await _db.addGoal(g);
        }
      case 'user_settings':
        final s = UserSettings.fromJson(localJson);
        await _db.updateUserSettings(s);
        break;
      case 'categorization_rules':
        final r = CategorizationRule.fromJson(localJson);
        final existing = await _db.getCategorizationRule(r.id);
        if (existing != null) {
          await _db.updateCategorizationRule(r);
        } else {
          await _db.addCategorizationRule(r);
        }
        break;
      case 'transaction_subcategories':
        final link = TransactionSubcategoryLink.fromJson(localJson);
        await _db.putTransactionSubcategoryLink(link);
        break;
    }
  }

  // ==================== COLUMN MAPPING (remote snake_case → local camelCase) ====================

  Map<String, dynamic> _remoteToLocal(String table, Map<String, dynamic> row) {
    switch (table) {
      case 'transactions':
        return {
          'id': row['id'],
          'amount': row['amount'],
          'type': row['type'],
          'categoryId': row['category_id'],
          'walletId': row['wallet_id'],
          'toWalletId': row['to_wallet_id'],
          'description': row['description'],
          'createdAt': row['created_at'] ?? row['date'],
          'updatedAt': row['updated_at'],
          'recurringId': row['recurring_id'],
          'goalId': row['goal_id'],
          'metadata': row['metadata'] ?? {},
          'parentTransactionId': row['parent_transaction_id'],
          'isSplit': row['is_split'],
          'splitIndex': row['split_index'],
        };
      case 'transaction_subcategories':
        return {
          'id': row['id'],
          'transactionId': row['transaction_id'],
          'subcategoryId': row['subcategory_id'],
          'createdAt': row['created_at'],
          'updatedAt': row['updated_at'],
        };
      case 'wallets':
        return {
          'id': row['id'],
          'name': row['name'],
          'type': row['type'],
          'accountType': row['account_type'],
          'currency': row['currency'],
          'initialBalance': row['initial_balance'],
          'currentBalance': row['current_balance'],
          'description': row['description'],
          'color': row['color'],
          'iconName': row['icon_name'],
          'isActive': row['is_active'],
          'includeInTotal': row['include_in_total'],
          'isDefault': row['is_default'],
          'creditLimit': row['credit_limit'],
          'debtIOwe': row['debt_i_owe'],
          'debtOwedToMe': row['debt_owed_to_me'],
          'debtTotal': row['debt_total'],
          'showDebtInExpenses': row['show_debt_in_expenses'],
          'goalAmount': row['goal_amount'],
          'createdAt': row['created_at'],
          'updatedAt': row['updated_at'],
          'metadata': row['metadata'] ?? {},
        };
      case 'categories':
        return {
          'id': row['id'],
          'name': row['name'],
          'type': row['type'],
          'parentId': row['parent_id'],
          'description': row['description'],
          'iconName': row['icon_name'],
          'color': row['color'],
          'isActive': row['is_active'],
          'isDefault': row['is_default'],
          'sortOrder': row['sort_order'],
          'createdAt': row['created_at'],
          'updatedAt': row['updated_at'],
          'metadata': row['metadata'] ?? {},
        };
      case 'budgets':
        return {
          'id': row['id'],
          'name': row['name'],
          'categoryId': row['category_id'],
          'walletId': row['wallet_id'],
          'amount': row['amount'],
          'spent': row['spent'],
          'period': row['period'],
          'startDate': row['start_date'],
          'endDate': row['end_date'],
          'isActive': row['is_active'],
          'notifyWhenExceeded': row['notify_when_exceeded'],
          'warningThreshold': row['warning_threshold'],
          'description': row['description'],
          'createdAt': row['created_at'],
          'updatedAt': row['updated_at'],
          'metadata': row['metadata'] ?? {},
        };
      case 'recurring_transactions':
        return {
          'id': row['id'],
          'amount': row['amount'],
          'type': row['type'],
          'categoryId': row['category_id'],
          'walletId': row['wallet_id'],
          'toWalletId': row['to_wallet_id'],
          'description': row['description'],
          'frequency': row['frequency'],
          'interval': row['interval_count'],
          'startDate': row['start_date'],
          'endDate': row['end_date'],
          'nextRunDate': row['next_run_date'],
          'lastGeneratedDate': row['last_generated_date'],
          'isPaused': row['is_paused'],
          'createdAt': row['created_at'],
          'updatedAt': row['updated_at'],
        };
      case 'goals':
        return {
          'id': row['id'],
          'name': row['name'],
          'type': row['type'],
          'targetAmount': row['target_amount'],
          'currentAmount': row['current_amount'],
          'linkedWalletId': row['linked_wallet_id'],
          'debtorName': row['debtor_name'],
          'dueDate': row['due_date'],
          'status': row['status'],
          'iconName': row['icon_name'],
          'color': row['color'],
          'createdAt': row['created_at'],
          'updatedAt': row['updated_at'],
        };
      case 'user_settings':
        return {
          'themeMode': row['theme_mode'],
          'primaryCurrency': row['primary_currency'] is String
              ? jsonDecode(row['primary_currency'])
              : row['primary_currency'],
          'locale': row['locale'],
          'requirePinForAccess': row['require_pin_for_access'],
          'useBiometrics': row['use_biometrics'],
          'showBalanceOnHome': row['show_balance_on_home'],
          'enableNotifications': row['enable_notifications'],
          'enableBudgetAlerts': row['enable_budget_alerts'],
          'enableCloudSync': row['enable_cloud_sync'],
          'includeTransferInStats': row['include_transfer_in_stats'],
          'weekStartDay': row['week_start_day'],
          'startOfMonthDay': row['start_of_month_day'],
          'autoLockTimeout': row['auto_lock_timeout'],
          'currencyFormatId': row['currency_format_id'],
          'startScreenIndex': row['start_screen_index'],
          'defaultWalletId': row['default_wallet_id'],
          'lastBackupDate': row['last_backup_date'],
          'isPremiumUser': row['is_premium_user'],
          'premiumExpiryDate': row['premium_expiry_date'],
          'createdAt': row['created_at'],
          'updatedAt': row['updated_at'],
          'preferences': row['preferences'] is String
              ? jsonDecode(row['preferences'])
              : row['preferences'] ?? {},
        };
      case 'categorization_rules':
        return {
          'id': row['id'],
          'pattern': row['pattern'],
          'normalizedPattern': row['normalized_pattern'],
          'categoryId': row['category_id'],
          'transactionType': row['transaction_type'],
          'source': row['source'],
          'priority': row['priority'],
          'hitCount': row['hit_count'] ?? 0,
          'createdAt': row['created_at'],
          'updatedAt': row['updated_at'],
        };
      default:
        return row;
    }
  }

  Map<String, dynamic> localToRemote(String table, Map<String, dynamic> local) {
    switch (table) {
      case 'transactions':
        return {
          'id': local['id'],
          'amount': local['amount'],
          'type': local['type'],
          'category_id': local['categoryId'],
          'wallet_id': local['walletId'],
          'to_wallet_id': local['toWalletId'],
          'description': local['description'],
          'date': local['createdAt'],
          'recurring_id': local['recurringId'],
          'goal_id': local['goalId'],
          'metadata': local['metadata'] ?? {},
          'created_at': local['createdAt'],
          'updated_at': local['updatedAt'] ?? DateTime.now().toUtc().toIso8601String(),
          'parent_transaction_id': local['parentTransactionId'],
          'is_split': local['isSplit'] ?? false,
          'split_index': local['splitIndex'],
        };
      case 'transaction_subcategories':
        return {
          'id': local['id'],
          'transaction_id': local['transactionId'],
          'subcategory_id': local['subcategoryId'],
          'created_at': local['createdAt'],
          'updated_at': local['updatedAt'] ?? local['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
        };
      case 'wallets':
        return {
          'id': local['id'],
          'name': local['name'],
          'type': local['type'],
          'account_type': local['accountType'],
          'currency': local['currency'],
          'initial_balance': local['initialBalance'],
          'current_balance': local['currentBalance'],
          'description': local['description'],
          'color': local['color'],
          'icon_name': local['iconName'],
          'is_active': local['isActive'],
          'include_in_total': local['includeInTotal'],
          'is_default': local['isDefault'],
          'credit_limit': local['creditLimit'],
          'debt_i_owe': local['debtIOwe'],
          'debt_owed_to_me': local['debtOwedToMe'],
          'debt_total': local['debtTotal'],
          'show_debt_in_expenses': local['showDebtInExpenses'],
          'goal_amount': local['goalAmount'],
          'metadata': local['metadata'] ?? {},
          'created_at': local['createdAt'],
          'updated_at': local['updatedAt'] ?? DateTime.now().toUtc().toIso8601String(),
        };
      case 'categories':
        return {
          'id': local['id'],
          'name': local['name'],
          'type': local['type'],
          'parent_id': local['parentId'],
          'description': local['description'],
          'icon_name': local['iconName'],
          'color': local['color'],
          'is_active': local['isActive'],
          'is_default': local['isDefault'],
          'sort_order': local['sortOrder'],
          'metadata': local['metadata'] ?? {},
          'created_at': local['createdAt'],
          'updated_at': local['updatedAt'] ?? DateTime.now().toUtc().toIso8601String(),
        };
      case 'budgets':
        return {
          'id': local['id'],
          'name': local['name'],
          'category_id': local['categoryId'],
          'wallet_id': local['walletId'],
          'amount': local['amount'],
          'spent': local['spent'],
          'period': local['period'],
          'start_date': local['startDate'],
          'end_date': local['endDate'],
          'is_active': local['isActive'],
          'notify_when_exceeded': local['notifyWhenExceeded'],
          'warning_threshold': local['warningThreshold'],
          'description': local['description'],
          'metadata': local['metadata'] ?? {},
          'created_at': local['createdAt'],
          'updated_at': local['updatedAt'] ?? DateTime.now().toUtc().toIso8601String(),
        };
      case 'recurring_transactions':
        return {
          'id': local['id'],
          'amount': local['amount'],
          'type': local['type'],
          'category_id': local['categoryId'],
          'wallet_id': local['walletId'],
          'to_wallet_id': local['toWalletId'],
          'description': local['description'],
          'frequency': local['frequency'],
          'interval_count': local['interval'],
          'start_date': local['startDate'],
          'end_date': local['endDate'],
          'next_run_date': local['nextRunDate'],
          'last_generated_date': local['lastGeneratedDate'],
          'is_paused': local['isPaused'],
          'created_at': local['createdAt'],
          'updated_at': local['updatedAt'] ?? DateTime.now().toUtc().toIso8601String(),
        };
      case 'goals':
        return {
          'id': local['id'],
          'name': local['name'],
          'type': local['type'],
          'target_amount': local['targetAmount'],
          'current_amount': local['currentAmount'],
          'linked_wallet_id': local['linkedWalletId'],
          'debtor_name': local['debtorName'],
          'due_date': local['dueDate'],
          'status': local['status'],
          'icon_name': local['iconName'],
          'color': local['color'],
          'created_at': local['createdAt'],
          'updated_at': local['updatedAt'] ?? DateTime.now().toUtc().toIso8601String(),
        };
      case 'user_settings':
        return {
          'id': local['id'] ?? 'default',
          'theme_mode': local['themeMode'],
          'primary_currency': local['primaryCurrency'],
          'locale': local['locale'],
          'require_pin_for_access': local['requirePinForAccess'],
          'use_biometrics': local['useBiometrics'],
          'show_balance_on_home': local['showBalanceOnHome'],
          'enable_notifications': local['enableNotifications'],
          'enable_budget_alerts': local['enableBudgetAlerts'],
          'enable_cloud_sync': local['enableCloudSync'],
          'include_transfer_in_stats': local['includeTransferInStats'],
          'week_start_day': local['weekStartDay'],
          'start_of_month_day': local['startOfMonthDay'],
          'auto_lock_timeout': local['autoLockTimeout'],
          'currency_format_id': local['currencyFormatId'],
          'start_screen_index': local['startScreenIndex'],
          'default_wallet_id': local['defaultWalletId'],
          'last_backup_date': local['lastBackupDate'],
          'is_premium_user': local['isPremiumUser'],
          'premium_expiry_date': local['premiumExpiryDate'],
          'preferences': local['preferences'] ?? {},
          'created_at': local['createdAt'],
          'updated_at': local['updatedAt'] ?? DateTime.now().toUtc().toIso8601String(),
        };
      case 'categorization_rules':
        return {
          'id': local['id'],
          'pattern': local['pattern'],
          'normalized_pattern': local['normalizedPattern'],
          'category_id': local['categoryId'],
          'transaction_type': local['transactionType'],
          'source': local['source'],
          'priority': local['priority'],
          'hit_count': local['hitCount'] ?? 0,
          'created_at': local['createdAt'],
          'updated_at': local['updatedAt'] ?? DateTime.now().toUtc().toIso8601String(),
        };
      default:
        return local;
    }
  }

  // ==================== BOOTSTRAP ====================

  /// Enqueues all local entities as upsert ops so guest-made changes sync after login.
  /// Skips entities already in the pending queue to avoid duplicates.
  Future<void> reconcileGuestData() async {
    if (_userId == null) return;
    final pending = _db.getPendingOps().map((j) => SyncOperation.fromJson(j)).toList();
    final inQueue = <String>{};
    for (final op in pending) {
      inQueue.add('${op.entityType}:${op.entityId}');
    }
    int added = 0;
    for (final table in _tables) {
      final items = await _getLocalItems(table);
      for (final item in items) {
        final id = safeString(item['id']) ?? 'default';
        if (inQueue.contains('$table:$id')) continue;
        enqueueOp(entityType: table, entityId: id, opType: 'upsert', payload: item);
        inQueue.add('$table:$id');
        added++;
      }
    }
    if (added > 0) debugPrint('[Sync] Reconcile: enqueued $added local entities');
  }

  Future<void> bootstrap() async {
    if (_userId == null) return;
    _debugLog('[Sync] Bootstrap start userId=$_userId');

    await reconcileGuestData();

    final localHasData = await _localHasData();
    final cloudHasData = await _cloudHasData();

    if (!localHasData && cloudHasData) {
      _debugLog('[Sync] Bootstrap: pull all from cloud');
      _lastSyncAt = null;
      await pullChanges();
    } else if (localHasData && !cloudHasData) {
      _debugLog('[Sync] Bootstrap: push local snapshot');
      await _pushLocalSnapshot();
    } else {
      _debugLog('[Sync] Bootstrap: normal sync');
      await pushPending();
      await pullChanges();
    }
    _debugLog('[Sync] Bootstrap end');
  }

  Future<bool> _localHasData() async {
    final txns = await _db.getTransactions();
    final wallets = await _db.getWallets();
    return txns.isNotEmpty || wallets.length > 1;
  }

  Future<bool> _cloudHasData() async {
    try {
      final result = await _client
          .from('transactions')
          .select('id')
          .eq('user_id', _userId!)
          .limit(1);
      if (result.isNotEmpty) return true;

      final walletResult = await _client
          .from('wallets')
          .select('id')
          .eq('user_id', _userId!)
          .limit(1);
      return walletResult.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pushLocalSnapshot() async {
    for (final table in _tables) {
      final items = await _getLocalItems(table);
      for (final item in items) {
        final remoteData = localToRemote(table, item);
        remoteData['user_id'] = _userId;
        remoteData['device_id'] = Env.deviceId;
        remoteData['updated_at'] = DateTime.now().toUtc().toIso8601String();
        try {
          await _client.from(table).upsert(remoteData, onConflict: 'id,user_id');
        } catch (e) {
          if (e is PostgrestException) {
            _debugLog('[Sync] Bootstrap push failed table=$table statusCode=${e.code} message=${e.message} details=${e.details}');
          } else {
            _debugLog('[Sync] Bootstrap push error for $table: $e');
          }
        }
      }
    }
    _lastSyncAt = DateTime.now().toUtc();
    await _db.setMetadata('lastSyncAt_$_userId', _lastSyncAt!.toIso8601String());
  }

  Future<List<Map<String, dynamic>>> _getLocalItems(String table) async {
    switch (table) {
      case 'transactions':
        return (await _db.getTransactions()).map((e) => e.toJson()).toList();
      case 'wallets':
        return (await _db.getWallets()).map((e) => e.toJson()).toList();
      case 'categories':
        return (await _db.getCategories()).map((e) => e.toJson()).toList();
      case 'budgets':
        return (await _db.getBudgets()).map((e) => e.toJson()).toList();
      case 'recurring_transactions':
        return (await _db.getRecurringTransactions()).map((e) => e.toJson()).toList();
      case 'goals':
        return (await _db.getGoals()).map((e) => e.toJson()).toList();
      case 'user_settings':
        final s = await _db.getUserSettings();
        return [s.toJson()..['id'] = 'default'];
      case 'categorization_rules':
        final rules = await _db.getCategorizationRules();
        return rules.map((r) => r.toJson()).toList();
      case 'transaction_subcategories':
        final links = await _db.getAllTransactionSubcategoryLinks();
        return links.map((l) => l.toJson()).toList();
      default:
        return [];
    }
  }

  // ==================== FULL SYNC CYCLE ====================

  Future<void> sync() async {
    if (_status == SyncStatus.syncing) {
      _debugLog('[Sync] Skipped (already syncing)');
      return;
    }
    if (_userId == null) {
      _debugLog('[Sync] Skipped (offline)');
      _setStatus(SyncStatus.offline);
      return;
    }

    _debugLog('[Sync] Starting sync');
    _setStatus(SyncStatus.syncing);
    try {
      await pushPending();
      await pullChanges();
      _setStatus(SyncStatus.idle);
      onSyncComplete?.call();
      _debugLog('[Sync] Sync completed');
    } catch (e) {
      _debugLog('[Sync] Sync cycle error: $e');
      _setStatus(SyncStatus.error);
    }
  }

  // ==================== REALTIME ====================

  void subscribeRealtime() {
    if (_userId == null) return;

    for (final table in _tables) {
      final channel = _client.channel('sync_$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId!,
          ),
          callback: (payload) => _handleRealtimeEvent(table, payload),
        )
        .subscribe();

      _channels.add(channel);
    }
  }

  void _handleRealtimeEvent(String table, PostgresChangePayload payload) {
    final newRecord = payload.newRecord;
    if (newRecord.isEmpty) return;

    final deviceId = safeString(newRecord['device_id']) ?? '';
    if (deviceId == Env.deviceId) return;

    _applyRemoteRow(table, newRecord).then((_) {
      onSyncComplete?.call();
    });
  }

  // ==================== LIFECYCLE ====================

  void _setStatus(SyncStatus s) {
    _status = s;
    if (!_statusController.isClosed) {
      _statusController.add(s);
    }
  }

  void dispose() {
    _disposed = true;
    for (final c in _channels) {
      _client.removeChannel(c);
    }
    _channels.clear();
    _statusController.close();
  }
}
