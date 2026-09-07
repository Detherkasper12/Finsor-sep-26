import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/user_settings.dart';
import '../constants/app_constants.dart';

/// Supabase database service for cloud-first approach
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  final supabase = Supabase.instance.client;
  bool _isInitialized = false;

  /// Initialize database with default data
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Check if user is authenticated
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw DatabaseException('User not authenticated');
      }

      // Initialize default data if needed
      await _initializeDefaultData();

      _isInitialized = true;
    } catch (e) {
      throw DatabaseException('Failed to initialize database: $e');
    }
  }

  /// Initialize default data for new users
  Future<void> _initializeDefaultData() async {
    final userId = supabase.auth.currentUser!.id;

    // Check if user already has data
    final existingWallets = await supabase
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .limit(1);

    if (existingWallets.isNotEmpty) return; // User already initialized

    // Initialize default categories (server-side or locally)
    for (final category in DefaultCategories.all) {
      await supabase.from('categories').insert({
        'id': category.id,
        'name': category.name,
        'icon': category.icon,
        'color': category.color,
        'type': category.type.toString().split('.').last,
        'is_default': category.isDefault,
        'is_active': category.isActive,
        'user_id': userId,
      });
    }

    // Create default wallet
    final defaultWallet = Wallet(
      id: 'default_wallet_$userId',
      name: 'Cash',
      type: WalletType.cash,
      currency: 'USD',
      createdAt: DateTime.now(),
    );

    await supabase.from('wallets').insert({
      'id': defaultWallet.id,
      'name': defaultWallet.name,
      'type': defaultWallet.type.toString().split('.').last,
      'currency': defaultWallet.currency,
      'current_balance': 0.0,
      'initial_balance': 0.0,
      'is_active': true,
      'user_id': userId,
      'created_at': defaultWallet.createdAt.toIso8601String(),
    });

    // Initialize default settings
    final defaultSettings = UserSettings(createdAt: DateTime.now());
    await supabase.from('user_settings').insert({
      'user_id': userId,
      'default_wallet_id': defaultWallet.id,
      'currency': defaultSettings.currency,
      'theme_mode': defaultSettings.themeMode.toString().split('.').last,
      'created_at': defaultSettings.createdAt.toIso8601String(),
    });
  }

  // ==================== TRANSACTION OPERATIONS ====================

  /// Get all transactions
  Future<List<Transaction>> getTransactions() async {
    _ensureInitialized();
    try {
      final data = await supabase
          .from('transactions')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);

      return data.map((json) => Transaction.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to get transactions: ${e.message}');
    }
  }

  /// Get transactions by wallet ID
  Future<List<Transaction>> getTransactionsByWallet(String walletId) async {
    _ensureInitialized();
    try {
      final data = await supabase
          .from('transactions')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .eq('wallet_id', walletId)
          .order('created_at', ascending: false);

      return data.map((json) => Transaction.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to get transactions: ${e.message}');
    }
  }

  /// Get transactions by category ID
  Future<List<Transaction>> getTransactionsByCategory(String categoryId) async {
    _ensureInitialized();
    try {
      final data = await supabase
          .from('transactions')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .eq('category_id', categoryId)
          .order('created_at', ascending: false);

      return data.map((json) => Transaction.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to get transactions: ${e.message}');
    }
  }

  /// Get transactions by date range
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _ensureInitialized();
    try {
      final data = await supabase
          .from('transactions')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return data.map((json) => Transaction.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to get transactions: ${e.message}');
    }
  }

  /// Get transaction by ID
  Future<Transaction?> getTransaction(String id) async {
    _ensureInitialized();
    try {
      final data = await supabase
          .from('transactions')
          .select()
          .eq('id', id)
          .eq('user_id', supabase.auth.currentUser!.id)
          .maybeSingle();

      return data != null ? Transaction.fromJson(data) : null;
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to get transaction: ${e.message}');
    }
  }

  /// Add transaction (KEY METHOD - THIS SAVES TO SUPABASE!)
  Future<void> addTransaction(Transaction transaction) async {
    _ensureInitialized();
    try {
      // 1️⃣ Insert transaction into Supabase
      await supabase.from('transactions').insert({
        'id': transaction.id,
        'amount': transaction.amount,
        'type': transaction.type.toString().split('.').last,
        'category_id': transaction.categoryId,
        'wallet_id': transaction.walletId,
        'to_wallet_id': transaction.toWalletId,
        'description': transaction.description,
        'date': transaction.date.toIso8601String(),
        'created_at': transaction.createdAt.toIso8601String(),
        'user_id': supabase.auth.currentUser!.id,
      });

      // 2️⃣ Update wallet balance
      await _updateWalletBalance(transaction);
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to add transaction: ${e.message}');
    }
  }

  /// Update transaction
  Future<void> updateTransaction(Transaction transaction) async {
    _ensureInitialized();
    try {
      // Get old transaction to reverse its balance effect
      final oldTransaction = await getTransaction(transaction.id);
      if (oldTransaction != null) {
        await _reverseWalletBalance(oldTransaction);
      }

      // Update transaction in Supabase
      await supabase
          .from('transactions')
          .update({
            'amount': transaction.amount,
            'type': transaction.type.toString().split('.').last,
            'category_id': transaction.categoryId,
            'wallet_id': transaction.walletId,
            'to_wallet_id': transaction.toWalletId,
            'description': transaction.description,
            'date': transaction.date.toIso8601String(),
          })
          .eq('id', transaction.id)
          .eq('user_id', supabase.auth.currentUser!.id);

      // Apply new balance effect
      await _updateWalletBalance(transaction);
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to update transaction: ${e.message}');
    }
  }

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    _ensureInitialized();
    try {
      final transaction = await getTransaction(id);
      if (transaction != null) {
        // Reverse balance effect
        await _reverseWalletBalance(transaction);

        // Delete from Supabase
        await supabase
            .from('transactions')
            .delete()
            .eq('id', id)
            .eq('user_id', supabase.auth.currentUser!.id);
      }
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to delete transaction: ${e.message}');
    }
  }

  // ==================== WALLET OPERATIONS ====================

  /// Get all wallets
  Future<List<Wallet>> getWallets() async {
    _ensureInitialized();
    try {
      final data = await supabase
          .from('wallets')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return data.map((json) => Wallet.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to get wallets: ${e.message}');
    }
  }

  /// Get wallet by ID
  Future<Wallet?> getWallet(String id) async {
    _ensureInitialized();
    try {
      final data = await supabase
          .from('wallets')
          .select()
          .eq('id', id)
          .eq('user_id', supabase.auth.currentUser!.id)
          .maybeSingle();

      return data != null ? Wallet.fromJson(data) : null;
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to get wallet: ${e.message}');
    }
  }

  /// Add wallet
  Future<void> addWallet(Wallet wallet) async {
    _ensureInitialized();
    try {
      await supabase.from('wallets').insert({
        'id': wallet.id,
        'name': wallet.name,
        'type': wallet.type.toString().split('.').last,
        'currency': wallet.currency,
        'current_balance': wallet.currentBalance,
        'initial_balance': wallet.initialBalance,
        'icon': wallet.icon,
        'color': wallet.color,
        'is_active': wallet.isActive,
        'user_id': supabase.auth.currentUser!.id,
        'created_at': wallet.createdAt.toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to add wallet: ${e.message}');
    }
  }

  /// Update wallet
  Future<void> updateWallet(Wallet wallet) async {
    _ensureInitialized();
    try {
      await supabase
          .from('wallets')
          .update({
            'name': wallet.name,
            'type': wallet.type.toString().split('.').last,
            'currency': wallet.currency,
            'current_balance': wallet.currentBalance,
            'initial_balance': wallet.initialBalance,
            'icon': wallet.icon,
            'color': wallet.color,
            'is_active': wallet.isActive,
          })
          .eq('id', wallet.id)
          .eq('user_id', supabase.auth.currentUser!.id);
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to update wallet: ${e.message}');
    }
  }

  /// Delete wallet (soft delete)
  Future<void> deleteWallet(String id) async {
    _ensureInitialized();
    try {
      await supabase
          .from('wallets')
          .update({'is_active': false})
          .eq('id', id)
          .eq('user_id', supabase.auth.currentUser!.id);
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to delete wallet: ${e.message}');
    }
  }

  // ==================== CATEGORY OPERATIONS ====================

  /// Get all categories
  Future<List<Category>> getCategories() async {
    _ensureInitialized();
    try {
      final data = await supabase
          .from('categories')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .eq('is_active', true)
          .order('name', ascending: true);

      return data.map((json) => Category.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to get categories: ${e.message}');
    }
  }

  /// Get categories by type
  Future<List<Category>> getCategoriesByType(TransactionType type) async {
    _ensureInitialized();
    try {
      final data = await supabase
          .from('categories')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .eq('type', type.toString().split('.').last)
          .eq('is_active', true)
          .order('name', ascending: true);

      return data.map((json) => Category.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to get categories: ${e.message}');
    }
  }

  /// Get category by ID
  Future<Category?> getCategory(String id) async {
    _ensureInitialized();
    try {
      final data = await supabase
          .from('categories')
          .select()
          .eq('id', id)
          .eq('user_id', supabase.auth.currentUser!.id)
          .maybeSingle();

      return data != null ? Category.fromJson(data) : null;
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to get category: ${e.message}');
    }
  }

  /// Add category
  Future<void> addCategory(Category category) async {
    _ensureInitialized();
    try {
      await supabase.from('categories').insert({
        'id': category.id,
        'name': category.name,
        'icon': category.icon,
        'color': category.color,
        'type': category.type.toString().split('.').last,
        'is_default': category.isDefault,
        'is_active': category.isActive,
        'user_id': supabase.auth.currentUser!.id,
      });
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to add category: ${e.message}');
    }
  }

  /// Update category
  Future<void> updateCategory(Category category) async {
    _ensureInitialized();
    try {
      await supabase
          .from('categories')
          .update({
            'name': category.name,
            'icon': category.icon,
            'color': category.color,
            'type': category.type.toString().split('.').last,
            'is_active': category.isActive,
          })
          .eq('id', category.id)
          .eq('user_id', supabase.auth.currentUser!.id);
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to update category: ${e.message}');
    }
  }

  /// Delete category (soft delete, only non-default)
  Future<void> deleteCategory(String id) async {
    _ensureInitialized();
    try {
      final category = await getCategory(id);
      if (category != null && !category.isDefault) {
        await supabase
            .from('categories')
            .update({'is_active': false})
            .eq('id', id)
            .eq('user_id', supabase.auth.currentUser!.id);
      }
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to delete category: ${e.message}');
    }
  }

  // ==================== BUDGET OPERATIONS ====================

  /// Get all budgets
  Future<List<Budget>> getBudgets() async {
    _ensureInitialized();
    try {
      final data = await supabase
          .from('budgets')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return data.map((json) => Budget.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to get budgets: ${e.message}');
    }
  }

  /// Get budget by ID
  Future<Budget?> getBudget(String id) async {
    _ensureInitialized();
    try {
      final data = await supabase
          .from('budgets')
          .select()
          .eq('id', id)
          .eq('user_id', supabase.auth.currentUser!.id)
          .maybeSingle();

      return data != null ? Budget.fromJson(data) : null;
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to get budget: ${e.message}');
    }
  }

  /// Add budget
  Future<void> addBudget(Budget budget) async {
    _ensureInitialized();
    try {
      await supabase.from('budgets').insert({
        'id': budget.id,
        'name': budget.name,
        'amount': budget.amount,
        'spent': budget.spent,
        'category_id': budget.categoryId,
        'period': budget.period.toString().split('.').last,
        'start_date': budget.startDate.toIso8601String(),
        'end_date': budget.endDate.toIso8601String(),
        'is_active': budget.isActive,
        'user_id': supabase.auth.currentUser!.id,
        'created_at': budget.createdAt.toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to add budget: ${e.message}');
    }
  }

  /// Update budget
  Future<void> updateBudget(Budget budget) async {
    _ensureInitialized();
    try {
      await supabase
          .from('budgets')
          .update({
            'name': budget.name,
            'amount': budget.amount,
            'spent': budget.spent,
            'category_id': budget.categoryId,
            'period': budget.period.toString().split('.').last,
            'start_date': budget.startDate.toIso8601String(),
            'end_date': budget.endDate.toIso8601String(),
            'is_active': budget.isActive,
          })
          .eq('id', budget.id)
          .eq('user_id', supabase.auth.currentUser!.id);
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to update budget: ${e.message}');
    }
  }

  /// Delete budget
  Future<void> deleteBudget(String id) async {
    _ensureInitialized();
    try {
      await supabase
          .from('budgets')
          .delete()
          .eq('id', id)
          .eq('user_id', supabase.auth.currentUser!.id);
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to delete budget: ${e.message}');
    }
  }

  // ==================== USER SETTINGS OPERATIONS ====================

  /// Get user settings
  Future<UserSettings> getUserSettings() async {
    _ensureInitialized();
    try {
      final data = await supabase
          .from('user_settings')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id)
          .maybeSingle();

      if (data == null) {
        // Create default settings if not exists
        final defaultSettings = UserSettings(createdAt: DateTime.now());
        await updateUserSettings(defaultSettings);
        return defaultSettings;
      }

      return UserSettings.fromJson(data);
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to get user settings: ${e.message}');
    }
  }

  /// Update user settings
  Future<void> updateUserSettings(UserSettings settings) async {
    _ensureInitialized();
    try {
      await supabase.from('user_settings').upsert({
        'user_id': supabase.auth.currentUser!.id,
        'default_wallet_id': settings.defaultWalletId,
        'currency': settings.currency,
        'theme_mode': settings.themeMode.toString().split('.').last,
        'language': settings.language,
        'created_at': settings.createdAt.toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to update user settings: ${e.message}');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Update wallet balance based on transaction
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

  /// Reverse wallet balance (for updates/deletes)
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

  /// Check if database is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw DatabaseException('Database not initialized. Call init() first.');
    }
  }

  /// Clear all user data (for development/testing)
  Future<void> clearAllData() async {
    _ensureInitialized();
    final userId = supabase.auth.currentUser!.id;

    try {
      await supabase.from('transactions').delete().eq('user_id', userId);
      await supabase.from('budgets').delete().eq('user_id', userId);
      await supabase.from('wallets').delete().eq('user_id', userId);
      await supabase.from('categories').delete().eq('user_id', userId);
      await supabase.from('user_settings').delete().eq('user_id', userId);

      await _initializeDefaultData();
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to clear data: ${e.message}');
    }
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseInfo() async {
    _ensureInitialized();
    final userId = supabase.auth.currentUser!.id;

    try {
      final transactions = await supabase
          .from('transactions')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', userId);

      final wallets = await supabase
          .from('wallets')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', userId);

      final categories = await supabase
          .from('categories')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', userId);

      final budgets = await supabase
          .from('budgets')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', userId);

      return {
        'transactions': transactions.length,
        'wallets': wallets.length,
        'categories': categories.length,
        'budgets': budgets.length,
      };
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to get database info: ${e.message}');
    }
  }

  /// Export all data for backup
  Future<Map<String, dynamic>> exportData() async {
    _ensureInitialized();
    return {
      'transactions': (await getTransactions()).map((t) => t.toJson()).toList(),
      'wallets': (await getWallets()).map((w) => w.toJson()).toList(),
      'categories': (await getCategories()).map((c) => c.toJson()).toList(),
      'budgets': (await getBudgets()).map((b) => b.toJson()).toList(),
      'settings': (await getUserSettings()).toJson(),
      'export_date': DateTime.now().toIso8601String(),
      'app_version': AppConstants.appVersion,
    };
  }

  /// Import data from backup
  Future<void> importData(Map<String, dynamic> data) async {
    _ensureInitialized();

    try {
      // Import wallets first
      if (data['wallets'] != null) {
        for (final json in data['wallets']) {
          final wallet = Wallet.fromJson(json);
          await addWallet(wallet);
        }
      }

      // Import categories
      if (data['categories'] != null) {
        for (final json in data['categories']) {
          final category = Category.fromJson(json);
          await addCategory(category);
        }
      }

      // Import transactions
      if (data['transactions'] != null) {
        for (final json in data['transactions']) {
          final transaction = Transaction.fromJson(json);
          await addTransaction(transaction);
        }
      }

      // Import budgets
      if (data['budgets'] != null) {
        for (final json in data['budgets']) {
          final budget = Budget.fromJson(json);
          await addBudget(budget);
        }
      }

      // Import settings
      if (data['settings'] != null) {
        final settings = UserSettings.fromJson(data['settings']);
        await updateUserSettings(settings);
      }
    } on PostgrestException catch (e) {
      throw DatabaseException('Failed to import data: ${e.message}');
    }
  }
}

/// Custom exception for database operations
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}
