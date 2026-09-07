import '../utils/safe_json_parse.dart';

/// Theme mode options
enum ThemeMode {
  light,
  dark,
  system,
}

/// Currency model
class Currency {
  final String code; // USD, EUR, RUB, etc.
  final String name; // US Dollar, Euro, etc.
  final String symbol; // $, €, ₽, etc.
  final int decimalPlaces;
  final double exchangeRate; // Relative to base currency

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    this.decimalPlaces = 2,
    this.exchangeRate = 1.0,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: safeStringOr(json['code'], 'USD'),
      name: safeStringOr(json['name'], ''),
      symbol: safeStringOr(json['symbol'], '\$'),
      decimalPlaces: safeInt(json['decimalPlaces']) ?? 2,
      exchangeRate: safeDouble(json['exchangeRate']) ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'decimalPlaces': decimalPlaces,
      'exchangeRate': exchangeRate,
    };
  }
}

/// User settings model
class UserSettings {
  final ThemeMode themeMode;
  final Currency primaryCurrency;
  final String locale;
  final bool requirePinForAccess;
  final bool useBiometrics;
  final bool showBalanceOnHome;
  final bool enableNotifications;
  final bool enableBudgetAlerts;
  final bool enableCloudSync;
  final bool includeTransferInStats;
  final int weekStartDay; // 1 = Monday, 7 = Sunday
  final int startOfMonthDay; // 1-28
  final int autoLockTimeout; // seconds
  final String currencyFormatId; // Key for currency display format
  final int startScreenIndex; // 0=Accounts, 1=Categories, 2=Operations, 3=Budget, 4=Overview
  final String defaultWalletId;
  final DateTime? lastBackupDate;
  final bool isPremiumUser;
  final DateTime? premiumExpiryDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> preferences;

  const UserSettings({
    this.themeMode = ThemeMode.system,
    this.primaryCurrency = const Currency(code: 'USD', name: 'US Dollar', symbol: '\$'),
    this.locale = 'en',
    this.requirePinForAccess = false,
    this.useBiometrics = false,
    this.showBalanceOnHome = true,
    this.enableNotifications = true,
    this.enableBudgetAlerts = true,
    this.enableCloudSync = false,
    this.includeTransferInStats = true,
    this.weekStartDay = 1,
    this.startOfMonthDay = 1,
    this.autoLockTimeout = 0,
    this.currencyFormatId = 'default',
    this.startScreenIndex = 0,
    this.defaultWalletId = '',
    this.lastBackupDate,
    this.isPremiumUser = false,
    this.premiumExpiryDate,
    required this.createdAt,
    this.updatedAt,
    this.preferences = const {},
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    final rawCurrency = json['primaryCurrency'];
    return UserSettings(
      themeMode: ThemeMode.values.byName(safeStringOr(json['themeMode'], 'system')),
      primaryCurrency: Currency.fromJson(rawCurrency is Map ? Map<String, dynamic>.from(rawCurrency) : const {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'}),
      locale: safeStringOr(json['locale'], 'en'),
      requirePinForAccess: json['requirePinForAccess'] == true,
      useBiometrics: json['useBiometrics'] == true,
      showBalanceOnHome: json['showBalanceOnHome'] != false,
      enableNotifications: json['enableNotifications'] != false,
      enableBudgetAlerts: json['enableBudgetAlerts'] != false,
      enableCloudSync: json['enableCloudSync'] == true,
      includeTransferInStats: json['includeTransferInStats'] != false,
      weekStartDay: safeInt(json['weekStartDay']) ?? 1,
      startOfMonthDay: safeInt(json['startOfMonthDay']) ?? 1,
      autoLockTimeout: safeInt(json['autoLockTimeout']) ?? 0,
      currencyFormatId: safeStringOr(json['currencyFormatId'], 'default'),
      startScreenIndex: safeInt(json['startScreenIndex']) ?? 0,
      defaultWalletId: safeStringOr(json['defaultWalletId'], ''),
      lastBackupDate: safeDateTime(json['lastBackupDate']),
      isPremiumUser: json['isPremiumUser'] == true,
      premiumExpiryDate: safeDateTime(json['premiumExpiryDate']),
      createdAt: safeDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: safeDateTime(json['updatedAt']),
      preferences: Map<String, dynamic>.from(json['preferences'] is Map ? json['preferences'] as Map : {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'primaryCurrency': primaryCurrency.toJson(),
      'locale': locale,
      'requirePinForAccess': requirePinForAccess,
      'useBiometrics': useBiometrics,
      'showBalanceOnHome': showBalanceOnHome,
      'enableNotifications': enableNotifications,
      'enableBudgetAlerts': enableBudgetAlerts,
      'enableCloudSync': enableCloudSync,
      'includeTransferInStats': includeTransferInStats,
      'weekStartDay': weekStartDay,
      'startOfMonthDay': startOfMonthDay,
      'autoLockTimeout': autoLockTimeout,
      'currencyFormatId': currencyFormatId,
      'startScreenIndex': startScreenIndex,
      'defaultWalletId': defaultWalletId,
      'lastBackupDate': lastBackupDate?.toIso8601String(),
      'isPremiumUser': isPremiumUser,
      'premiumExpiryDate': premiumExpiryDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'preferences': preferences,
    };
  }

  /// Default settings factory
  factory UserSettings.defaultSettings() {
    return UserSettings(
      createdAt: DateTime.now(),
    );
  }

  UserSettings copyWith({
    ThemeMode? themeMode,
    Currency? primaryCurrency,
    String? locale,
    bool? requirePinForAccess,
    bool? useBiometrics,
    bool? showBalanceOnHome,
    bool? enableNotifications,
    bool? enableBudgetAlerts,
    bool? enableCloudSync,
    bool? includeTransferInStats,
    int? weekStartDay,
    int? startOfMonthDay,
    int? autoLockTimeout,
    String? currencyFormatId,
    int? startScreenIndex,
    String? defaultWalletId,
    DateTime? lastBackupDate,
    bool? isPremiumUser,
    DateTime? premiumExpiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      locale: locale ?? this.locale,
      requirePinForAccess: requirePinForAccess ?? this.requirePinForAccess,
      useBiometrics: useBiometrics ?? this.useBiometrics,
      showBalanceOnHome: showBalanceOnHome ?? this.showBalanceOnHome,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableBudgetAlerts: enableBudgetAlerts ?? this.enableBudgetAlerts,
      enableCloudSync: enableCloudSync ?? this.enableCloudSync,
      includeTransferInStats: includeTransferInStats ?? this.includeTransferInStats,
      weekStartDay: weekStartDay ?? this.weekStartDay,
      startOfMonthDay: startOfMonthDay ?? this.startOfMonthDay,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      currencyFormatId: currencyFormatId ?? this.currencyFormatId,
      startScreenIndex: startScreenIndex ?? this.startScreenIndex,
      defaultWalletId: defaultWalletId ?? this.defaultWalletId,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      isPremiumUser: isPremiumUser ?? this.isPremiumUser,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
    );
  }
}

/// Extension methods for UserSettings
extension UserSettingsX on UserSettings {
  /// Check if user has active premium subscription
  bool get hasActivePremium {
    if (!isPremiumUser) return false;
    if (premiumExpiryDate == null) return true; // Lifetime premium
    return DateTime.now().isBefore(premiumExpiryDate!);
  }

  /// Get theme mode display name
  String get themeModeDisplayName {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Create a copy with updated fields
  UserSettings copyWithUpdatedAt() {
    return copyWith(updatedAt: DateTime.now());
  }
}

/// Default currencies - popular fiat for backward compat
class DefaultCurrencies {
  static const List<Currency> popular = [
    Currency(code: 'USD', name: 'US Dollar', symbol: '\$'),
    Currency(code: 'EUR', name: 'Euro', symbol: '€'),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£'),
    Currency(code: 'RUB', name: 'Russian Ruble', symbol: '₽'),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', decimalPlaces: 0),
    Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
    Currency(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$'),
    Currency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$'),
    Currency(code: 'CHF', name: 'Swiss Franc', symbol: 'CHF'),
    Currency(code: 'ILS', name: 'Israeli New Shekel', symbol: '₪'),
  ];

  static Currency get defaultCurrency => popular.first;
}


