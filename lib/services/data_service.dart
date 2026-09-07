import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/category.dart';
import '../models/budget.dart';
import 'storage_service.dart';

/// Providers for app data
final dataServiceProvider = Provider<DataService>((ref) => DataService());

final transactionsProvider = StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
  return TransactionNotifier(ref.read(dataServiceProvider));
});

final walletsProvider = StateNotifierProvider<WalletNotifier, List<Wallet>>((ref) {
  return WalletNotifier(ref.read(dataServiceProvider));
});

final categoriesProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier(ref.read(dataServiceProvider));
});

final budgetsProvider = StateNotifierProvider<BudgetNotifier, List<Budget>>((ref) {
  return BudgetNotifier(ref.read(dataServiceProvider));
});

// TODO: Implement appSettingsProvider or remove

/// Data service for managing app data
class DataService {
  DataService() {
    _initializeDefaultData();
  }

  void _initializeDefaultData() {
    // Initialize default categories if none exist
    final existingCategories = StorageService.getCategories();
    if (existingCategories.isEmpty) {
      StorageService.saveCategories(DefaultCategories.all);
    }

    // Initialize default wallets if none exist
    final existingWallets = StorageService.getWallets();
    if (existingWallets.isEmpty) {
      final defaultWallets = [
        Wallet(
          id: 'wallet_cash',
          name: 'Cash',
          type: WalletType.cash,
          currency: 'USD',
          currentBalance: 1250.0,
          color: '#4CAF50',
          iconName: 'payments',
          createdAt: DateTime.now(),
        ),
        Wallet(
          id: 'wallet_bank',
          name: 'Bank Account',
          type: WalletType.bank,
          currency: 'USD',
          currentBalance: 5600.0,
          color: '#2196F3',
          iconName: 'account_balance',
          createdAt: DateTime.now(),
        ),
        Wallet(
          id: 'wallet_card',
          name: 'Credit Card',
          type: WalletType.card,
          currency: 'USD',
          currentBalance: 890.0,
          color: '#FF9800',
          iconName: 'credit_card',
          createdAt: DateTime.now(),
        ),
      ];
      StorageService.saveWallets(defaultWallets);
    }

    // Initialize sample transactions if none exist
    final existingTransactions = StorageService.getTransactions();
    if (existingTransactions.isEmpty) {
      final sampleTransactions = [
        Transaction(
          id: 'tx_1',
          amount: 50.0,
          type: TransactionType.expense,
          categoryId: 'expense_food',
          walletId: 'wallet_cash',
          description: 'Lunch at Restaurant',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Transaction(
          id: 'tx_2',
          amount: 3200.0,
          type: TransactionType.income,
          categoryId: 'income_salary',
          walletId: 'wallet_bank',
          description: 'Monthly Salary',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Transaction(
          id: 'tx_3',
          amount: 25.0,
          type: TransactionType.expense,
          categoryId: 'expense_transport',
          walletId: 'wallet_card',
          description: 'Uber Ride',
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
      ];
      StorageService.saveTransactions(sampleTransactions);
    }
  }

  List<Transaction> getTransactions() => StorageService.getTransactions();
  List<Wallet> getWallets() => StorageService.getWallets();
  List<Category> getCategories() => StorageService.getCategories();
  List<Budget> getBudgets() => StorageService.getBudgets();
  // TODO: Implement AppSettings or use UserSettings

  Future<void> saveTransactions(List<Transaction> transactions) =>
      StorageService.saveTransactions(transactions);
  Future<void> saveWallets(List<Wallet> wallets) =>
      StorageService.saveWallets(wallets);
  Future<void> saveCategories(List<Category> categories) =>
      StorageService.saveCategories(categories);
  Future<void> saveBudgets(List<Budget> budgets) =>
      StorageService.saveBudgets(budgets);
  // TODO: Implement AppSettings or use UserSettings
}

/// Transaction state notifier
class TransactionNotifier extends StateNotifier<List<Transaction>> {
  final DataService _dataService;

  TransactionNotifier(this._dataService) : super(_dataService.getTransactions());

  Future<void> addTransaction(Transaction transaction) async {
    state = [...state, transaction];
    await _dataService.saveTransactions(state);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    state = [
      for (final t in state)
        if (t.id == transaction.id) transaction else t,
    ];
    await _dataService.saveTransactions(state);
  }

  Future<void> deleteTransaction(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _dataService.saveTransactions(state);
  }

  List<Transaction> getByWallet(String walletId) {
    return state.where((t) => t.walletId == walletId).toList();
  }

  List<Transaction> getByCategory(String categoryId) {
    return state.where((t) => t.categoryId == categoryId).toList();
  }

  List<Transaction> getByDateRange(DateTime start, DateTime end) {
    return state.where((t) => 
      t.createdAt.isAfter(start) && t.createdAt.isBefore(end)
    ).toList();
  }

  double getTotalIncome() {
    return state
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalExpenses() {
    return state
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}

/// Wallet state notifier
class WalletNotifier extends StateNotifier<List<Wallet>> {
  final DataService _dataService;

  WalletNotifier(this._dataService) : super(_dataService.getWallets());

  Future<void> addWallet(Wallet wallet) async {
    state = [...state, wallet];
    await _dataService.saveWallets(state);
  }

  Future<void> updateWallet(Wallet wallet) async {
    state = [
      for (final w in state)
        if (w.id == wallet.id) wallet else w,
    ];
    await _dataService.saveWallets(state);
  }

  Future<void> deleteWallet(String id) async {
    state = state.where((w) => w.id != id).toList();
    await _dataService.saveWallets(state);
  }

  double getTotalBalance() {
    return state.fold(0.0, (sum, wallet) => sum + wallet.currentBalance);
  }

  Wallet? getWalletById(String id) {
    try {
      return state.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Category state notifier
class CategoryNotifier extends StateNotifier<List<Category>> {
  final DataService _dataService;

  CategoryNotifier(this._dataService) : super(_dataService.getCategories());

  Future<void> addCategory(Category category) async {
    state = [...state, category];
    await _dataService.saveCategories(state);
  }

  Future<void> updateCategory(Category category) async {
    state = [
      for (final c in state)
        if (c.id == category.id) category else c,
    ];
    await _dataService.saveCategories(state);
  }

  Future<void> deleteCategory(String id) async {
    final category = state.firstWhere((c) => c.id == id);
    if (!category.isDefault) {
      state = state.where((c) => c.id != id).toList();
      await _dataService.saveCategories(state);
    }
  }

  List<Category> getByType(TransactionType type) {
    return state.where((c) => c.type == type).toList();
  }

  Category? getCategoryById(String id) {
    try {
      return state.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Budget state notifier
class BudgetNotifier extends StateNotifier<List<Budget>> {
  final DataService _dataService;

  BudgetNotifier(this._dataService) : super(_dataService.getBudgets());

  Future<void> addBudget(Budget budget) async {
    state = [...state, budget];
    await _dataService.saveBudgets(state);
  }

  Future<void> updateBudget(Budget budget) async {
    state = [
      for (final b in state)
        if (b.id == budget.id) budget else b,
    ];
    await _dataService.saveBudgets(state);
  }

  Future<void> deleteBudget(String id) async {
    state = state.where((b) => b.id != id).toList();
    await _dataService.saveBudgets(state);
  }
}

// TODO: Implement AppSettingsNotifier or remove


