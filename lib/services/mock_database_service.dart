import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/user_settings.dart';
import '../constants/app_constants.dart';
import '../utils/safe_json_parse.dart';

/// Mock database service for development/demo
class MockDatabaseService {
  static MockDatabaseService? _instance;
  static MockDatabaseService get instance => _instance ??= MockDatabaseService._();
  MockDatabaseService._();

  bool _isInitialized = false;

  // Mock data storage
  final List<Transaction> _transactions = [];
  final List<Wallet> _wallets = [];
  final List<Category> _categories = [];
  final List<Budget> _budgets = [];
  UserSettings? _settings;
  final Map<String, dynamic> _userData = {};

  /// Initialize mock database
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _initializeMockData();
      _isInitialized = true;
    } catch (e) {
      throw DatabaseException('Failed to initialize mock database: $e');
    }
  }

  /// Initialize with sample data
  Future<void> _initializeMockData() async {
    // Initialize default categories
    if (_categories.isEmpty) {
      _categories.addAll(DefaultCategories.all);
    }

    // Initialize default settings
    _settings ??= UserSettings.defaultSettings();

    // Create sample wallets
    if (_wallets.isEmpty) {
      _wallets.addAll([
        Wallet(
          id: 'wallet_cash',
          name: 'Cash',
          type: WalletType.cash,
          currency: 'USD',
          currentBalance: 1250.0,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Wallet(
          id: 'wallet_bank',
          name: 'Bank Account',
          type: WalletType.bank,
          currency: 'USD',
          currentBalance: 5600.0,
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
        ),
        Wallet(
          id: 'wallet_card',
          name: 'Credit Card',
          type: WalletType.card,
          currency: 'USD',
          currentBalance: 890.0,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
      ]);
    }

    // Create sample transactions
    if (_transactions.isEmpty) {
      _transactions.addAll([
        Transaction(
          id: 'tx_1',
          amount: 50.0,
          type: TransactionType.expense,
          categoryId: 'expense_food',
          walletId: 'wallet_cash',
          description: 'Lunch at restaurant',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Transaction(
          id: 'tx_2',
          amount: 3200.0,
          type: TransactionType.income,
          categoryId: 'income_salary',
          walletId: 'wallet_bank',
          description: 'Monthly salary',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Transaction(
          id: 'tx_3',
          amount: 25.0,
          type: TransactionType.expense,
          categoryId: 'expense_transport',
          walletId: 'wallet_card',
          description: 'Uber ride',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        Transaction(
          id: 'tx_4',
          amount: 120.0,
          type: TransactionType.expense,
          categoryId: 'expense_shopping',
          walletId: 'wallet_bank',
          description: 'Groceries',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Transaction(
          id: 'tx_5',
          amount: 15.0,
          type: TransactionType.expense,
          categoryId: 'expense_entertainment',
          walletId: 'wallet_cash',
          description: 'Movie ticket',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ]);
    }

    // Create sample budget
    if (_budgets.isEmpty) {
      _budgets.add(
        Budget(
          id: 'budget_food',
          name: 'Food Budget',
          categoryId: 'expense_food',
          amount: 500.0,
          spent: 150.0,
          period: BudgetPeriod.monthly,
          startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
          endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      );
    }
  }

  // TRANSACTION OPERATIONS

  Future<List<Transaction>> getTransactions() async {
    _ensureInitialized();
    return List.from(_transactions)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<Transaction>> getTransactionsByWallet(String walletId) async {
    _ensureInitialized();
    return _transactions
        .where((transaction) => transaction.walletId == walletId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<Transaction>> getTransactionsByCategory(String categoryId) async {
    _ensureInitialized();
    return _transactions
        .where((transaction) => transaction.categoryId == categoryId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _ensureInitialized();
    return _transactions
        .where((transaction) =>
            transaction.createdAt.isAfter(startDate.subtract(const Duration(microseconds: 1))) &&
            transaction.createdAt.isBefore(endDate.add(const Duration(microseconds: 1))))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Transaction?> getTransaction(String id) async {
    _ensureInitialized();
    try {
      return _transactions.firstWhere((transaction) => transaction.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    _ensureInitialized();
    _transactions.add(transaction);
    await _updateWalletBalance(transaction);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    _ensureInitialized();
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      final oldTransaction = _transactions[index];
      await _reverseWalletBalance(oldTransaction);
      _transactions[index] = transaction;
      await _updateWalletBalance(transaction);
    }
  }

  Future<void> deleteTransaction(String id) async {
    _ensureInitialized();
    final transaction = await getTransaction(id);
    if (transaction != null) {
      await _reverseWalletBalance(transaction);
      _transactions.removeWhere((t) => t.id == id);
    }
  }

  // WALLET OPERATIONS

  Future<List<Wallet>> getWallets() async {
    _ensureInitialized();
    return _wallets.where((wallet) => wallet.isActive).toList();
  }

  Future<Wallet?> getWallet(String id) async {
    _ensureInitialized();
    try {
      return _wallets.firstWhere((wallet) => wallet.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addWallet(Wallet wallet) async {
    _ensureInitialized();
    _wallets.add(wallet);
  }

  Future<void> updateWallet(Wallet wallet) async {
    _ensureInitialized();
    final index = _wallets.indexWhere((w) => w.id == wallet.id);
    if (index != -1) {
      _wallets[index] = wallet;
    }
  }

  Future<void> deleteWallet(String id) async {
    _ensureInitialized();
    final index = _wallets.indexWhere((w) => w.id == id);
    if (index != -1) {
      _wallets[index] = _wallets[index].copyWith(isActive: false);
    }
  }

  // CATEGORY OPERATIONS

  Future<List<Category>> getCategories() async {
    _ensureInitialized();
    return _categories.where((category) => category.isActive).toList();
  }

  Future<List<Category>> getCategoriesByType(TransactionType type) async {
    _ensureInitialized();
    return _categories
        .where((category) => category.type == type && category.isActive)
        .toList();
  }

  Future<Category?> getCategory(String id) async {
    _ensureInitialized();
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addCategory(Category category) async {
    _ensureInitialized();
    _categories.add(category);
  }

  Future<void> updateCategory(Category category) async {
    _ensureInitialized();
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
    }
  }

  Future<void> deleteCategory(String id) async {
    _ensureInitialized();
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1 && !_categories[index].isDefault) {
      _categories[index] = _categories[index].copyWith(isActive: false);
    }
  }

  // BUDGET OPERATIONS

  Future<List<Budget>> getBudgets() async {
    _ensureInitialized();
    return _budgets.where((budget) => budget.isActive).toList();
  }

  Future<Budget?> getBudget(String id) async {
    _ensureInitialized();
    try {
      return _budgets.firstWhere((budget) => budget.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addBudget(Budget budget) async {
    _ensureInitialized();
    _budgets.add(budget);
  }

  Future<void> updateBudget(Budget budget) async {
    _ensureInitialized();
    final index = _budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      _budgets[index] = budget;
    }
  }

  Future<void> deleteBudget(String id) async {
    _ensureInitialized();
    _budgets.removeWhere((b) => b.id == id);
  }

  // USER SETTINGS OPERATIONS

  Future<UserSettings> getUserSettings() async {
    try {
      _ensureInitialized();
      
      // Try to load from SharedPreferences if in-memory settings is null
      if (_settings == null) {
        final prefs = await SharedPreferences.getInstance();
        final settingsString = prefs.getString('user_settings');
        
        if (settingsString != null) {
          final settingsJson = json.decode(settingsString) as Map<String, dynamic>;
          
          final themeModeString = safeString(settingsJson['themeMode']);
          ThemeMode themeMode = ThemeMode.system;
          if (themeModeString != null && themeModeString.isNotEmpty) {
            if (themeModeString.contains('light')) themeMode = ThemeMode.light;
            else if (themeModeString.contains('dark')) themeMode = ThemeMode.dark;
          }

          final currencyData = settingsJson['primaryCurrency'];
          Currency primaryCurrency = DefaultCurrencies.popular.first;
          if (currencyData is Map) {
            final c = currencyData as Map;
            primaryCurrency = Currency(
              code: safeStringOr(c['code'], 'USD'),
              name: safeStringOr(c['name'], 'US Dollar'),
              symbol: safeStringOr(c['symbol'], '\$'),
              decimalPlaces: safeInt(c['decimalPlaces']) ?? 2,
            );
          }

          _settings = UserSettings(
            themeMode: themeMode,
            primaryCurrency: primaryCurrency,
            locale: safeStringOr(settingsJson['locale'], 'en'),
            showBalanceOnHome: settingsJson['showBalanceOnHome'] != false,
            enableCloudSync: settingsJson['enableCloudSync'] == true,
            requirePinForAccess: settingsJson['requirePinForAccess'] == true,
            useBiometrics: settingsJson['useBiometrics'] == true,
            defaultWalletId: safeStringOr(settingsJson['defaultWalletId'], ''),
            createdAt: safeDateTime(settingsJson['createdAt']) ?? DateTime.now(),
            updatedAt: safeDateTime(settingsJson['updatedAt']),
          );
        }
      }
      
      return _settings ?? UserSettings.defaultSettings();
    } catch (e) {
      print('Error loading settings: $e');
      // Return default settings if there's any error
      return UserSettings.defaultSettings();
    }
  }

  Future<void> updateUserSettings(UserSettings settings) async {
    _ensureInitialized();
    _settings = settings;
    
    // Persist settings to SharedPreferences for mock database
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = {
        'themeMode': settings.themeMode.toString(),
        'primaryCurrency': {
          'code': settings.primaryCurrency.code,
          'name': settings.primaryCurrency.name,
          'symbol': settings.primaryCurrency.symbol,
          'decimalPlaces': settings.primaryCurrency.decimalPlaces,
        },
        'locale': settings.locale,
        'showBalanceOnHome': settings.showBalanceOnHome,
        'enableCloudSync': settings.enableCloudSync,
        'requirePinForAccess': settings.requirePinForAccess,
        'useBiometrics': settings.useBiometrics,
        'defaultWalletId': settings.defaultWalletId,
        'createdAt': settings.createdAt.toIso8601String(),
        'updatedAt': settings.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };
      await prefs.setString('user_settings', json.encode(settingsJson));
    } catch (e) {
      print('Error persisting settings: $e');
    }
  }

  // USER DATA OPERATIONS

  Future<T?> getUserData<T>(String key) async {
    _ensureInitialized();
    return _userData[key] as T?;
  }

  Future<void> setUserData<T>(String key, T value) async {
    _ensureInitialized();
    _userData[key] = value;
  }

  Future<void> removeUserData(String key) async {
    _ensureInitialized();
    _userData.remove(key);
  }

  // HELPER METHODS

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
      throw DatabaseException('Database not initialized. Call init() first.');
    }
  }

  Future<void> clearAllData() async {
    _ensureInitialized();
    _transactions.clear();
    _wallets.clear();
    _categories.clear();
    _budgets.clear();
    _userData.clear();
    _settings = null;
    await _initializeMockData();
  }

  Future<Map<String, int>> getDatabaseInfo() async {
    _ensureInitialized();
    return {
      'transactions': _transactions.length,
      'wallets': _wallets.length,
      'categories': _categories.length,
      'budgets': _budgets.length,
      'user_data': _userData.length,
    };
  }

  Future<Map<String, dynamic>> exportData() async {
    _ensureInitialized();
    return {
      'transactions': _transactions.map((t) => t.toJson()).toList(),
      'wallets': _wallets.map((w) => w.toJson()).toList(),
      'categories': _categories.map((c) => c.toJson()).toList(),
      'budgets': _budgets.map((b) => b.toJson()).toList(),
      'settings': (await getUserSettings()).toJson(),
      'user_data': _userData,
      'export_date': DateTime.now().toIso8601String(),
      'app_version': AppConstants.appVersion,
    };
  }
}

/// Custom exception for database operations
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);
  
  @override
  String toString() => 'DatabaseException: $message';
}
