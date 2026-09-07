import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../utils/safe_json_parse.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/user_settings.dart';
import '../models/recurring_transaction.dart';
import '../models/goal.dart';
import '../models/categorization_rule.dart';
import '../models/transaction_subcategory_link.dart';
import '../models/transaction_edit.dart';
import '../constants/app_constants.dart';

/// Hive database service for persistent local storage
/// Uses JSON serialization to store complex objects
class HiveDatabaseService {
  static HiveDatabaseService? _instance;
  static HiveDatabaseService get instance => _instance ??= HiveDatabaseService._();
  HiveDatabaseService._();

  // Box names
  static const String _transactionsBox = 'transactions';
  static const String _walletsBox = 'wallets';
  static const String _categoriesBox = 'categories';
  static const String _budgetsBox = 'budgets';
  static const String _settingsBox = 'settings';
  static const String _metadataBox = 'metadata';
  static const String _recurringBox = 'recurring_transactions';
  static const String _goalsBox = 'goals';
  static const String _pendingOpsBox = 'pending_ops';
  static const String _categorizationRulesBox = 'categorization_rules';
  static const String _transactionSubcategoryLinksBox = 'transaction_subcategory_links';
  static const String _transactionEditsBox = 'transaction_edits';

  // Boxes
  late Box<String> _transactions;
  late Box<String> _wallets;
  late Box<String> _categories;
  late Box<String> _budgets;
  late Box<String> _settings;
  late Box<String> _metadata;
  late Box<String> _recurring;
  late Box<String> _goals;
  late Box<String> _pendingOps;
  late Box<String> _categorizationRules;
  late Box<String> _transactionSubcategoryLinks;
  late Box<String> _transactionEdits;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive (should be called in main.dart before this)
      // Open boxes (using String type for JSON storage)
      _transactions = await Hive.openBox<String>(_transactionsBox);
      _wallets = await Hive.openBox<String>(_walletsBox);
      _categories = await Hive.openBox<String>(_categoriesBox);
      _budgets = await Hive.openBox<String>(_budgetsBox);
      _settings = await Hive.openBox<String>(_settingsBox);
      _metadata = await Hive.openBox<String>(_metadataBox);
      _recurring = await Hive.openBox<String>(_recurringBox);
      _goals = await Hive.openBox<String>(_goalsBox);
      _pendingOps = await Hive.openBox<String>(_pendingOpsBox);
      _categorizationRules = await Hive.openBox<String>(_categorizationRulesBox);
      _transactionSubcategoryLinks = await Hive.openBox<String>(_transactionSubcategoryLinksBox);
      _transactionEdits = await Hive.openBox<String>(_transactionEditsBox);

      // Check if first run and initialize defaults
      await _initializeDefaultDataIfNeeded();

      _isInitialized = true;
      debugPrint('HiveDatabaseService initialized successfully');
    } catch (e) {
      debugPrint('HiveDatabaseService init error: $e');
      throw HiveDatabaseException('Failed to initialize database: $e');
    }
  }

  /// Initialize default data for first-time users
  Future<void> _initializeDefaultDataIfNeeded() async {
    final isFirstRun = _metadata.get('isFirstRun') != 'false';
    
    if (isFirstRun) {
      debugPrint('First run detected, initializing default data...');
      
      // Add default categories
      for (final category in DefaultCategories.all) {
        await _categories.put(category.id, jsonEncode(category.toJson()));
      }

      // Add default wallet
      final defaultWallet = Wallet(
        id: 'wallet_default',
        name: 'Cash',
        type: WalletType.cash,
        currency: 'USD',
        currentBalance: 0.0,
        initialBalance: 0.0,
        isDefault: true,
        createdAt: DateTime.now(),
      );
      await _wallets.put(defaultWallet.id, jsonEncode(defaultWallet.toJson()));

      // Add default settings
      final defaultSettings = UserSettings.defaultSettings().copyWith(
        defaultWalletId: defaultWallet.id,
      );
      await _settings.put('user_settings', jsonEncode(defaultSettings.toJson()));

      // Mark first run complete
      await _metadata.put('isFirstRun', 'false');
      await _metadata.put('dbVersion', '1');
      await _metadata.put('createdAt', DateTime.now().toIso8601String());
      
      debugPrint('Default data initialized');
    }
  }

  // ==================== TRANSACTION OPERATIONS ====================

  Future<List<Transaction>> getTransactions() async {
    _ensureInitialized();
    return _transactions.values
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<Transaction>> getTransactionsByWallet(String walletId) async {
    _ensureInitialized();
    return _transactions.values
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .where((t) => t.walletId == walletId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<Transaction>> getTransactionsByCategory(String categoryId) async {
    _ensureInitialized();
    return _transactions.values
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .where((t) => t.categoryId == categoryId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _ensureInitialized();
    return _transactions.values
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .where((t) =>
            t.createdAt.isAfter(startDate.subtract(const Duration(microseconds: 1))) &&
            t.createdAt.isBefore(endDate.add(const Duration(microseconds: 1))))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Transaction?> getTransaction(String id) async {
    _ensureInitialized();
    final json = _transactions.get(id);
    return json != null ? Transaction.fromJson(jsonDecode(json)) : null;
  }

  Future<void> addTransaction(Transaction transaction) async {
    _ensureInitialized();
    await _transactions.put(transaction.id, jsonEncode(transaction.toJson()));
    await _updateWalletBalance(transaction);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    _ensureInitialized();
    final oldTransaction = await getTransaction(transaction.id);
    if (oldTransaction != null) {
      final edit = TransactionEdit(
        id: Uuid().v4(),
        transactionId: transaction.id,
        previousAmount: oldTransaction.amount,
        previousCategoryId: oldTransaction.categoryId,
        previousDate: oldTransaction.createdAt,
        previousWalletId: oldTransaction.walletId,
        previousStatus: null,
        editedAt: DateTime.now(),
      );
      await insertTransactionEdit(edit);
      await _reverseWalletBalance(oldTransaction);
    }
    await _transactions.put(transaction.id, jsonEncode(transaction.toJson()));
    await _updateWalletBalance(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    _ensureInitialized();
    final transaction = await getTransaction(id);
    if (transaction != null) {
      await _reverseWalletBalance(transaction);
      await _transactions.delete(id);
      await deleteTransactionSubcategoryLinksForTransaction(id);
    }
  }

  Future<List<TransactionSubcategoryLink>> getTransactionSubcategoryLinks(String transactionId) async {
    _ensureInitialized();
    return _transactionSubcategoryLinks.values
        .map((json) => TransactionSubcategoryLink.fromJson(jsonDecode(json)))
        .where((l) => l.transactionId == transactionId)
        .toList();
  }

  Future<List<TransactionSubcategoryLink>> getAllTransactionSubcategoryLinks() async {
    _ensureInitialized();
    return _transactionSubcategoryLinks.values
        .map((json) => TransactionSubcategoryLink.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> putTransactionSubcategoryLink(TransactionSubcategoryLink link) async {
    _ensureInitialized();
    await _transactionSubcategoryLinks.put(link.id, jsonEncode(link.toJson()));
  }

  Future<void> deleteTransactionSubcategoryLink(String linkId) async {
    _ensureInitialized();
    await _transactionSubcategoryLinks.delete(linkId);
  }

  Future<void> deleteTransactionSubcategoryLinksForTransaction(String transactionId) async {
    _ensureInitialized();
    final ids = _transactionSubcategoryLinks.values
        .map((json) => TransactionSubcategoryLink.fromJson(jsonDecode(json)))
        .where((l) => l.transactionId == transactionId)
        .map((l) => l.id)
        .toList();
    for (final id in ids) {
      await _transactionSubcategoryLinks.delete(id);
    }
  }

  Future<void> setTransactionSubcategoryLinks(String transactionId, List<String> subcategoryIds) async {
    _ensureInitialized();
    await deleteTransactionSubcategoryLinksForTransaction(transactionId);
    final now = DateTime.now();
    const uuid = Uuid();
    for (final subId in subcategoryIds) {
      final link = TransactionSubcategoryLink(
        id: uuid.v4(),
        transactionId: transactionId,
        subcategoryId: subId,
        createdAt: now,
      );
      await putTransactionSubcategoryLink(link);
    }
  }

  Future<void> insertTransactionEdit(TransactionEdit edit) async {
    _ensureInitialized();
    await _transactionEdits.put(edit.id, jsonEncode(edit.toJson()));
  }

  // ==================== WALLET OPERATIONS ====================

  Future<List<Wallet>> getWallets() async {
    _ensureInitialized();
    return _wallets.values
        .map((json) => Wallet.fromJson(jsonDecode(json)))
        .where((w) => w.isActive)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<List<Wallet>> getAllWallets() async {
    _ensureInitialized();
    return _wallets.values
        .map((json) => Wallet.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<Wallet?> getWallet(String id) async {
    _ensureInitialized();
    final json = _wallets.get(id);
    return json != null ? Wallet.fromJson(jsonDecode(json)) : null;
  }

  Future<void> addWallet(Wallet wallet) async {
    _ensureInitialized();
    await _wallets.put(wallet.id, jsonEncode(wallet.toJson()));
  }

  Future<void> updateWallet(Wallet wallet) async {
    _ensureInitialized();
    await _wallets.put(wallet.id, jsonEncode(wallet.toJson()));
  }

  Future<int> getTransactionCountByWallet(String walletId) async {
    _ensureInitialized();
    final list = await getTransactionsByWallet(walletId);
    final asTo = _transactions.values
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .where((t) => t.toWalletId == walletId)
        .length;
    return list.length + asTo;
  }

  Future<void> reassignTransactionsToWallet(String fromWalletId, String toWalletId) async {
    _ensureInitialized();
    final txFrom = await getTransactionsByWallet(fromWalletId);
    final allTx = await getTransactions();
    final txTo = allTx.where((t) => t.toWalletId == fromWalletId).toList();
    for (final t in txFrom) {
      await _reverseWalletBalance(t);
      final updated = t.copyWith(walletId: toWalletId, updatedAt: DateTime.now());
      await _transactions.put(t.id, jsonEncode(updated.toJson()));
      await _updateWalletBalance(updated);
    }
    for (final t in txTo) {
      await _reverseWalletBalance(t);
      final updated = t.copyWith(toWalletId: toWalletId, updatedAt: DateTime.now());
      await _transactions.put(t.id, jsonEncode(updated.toJson()));
      await _updateWalletBalance(updated);
    }
  }

  Future<void> deleteWallet(String id) async {
    _ensureInitialized();
    final wallet = await getWallet(id);
    if (wallet != null) {
      final updatedWallet = wallet.copyWith(isActive: false, updatedAt: DateTime.now());
      await _wallets.put(id, jsonEncode(updatedWallet.toJson()));
    }
  }

  Future<void> hardDeleteWallet(String id) async {
    _ensureInitialized();
    await _wallets.delete(id);
  }

  // ==================== CATEGORY OPERATIONS ====================

  Future<List<Category>> getCategories() async {
    _ensureInitialized();
    return _categories.values
        .map((json) => Category.fromJson(jsonDecode(json)))
        .where((c) => c.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<List<Category>> getCategoriesByType(TransactionType type) async {
    _ensureInitialized();
    return _categories.values
        .map((json) => Category.fromJson(jsonDecode(json)))
        .where((c) => c.type == type && c.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<Category?> getCategory(String id) async {
    _ensureInitialized();
    final json = _categories.get(id);
    return json != null ? Category.fromJson(jsonDecode(json)) : null;
  }

  Future<void> addCategory(Category category) async {
    _ensureInitialized();
    await _categories.put(category.id, jsonEncode(category.toJson()));
  }

  Future<void> updateCategory(Category category) async {
    _ensureInitialized();
    await _categories.put(category.id, jsonEncode(category.toJson()));
  }

  Future<void> deleteCategory(String id) async {
    _ensureInitialized();
    final category = await getCategory(id);
    if (category != null && !category.isDefault) {
      final updatedCategory = category.copyWith(isActive: false, updatedAt: DateTime.now());
      await _categories.put(id, jsonEncode(updatedCategory.toJson()));
    }
  }

  Future<int> getTransactionCountByCategory(String categoryId) async {
    final list = await getTransactionsByCategory(categoryId);
    return list.length;
  }

  Future<void> reassignTransactionsToCategory(String fromCategoryId, String toCategoryId) async {
    _ensureInitialized();
    final transactions = await getTransactionsByCategory(fromCategoryId);
    for (final t in transactions) {
      final updated = t.copyWith(categoryId: toCategoryId, updatedAt: DateTime.now());
      await _transactions.put(t.id, jsonEncode(updated.toJson()));
    }
  }

  // ==================== BUDGET OPERATIONS ====================

  Future<List<Budget>> getBudgets() async {
    _ensureInitialized();
    return _budgets.values
        .map((json) => Budget.fromJson(jsonDecode(json)))
        .where((b) => b.isActive)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Budget?> getBudget(String id) async {
    _ensureInitialized();
    final json = _budgets.get(id);
    return json != null ? Budget.fromJson(jsonDecode(json)) : null;
  }

  Future<void> addBudget(Budget budget) async {
    _ensureInitialized();
    await _budgets.put(budget.id, jsonEncode(budget.toJson()));
  }

  Future<void> updateBudget(Budget budget) async {
    _ensureInitialized();
    await _budgets.put(budget.id, jsonEncode(budget.toJson()));
  }

  Future<void> deleteBudget(String id) async {
    _ensureInitialized();
    await _budgets.delete(id);
  }

  // ==================== USER SETTINGS OPERATIONS ====================

  Future<UserSettings> getUserSettings() async {
    _ensureInitialized();
    final json = _settings.get('user_settings');
    if (json != null) {
      return UserSettings.fromJson(jsonDecode(json));
    }
    return UserSettings.defaultSettings();
  }

  Future<void> updateUserSettings(UserSettings settings) async {
    _ensureInitialized();
    final updatedSettings = settings.copyWith(updatedAt: DateTime.now());
    await _settings.put('user_settings', jsonEncode(updatedSettings.toJson()));
  }

  // ==================== RECURRING TRANSACTION OPERATIONS ====================

  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    _ensureInitialized();
    return _recurring.values
        .map((json) => RecurringTransaction.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => a.nextRunDate.compareTo(b.nextRunDate));
  }

  Future<RecurringTransaction?> getRecurringTransaction(String id) async {
    _ensureInitialized();
    final json = _recurring.get(id);
    return json != null ? RecurringTransaction.fromJson(jsonDecode(json)) : null;
  }

  Future<void> addRecurringTransaction(RecurringTransaction rt) async {
    _ensureInitialized();
    await _recurring.put(rt.id, jsonEncode(rt.toJson()));
  }

  Future<void> updateRecurringTransaction(RecurringTransaction rt) async {
    _ensureInitialized();
    await _recurring.put(rt.id, jsonEncode(rt.toJson()));
  }

  Future<void> deleteRecurringTransaction(String id) async {
    _ensureInitialized();
    await _recurring.delete(id);
  }

  // ==================== GOAL OPERATIONS ====================

  Future<List<Goal>> getGoals() async {
    _ensureInitialized();
    return _goals.values
        .map((json) => Goal.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<Goal>> getGoalsByType(GoalType type) async {
    _ensureInitialized();
    return _goals.values
        .map((json) => Goal.fromJson(jsonDecode(json)))
        .where((g) => g.type == type && g.status == GoalStatus.active)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Goal?> getGoal(String id) async {
    _ensureInitialized();
    final json = _goals.get(id);
    return json != null ? Goal.fromJson(jsonDecode(json)) : null;
  }

  Future<void> addGoal(Goal goal) async {
    _ensureInitialized();
    await _goals.put(goal.id, jsonEncode(goal.toJson()));
  }

  Future<void> updateGoal(Goal goal) async {
    _ensureInitialized();
    await _goals.put(goal.id, jsonEncode(goal.toJson()));
  }

  Future<void> deleteGoal(String id) async {
    _ensureInitialized();
    await _goals.delete(id);
  }

  Future<List<Transaction>> getTransactionsByGoal(String goalId) async {
    _ensureInitialized();
    return _transactions.values
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .where((t) => t.goalId == goalId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ==================== CATEGORIZATION RULES ====================

  Future<List<CategorizationRule>> getCategorizationRules() async {
    _ensureInitialized();
    return _categorizationRules.values
        .map((json) => CategorizationRule.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  Future<CategorizationRule?> getCategorizationRule(String id) async {
    _ensureInitialized();
    final json = _categorizationRules.get(id);
    return json != null ? CategorizationRule.fromJson(jsonDecode(json) as Map<String, dynamic>) : null;
  }

  Future<void> addCategorizationRule(CategorizationRule rule) async {
    _ensureInitialized();
    await _categorizationRules.put(rule.id, jsonEncode(rule.toJson()));
  }

  Future<void> updateCategorizationRule(CategorizationRule rule) async {
    _ensureInitialized();
    await _categorizationRules.put(rule.id, jsonEncode(rule.toJson()));
  }

  Future<void> deleteCategorizationRule(String id) async {
    _ensureInitialized();
    await _categorizationRules.delete(id);
  }

  // ==================== METADATA ====================

  String? getMetadata(String key) {
    _ensureInitialized();
    return _metadata.get(key);
  }

  Future<void> setMetadata(String key, String value) async {
    _ensureInitialized();
    await _metadata.put(key, value);
  }

  // ==================== PENDING OPS (OUTBOX) ====================

  List<Map<String, dynamic>> getPendingOps() {
    _ensureInitialized();
    return _pendingOps.values
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
  }

  Future<void> addPendingOp(Map<String, dynamic> op) async {
    _ensureInitialized();
    final key = safeStringOr(op['opId'], '');
    if (key.isNotEmpty) await _pendingOps.put(key, jsonEncode(op));
  }

  Future<void> updatePendingOp(Map<String, dynamic> op) async {
    _ensureInitialized();
    final key = safeStringOr(op['opId'], '');
    if (key.isNotEmpty) await _pendingOps.put(key, jsonEncode(op));
  }

  Future<void> removePendingOp(String opId) async {
    _ensureInitialized();
    await _pendingOps.delete(opId);
  }

  Future<void> clearPendingOps() async {
    _ensureInitialized();
    await _pendingOps.clear();
  }

  int get pendingOpsCount {
    _ensureInitialized();
    return _pendingOps.length;
  }

  // ==================== HELPER METHODS ====================

  Future<void> _updateWalletBalance(Transaction transaction) async {
    final wallet = await getWallet(transaction.walletId);
    if (wallet == null) return;

    double newBalance = wallet.currentBalance;

    switch (transaction.type) {
      case TransactionType.income:
        newBalance += transaction.amount;
        break;
      case TransactionType.expense:
        newBalance -= transaction.amount;
        break;
      case TransactionType.transfer:
        newBalance -= transaction.amount;
        if (transaction.toWalletId != null) {
          final toWallet = await getWallet(transaction.toWalletId!);
          if (toWallet != null) {
            await updateWallet(
              toWallet.copyWithNewBalance(toWallet.currentBalance + transaction.amount),
            );
          }
        }
        break;
    }

    await updateWallet(wallet.copyWithNewBalance(newBalance));
  }

  Future<void> _reverseWalletBalance(Transaction transaction) async {
    final wallet = await getWallet(transaction.walletId);
    if (wallet == null) return;

    double newBalance = wallet.currentBalance;

    switch (transaction.type) {
      case TransactionType.income:
        newBalance -= transaction.amount;
        break;
      case TransactionType.expense:
        newBalance += transaction.amount;
        break;
      case TransactionType.transfer:
        newBalance += transaction.amount;
        if (transaction.toWalletId != null) {
          final toWallet = await getWallet(transaction.toWalletId!);
          if (toWallet != null) {
            await updateWallet(
              toWallet.copyWithNewBalance(toWallet.currentBalance - transaction.amount),
            );
          }
        }
        break;
    }

    await updateWallet(wallet.copyWithNewBalance(newBalance));
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw HiveDatabaseException('Database not initialized. Call init() first.');
    }
  }

  // ==================== DATA MANAGEMENT ====================

  Future<void> clearAllData() async {
    _ensureInitialized();
    await _transactions.clear();
    await _wallets.clear();
    await _categories.clear();
    await _budgets.clear();
    await _settings.clear();
    await _metadata.clear();
    await _recurring.clear();
    await _goals.clear();
    await _pendingOps.clear();
    await _initializeDefaultDataIfNeeded();
  }

  /// Clear all data boxes without re-initializing defaults. Use before full replace restore.
  Future<void> clearAllDataForRestore() async {
    _ensureInitialized();
    await _transactions.clear();
    await _wallets.clear();
    await _categories.clear();
    await _budgets.clear();
    await _settings.clear();
    await _metadata.clear();
    await _recurring.clear();
    await _goals.clear();
    await _pendingOps.clear();
    await _categorizationRules.clear();
  }

  /// Full replace: clear local data then import. No merge; no duplicates.
  Future<void> importDataReplace(Map<String, dynamic> data) async {
    _ensureInitialized();
    await clearAllDataForRestore();
    await importData(data);
  }

  Future<Map<String, int>> getDatabaseInfo() async {
    _ensureInitialized();
    return {
      'transactions': _transactions.length,
      'wallets': _wallets.length,
      'categories': _categories.length,
      'budgets': _budgets.length,
      'recurring': _recurring.length,
      'goals': _goals.length,
    };
  }

  Future<Map<String, dynamic>> exportData() async {
    _ensureInitialized();
    return {
      'transactions': (await getTransactions()).map((t) => t.toJson()).toList(),
      'wallets': (await getAllWallets()).map((w) => w.toJson()).toList(),
      'categories': (await getCategories()).map((c) => c.toJson()).toList(),
      'budgets': (await getBudgets()).map((b) => b.toJson()).toList(),
      'recurring': (await getRecurringTransactions()).map((r) => r.toJson()).toList(),
      'goals': (await getGoals()).map((g) => g.toJson()).toList(),
      'settings': (await getUserSettings()).toJson(),
      'export_date': DateTime.now().toIso8601String(),
      'app_version': AppConstants.appVersion,
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    _ensureInitialized();

    // Import wallets first (transactions depend on them)
    if (data['wallets'] != null) {
      for (final json in data['wallets']) {
        final wallet = Wallet.fromJson(json);
        await _wallets.put(wallet.id, jsonEncode(wallet.toJson()));
      }
    }

    // Import categories
    if (data['categories'] != null) {
      for (final json in data['categories']) {
        final category = Category.fromJson(json);
        await _categories.put(category.id, jsonEncode(category.toJson()));
      }
    }

    // Import transactions (don't update balances - they're already in wallet data)
    if (data['transactions'] != null) {
      for (final json in data['transactions']) {
        final transaction = Transaction.fromJson(json);
        await _transactions.put(transaction.id, jsonEncode(transaction.toJson()));
      }
    }

    // Import budgets
    if (data['budgets'] != null) {
      for (final json in data['budgets']) {
        final budget = Budget.fromJson(json);
        await _budgets.put(budget.id, jsonEncode(budget.toJson()));
      }
    }

    // Import recurring transactions
    if (data['recurring'] != null) {
      for (final json in data['recurring']) {
        final rt = RecurringTransaction.fromJson(json);
        await _recurring.put(rt.id, jsonEncode(rt.toJson()));
      }
    }

    // Import goals
    if (data['goals'] != null) {
      for (final json in data['goals']) {
        final goal = Goal.fromJson(json);
        await _goals.put(goal.id, jsonEncode(goal.toJson()));
      }
    }

    // Import settings
    if (data['settings'] != null) {
      final settings = UserSettings.fromJson(data['settings']);
      await _settings.put('user_settings', jsonEncode(settings.toJson()));
    }
  }

  // ==================== BALANCE RECONCILIATION ====================

  /// Compute wallet balance from transactions (for verification/reconciliation)
  /// This is the source of truth check - computed should match stored
  Future<double> computeBalanceFromTransactions(String walletId) async {
    _ensureInitialized();
    final wallet = await getWallet(walletId);
    if (wallet == null) return 0.0;

    final allTransactions = await getTransactions();
    double computed = wallet.initialBalance;

    for (final tx in allTransactions) {
      if (tx.walletId == walletId) {
        switch (tx.type) {
          case TransactionType.income:
            computed += tx.amount;
            break;
          case TransactionType.expense:
            computed -= tx.amount;
            break;
          case TransactionType.transfer:
            computed -= tx.amount; // Outgoing from source
            break;
        }
      }
      // Handle incoming transfers
      if (tx.type == TransactionType.transfer && tx.toWalletId == walletId) {
        computed += tx.amount;
      }
    }

    return computed;
  }

  /// Verify all wallet balances match computed values
  /// Returns map of walletId -> {stored, computed, matches}
  Future<Map<String, Map<String, dynamic>>> verifyAllBalances() async {
    _ensureInitialized();
    final wallets = await getAllWallets();
    final results = <String, Map<String, dynamic>>{};

    for (final wallet in wallets) {
      final computed = await computeBalanceFromTransactions(wallet.id);
      final stored = wallet.currentBalance;
      results[wallet.id] = {
        'name': wallet.name,
        'stored': stored,
        'computed': computed,
        'matches': (stored - computed).abs() < 0.01, // Float tolerance
        'drift': stored - computed,
      };
    }

    return results;
  }

  /// Reconcile wallet balance (fix drift if detected)
  Future<void> reconcileWalletBalance(String walletId) async {
    _ensureInitialized();
    final wallet = await getWallet(walletId);
    if (wallet == null) return;

    final computed = await computeBalanceFromTransactions(walletId);
    if ((wallet.currentBalance - computed).abs() > 0.01) {
      debugPrint('Reconciling wallet ${wallet.name}: ${wallet.currentBalance} -> $computed');
      await updateWallet(wallet.copyWithNewBalance(computed));
    }
  }

  /// Close all boxes (call on app dispose)
  Future<void> close() async {
    if (_isInitialized) {
      await _transactions.close();
      await _wallets.close();
      await _categories.close();
      await _budgets.close();
      await _settings.close();
      await _metadata.close();
      await _recurring.close();
      await _goals.close();
      await _pendingOps.close();
      await _transactionSubcategoryLinks.close();
      await _transactionEdits.close();
      _isInitialized = false;
    }
  }
}

/// Custom exception for Hive database operations
class HiveDatabaseException implements Exception {
  final String message;
  HiveDatabaseException(this.message);

  @override
  String toString() => 'HiveDatabaseException: $message';
}
