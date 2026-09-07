import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/user_settings.dart';

/// Storage service for persisting app data
class StorageService {
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Transactions
  static Future<void> saveTransactions(List<Transaction> transactions) async {
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await _prefs?.setString('transactions', jsonEncode(jsonList));
  }

  static List<Transaction> getTransactions() {
    final jsonString = _prefs?.getString('transactions') ?? '[]';
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Transaction.fromJson(json)).toList();
  }

  // Wallets
  static Future<void> saveWallets(List<Wallet> wallets) async {
    final jsonList = wallets.map((w) => w.toJson()).toList();
    await _prefs?.setString('wallets', jsonEncode(jsonList));
  }

  static List<Wallet> getWallets() {
    final jsonString = _prefs?.getString('wallets') ?? '[]';
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Wallet.fromJson(json)).toList();
  }

  // Categories
  static Future<void> saveCategories(List<Category> categories) async {
    final jsonList = categories.map((c) => c.toJson()).toList();
    await _prefs?.setString('categories', jsonEncode(jsonList));
  }

  static List<Category> getCategories() {
    final jsonString = _prefs?.getString('categories') ?? '[]';
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Category.fromJson(json)).toList();
  }

  // Budgets
  static Future<void> saveBudgets(List<Budget> budgets) async {
    final jsonList = budgets.map((b) => b.toJson()).toList();
    await _prefs?.setString('budgets', jsonEncode(jsonList));
  }

  static List<Budget> getBudgets() {
    final jsonString = _prefs?.getString('budgets') ?? '[]';
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Budget.fromJson(json)).toList();
  }

  // User Settings
  static Future<void> saveUserSettings(UserSettings settings) async {
    await _prefs?.setString('user_settings', jsonEncode(settings.toJson()));
  }

  static UserSettings getUserSettings() {
    final jsonString = _prefs?.getString('user_settings');
    if (jsonString != null) {
      return UserSettings.fromJson(jsonDecode(jsonString));
    }
    return UserSettings.defaultSettings();
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await _prefs?.clear();
  }
}


