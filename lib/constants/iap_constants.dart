/// Centralized IAP product IDs and configuration
/// Sandbox-ready - configure in App Store Connect / Play Console

class IapConstants {
  IapConstants._();

  /// Premium Monthly subscription
  static const String premiumMonthly = 'finsor_premium_monthly';

  /// Premium Yearly subscription
  static const String premiumYearly = 'finsor_premium_yearly';

  /// All premium product IDs
  static const Set<String> premiumProductIds = {
    premiumMonthly,
    premiumYearly,
  };
}
