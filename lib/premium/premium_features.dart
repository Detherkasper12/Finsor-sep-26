/// Premium feature definitions
///
/// This file defines all gatable features in the app.
/// Features can be enabled/disabled based on premium status.
///
/// NOTE: This is infrastructure only - no actual paywall or IAP is implemented yet.

enum PremiumFeature {
  /// Access to advanced analytics (trends, comparisons)
  advancedAnalytics,

  /// Unlimited wallets (free tier may limit to 2-3)
  unlimitedWallets,

  /// AI-powered insights and categorization
  aiInsights,

  /// Export data to CSV/PDF
  exportData,

  /// Multiple currencies support
  multipleCurrencies,

  /// Budget tracking with notifications
  budgetAlerts,

  /// Category customization
  customCategories,

  /// Cloud backup and sync
  cloudSync,
}

/// Feature metadata for UI display
class PremiumFeatureInfo {
  final PremiumFeature feature;
  final String title;
  final String description;
  final String iconName;

  const PremiumFeatureInfo({
    required this.feature,
    required this.title,
    required this.description,
    required this.iconName,
  });

  /// Get feature info for display
  static PremiumFeatureInfo getInfo(PremiumFeature feature) {
    switch (feature) {
      case PremiumFeature.advancedAnalytics:
        return const PremiumFeatureInfo(
          feature: PremiumFeature.advancedAnalytics,
          title: 'Advanced Analytics',
          description: 'Detailed trends, comparisons, and spending insights',
          iconName: 'analytics',
        );
      case PremiumFeature.unlimitedWallets:
        return const PremiumFeatureInfo(
          feature: PremiumFeature.unlimitedWallets,
          title: 'Unlimited Wallets',
          description: 'Create as many wallets as you need',
          iconName: 'wallet',
        );
      case PremiumFeature.aiInsights:
        return const PremiumFeatureInfo(
          feature: PremiumFeature.aiInsights,
          title: 'AI Insights',
          description: 'Smart categorization and spending predictions',
          iconName: 'smart_toy',
        );
      case PremiumFeature.exportData:
        return const PremiumFeatureInfo(
          feature: PremiumFeature.exportData,
          title: 'Export Data',
          description: 'Export your data to CSV or PDF',
          iconName: 'download',
        );
      case PremiumFeature.multipleCurrencies:
        return const PremiumFeatureInfo(
          feature: PremiumFeature.multipleCurrencies,
          title: 'Multiple Currencies',
          description: 'Track finances in different currencies',
          iconName: 'currency_exchange',
        );
      case PremiumFeature.budgetAlerts:
        return const PremiumFeatureInfo(
          feature: PremiumFeature.budgetAlerts,
          title: 'Budget Alerts',
          description: 'Get notified when approaching budget limits',
          iconName: 'notifications',
        );
      case PremiumFeature.customCategories:
        return const PremiumFeatureInfo(
          feature: PremiumFeature.customCategories,
          title: 'Custom Categories',
          description: 'Create and customize your own categories',
          iconName: 'category',
        );
      case PremiumFeature.cloudSync:
        return const PremiumFeatureInfo(
          feature: PremiumFeature.cloudSync,
          title: 'Cloud Sync',
          description: 'Sync your data across devices',
          iconName: 'cloud_sync',
        );
    }
  }
}

/// Default free tier features
const Set<PremiumFeature> freeTierFeatures = {
  // Free users get basic functionality
};

/// Default premium features (all features)
const Set<PremiumFeature> premiumFeatures = {
  PremiumFeature.advancedAnalytics,
  PremiumFeature.unlimitedWallets,
  PremiumFeature.aiInsights,
  PremiumFeature.exportData,
  PremiumFeature.multipleCurrencies,
  PremiumFeature.budgetAlerts,
  PremiumFeature.customCategories,
  PremiumFeature.cloudSync,
};

/// Features that will be gated in the first monetization phase
/// Start conservative - gate only high-value features
const Set<PremiumFeature> initiallyGatedFeatures = {
  PremiumFeature.advancedAnalytics, // Trends tab
  PremiumFeature.aiInsights,
  PremiumFeature.exportData,
  PremiumFeature.cloudSync,
};
