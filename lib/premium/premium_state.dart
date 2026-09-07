import 'premium_features.dart';

/// Premium state representing user's entitlement status
///
/// NOTE: Currently mocked/static. Will be replaced with real
/// entitlement logic from App Store / Play Store when monetization
/// is enabled.
class PremiumState {
  /// Whether user has any premium subscription
  final bool isPremium;

  /// Set of enabled premium features
  final Set<PremiumFeature> enabledFeatures;

  /// Optional expiration date for time-limited subscriptions
  final DateTime? expiresAt;

  /// Subscription tier name (if applicable)
  final String? subscriptionTier;

  const PremiumState({
    required this.isPremium,
    required this.enabledFeatures,
    this.expiresAt,
    this.subscriptionTier,
  });

  /// Free tier state
  static const free = PremiumState(
    isPremium: false,
    enabledFeatures: freeTierFeatures,
  );

  /// Full premium state (for testing or promo)
  static PremiumState fullPremium({DateTime? expiresAt}) => PremiumState(
        isPremium: true,
        enabledFeatures: premiumFeatures,
        expiresAt: expiresAt,
        subscriptionTier: 'Premium',
      );

  /// Check if a specific feature is enabled
  bool hasFeature(PremiumFeature feature) {
    return enabledFeatures.contains(feature);
  }

  /// Check if a specific feature is gated (locked)
  bool isFeatureLocked(PremiumFeature feature) {
    if (isPremium) return false;
    return initiallyGatedFeatures.contains(feature);
  }

  /// Create a copy with modified properties
  PremiumState copyWith({
    bool? isPremium,
    Set<PremiumFeature>? enabledFeatures,
    DateTime? expiresAt,
    String? subscriptionTier,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      expiresAt: expiresAt ?? this.expiresAt,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
    );
  }

  /// Check if subscription is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get effective premium status (accounts for expiration)
  bool get isEffectivelyPremium => isPremium && !isExpired;

  @override
  String toString() {
    return 'PremiumState(isPremium: $isPremium, features: ${enabledFeatures.length}, tier: $subscriptionTier)';
  }
}

/// Premium state notifier for managing premium state
/// This class handles loading and updating premium entitlements
class PremiumStateManager {
  PremiumState _state;

  PremiumStateManager({PremiumState? initialState})
      : _state = initialState ?? PremiumState.free;

  PremiumState get state => _state;

  /// Load premium state (mock implementation)
  /// In production, this would fetch from:
  /// - Local cache (for offline access)
  /// - StoreKit / Google Play Billing
  /// - Backend verification
  Future<PremiumState> loadPremiumState() async {
    // TODO: Replace with real entitlement check
    // For now, return free tier
    _state = PremiumState.free;
    return _state;
  }

  /// Grant premium (for testing/development)
  void grantPremium({Set<PremiumFeature>? features}) {
    _state = PremiumState(
      isPremium: true,
      enabledFeatures: features ?? premiumFeatures,
      subscriptionTier: 'Development',
    );
  }

  /// Revoke premium (for testing/development)
  void revokePremium() {
    _state = PremiumState.free;
  }

  /// Enable a specific feature (for A/B testing or gradual rollout)
  void enableFeature(PremiumFeature feature) {
    _state = _state.copyWith(
      enabledFeatures: {..._state.enabledFeatures, feature},
    );
  }

  /// Disable a specific feature
  void disableFeature(PremiumFeature feature) {
    final newFeatures = Set<PremiumFeature>.from(_state.enabledFeatures)
      ..remove(feature);
    _state = _state.copyWith(enabledFeatures: newFeatures);
  }
}
