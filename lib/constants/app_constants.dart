/// App-wide constants for Finsor
class AppConstants {
  // App Information
  static const String appName = 'Finsor';
  static const String appTagline =
      'The Ultimate AI-Powered Personal Finance App';
  static const String appVersion = '1.0.0';

  // Database
  static const String hiveBoxTransactions = 'transactions';
  static const String hiveBoxWallets = 'wallets';
  static const String hiveBoxCategories = 'categories';
  static const String hiveBoxBudgets = 'budgets';
  static const String hiveBoxSettings = 'settings';
  static const String hiveBoxUser = 'user';

  // Firebase Collections
  static const String firebaseUsers = 'users';
  static const String firebaseTransactions = 'transactions';
  static const String firebaseWallets = 'wallets';
  static const String firebaseCategories = 'categories';
  static const String firebaseBudgets = 'budgets';

  // API Endpoints
  static const String openAIBaseUrl = 'https://api.openai.com/v1';
  static const String exchangeRateAPI =
      'https://api.exchangerate-api.com/v4/latest';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Limits
  static const int maxTransactionAmount = 999999999;
  static const int maxWallets = 10;
  static const int maxCategories = 50;
  static const int maxBudgets = 20;
  static const int transactionHistoryLimit = 1000;

  // Premium Features
  static const int freeWalletLimit = 3;
  static const int freeBudgetLimit = 5;
  static const int freeAIQueriesPerDay = 10;

  // Security
  static const int maxPinAttempts = 5;
  static const Duration pinLockoutDuration = Duration(minutes: 5);
  /// Max length for verification code input (Supabase may send 6 or other lengths).
  static const int kVerificationCodeMaxLength = 12;

  // Backup & Sync
  static const Duration autoBackupInterval = Duration(hours: 24);
  static const Duration syncInterval = Duration(minutes: 15);

  // AI Assistant
  static const int maxAIContextLength = 4000;
  static const int maxAIResponseLength = 1000;
  static const String aiSystemPrompt = '''
You are Finsor AI, a personal finance assistant integrated into the Finsor app. 
You help users understand their spending patterns, create budgets, and make better financial decisions.
Always be helpful, concise, and provide actionable advice based on the user's transaction data.
Use emojis appropriately to make responses friendly and engaging.
''';

  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Please check your internet connection.';
  static const String errorAuth = 'Authentication failed. Please login again.';
  static const String errorInsufficientFunds = 'Insufficient funds in wallet.';
  static const String errorAmountTooLarge = 'Amount is too large.';
  static const String errorInvalidAmount = 'Please enter a valid amount.';

  // Success Messages
  static const String successTransactionAdded =
      'Transaction added successfully';
  static const String successTransactionUpdated =
      'Transaction updated successfully';
  static const String successTransactionDeleted =
      'Transaction deleted successfully';
  static const String successWalletCreated = 'Wallet created successfully';
  static const String successBudgetCreated = 'Budget created successfully';
  static const String successSettingsSaved = 'Settings saved successfully';

  // Feature Flags
  static const bool enableAIFeatures = true;
  static const bool enableCloudSync = true;
  static const bool enableAnalytics = true;
  static const bool enableNotifications = true;
  static const bool enableBiometrics = true;

  // URLs
  static const String privacyPolicyUrl = 'https://finsor.app/privacy';
  static const String termsOfServiceUrl = 'https://finsor.app/terms';
  static const String supportUrl = 'https://finsor.app/support';
  static const String feedbackUrl = 'mailto:feedback@finsor.app';

  // Social Media
  static const String twitterUrl = 'https://twitter.com/finsorapp';
  static const String instagramUrl = 'https://instagram.com/finsorapp';
  static const String githubUrl = 'https://github.com/finsorapp';
}
