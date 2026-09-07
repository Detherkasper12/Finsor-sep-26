import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../premium/premium_features.dart';
import '../premium/premium_state.dart';
import '../services/iap_service.dart';
import 'iap_provider.dart';

/// Provider for premium state - store-backed entitlements when IAP available
final premiumStateProvider =
    StateNotifierProvider<PremiumStateNotifier, PremiumState>((ref) {
  final iapService = ref.watch(iapServiceProvider);
  return PremiumStateNotifier(iapService);
});

/// State notifier for premium state management
class PremiumStateNotifier extends StateNotifier<PremiumState> {
  final IapService _iapService;

  PremiumStateNotifier(this._iapService) : super(PremiumState.free);

  bool hasFeature(PremiumFeature feature) => state.hasFeature(feature);

  bool isFeatureLocked(PremiumFeature feature) =>
      state.isFeatureLocked(feature);

  /// Grant premium (dev/testing or after successful purchase)
  void grantPremium({Set<PremiumFeature>? features, String? tier}) {
    state = PremiumState(
      isPremium: true,
      enabledFeatures: features ?? premiumFeatures,
      subscriptionTier: tier ?? 'Development',
    );
  }

  void revokePremium() {
    state = PremiumState.free;
  }

  void togglePremium() {
    if (state.isPremium) {
      revokePremium();
    } else {
      grantPremium();
    }
  }

  /// Refresh from store - resolves entitlement via IAP
  Future<void> refreshPremiumState() async {
    final result = await _iapService.resolveEntitlement();
    switch (result) {
      case EntitlementResult.premium:
        grantPremium(tier: 'Premium');
        break;
      case EntitlementResult.free:
        revokePremium();
        break;
      case EntitlementResult.unavailable:
        break;
    }
  }
}

/// Convenience provider to check if user is premium
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(premiumStateProvider).isEffectivelyPremium;
});

/// Provider to check if a specific feature is locked
final isFeatureLockedProvider =
    Provider.family<bool, PremiumFeature>((ref, feature) {
  return ref.watch(premiumStateProvider).isFeatureLocked(feature);
});

/// Provider to check if a specific feature is available
final hasFeatureProvider =
    Provider.family<bool, PremiumFeature>((ref, feature) {
  return ref.watch(premiumStateProvider).hasFeature(feature);
});
