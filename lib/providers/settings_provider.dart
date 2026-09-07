import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_settings.dart';
import 'analytics_providers.dart';
import 'budgets_provider.dart';
import 'categories_provider.dart';
import 'database_provider.dart';
import 'insights_providers.dart';
import 'repository_providers.dart';
import 'sync_provider.dart';
import 'transaction_provider.dart' hide recentTransactionsProvider;
import 'wallet_provider.dart';

/// Provider for user settings
final settingsProvider = FutureProvider<UserSettings>((ref) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getUserSettings();
});

/// Notifier for settings operations
class SettingsNotifier extends StateNotifier<AsyncValue<void>> {
  SettingsNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  /// Update user settings
  Future<void> updateSettings(UserSettings settings) async {
    state = const AsyncValue.loading();
    try {
      final databaseService = ref.read(databaseServiceProvider);
      await databaseService.updateUserSettings(settings);
      enqueueSyncOp(ref, entityType: 'user_settings', entityId: 'default',
          opType: 'upsert', payload: settings.toJson()..['id'] = 'default');
      
      ref.invalidate(settingsProvider);
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update theme mode
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    final currentSettings = await ref.read(settingsProvider.future);
    await updateSettings(currentSettings.copyWith(themeMode: themeMode));
  }

  /// Update primary currency
  Future<void> updatePrimaryCurrency(Currency currency) async {
    final currentSettings = await ref.read(settingsProvider.future);
    await updateSettings(currentSettings.copyWith(primaryCurrency: currency));
  }

  /// Update locale
  Future<void> updateLocale(String locale) async {
    final currentSettings = await ref.read(settingsProvider.future);
    await updateSettings(currentSettings.copyWith(locale: locale));
  }

  /// Toggle PIN requirement
  Future<void> togglePinRequirement(bool requirePin) async {
    final currentSettings = await ref.read(settingsProvider.future);
    await updateSettings(currentSettings.copyWith(requirePinForAccess: requirePin));
  }

  /// Toggle biometrics
  Future<void> toggleBiometrics(bool useBiometrics) async {
    final currentSettings = await ref.read(settingsProvider.future);
    await updateSettings(currentSettings.copyWith(useBiometrics: useBiometrics));
  }

  /// Toggle cloud sync
  Future<void> toggleCloudSync(bool enableCloudSync) async {
    final currentSettings = await ref.read(settingsProvider.future);
    await updateSettings(currentSettings.copyWith(enableCloudSync: enableCloudSync));
  }

  Future<void> updateCurrencyFormatId(String currencyFormatId) async {
    final currentSettings = await ref.read(settingsProvider.future);
    await updateSettings(currentSettings.copyWith(currencyFormatId: currencyFormatId));
  }

  Future<void> updateWeekStartDay(int weekStartDay) async {
    final currentSettings = await ref.read(settingsProvider.future);
    await updateSettings(currentSettings.copyWith(weekStartDay: weekStartDay));
  }

  Future<void> updateStartScreenIndex(int startScreenIndex) async {
    final currentSettings = await ref.read(settingsProvider.future);
    await updateSettings(currentSettings.copyWith(startScreenIndex: startScreenIndex));
  }

  /// Reset app: clear all data and re-initialize defaults
  Future<void> resetAllData() async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseServiceProvider);
      await db.clearAllData();
      ref.invalidate(transactionsProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(walletsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(budgetsProvider);
      ref.invalidate(computedBudgetsProvider);
      ref.invalidate(periodSummaryProvider);
      ref.invalidate(currentMonthCategoryBreakdownProvider);
      ref.invalidate(insightsProvider);
      ref.invalidate(settingsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update last-used wallet and category (for transaction input defaults)
  Future<void> updateLastUsedTransactionDefaults({
    required String walletId,
    required String categoryId,
    required String type,
  }) async {
    final currentSettings = await ref.read(settingsProvider.future);
    final newPrefs = Map<String, dynamic>.from(currentSettings.preferences);
    newPrefs['lastUsedWalletId'] = walletId;
    newPrefs['lastUsedCategoryId_$type'] = categoryId;
    await updateSettings(currentSettings.copyWith(
      preferences: newPrefs,
      updatedAt: DateTime.now(),
    ));
  }

  /// Mark onboarding as complete
  Future<void> setOnboardingComplete() async {
    final currentSettings = await ref.read(settingsProvider.future);
    final newPrefs = Map<String, dynamic>.from(currentSettings.preferences);
    newPrefs['onboarding_complete'] = true;
    await updateSettings(currentSettings.copyWith(
      preferences: newPrefs,
      updatedAt: DateTime.now(),
    ));
  }
}

/// Provider to check if onboarding is complete
final isOnboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  return settings.preferences['onboarding_complete'] == true;
});

/// Provider for settings operations
final settingsNotifierProvider = 
    StateNotifierProvider<SettingsNotifier, AsyncValue<void>>((ref) {
  return SettingsNotifier(ref);
});
