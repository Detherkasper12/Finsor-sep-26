import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../constants/iap_constants.dart';

/// Result of entitlement resolution
enum EntitlementResult {
  premium,
  free,
  unavailable,
}

/// IAP service - handles purchases and restore
/// Gracefully falls back when store unavailable (e.g. web, emulator)
class IapService {
  static bool _testMode = false;
  static void enableTestMode() => _testMode = true;
  static void disableTestMode() => _testMode = false;

  InAppPurchase get _iap => InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _available = false;
  bool _initialized = false;

  bool get isAvailable => _available;

  /// Initialize IAP - check store availability (lazy, on first use)
  Future<bool> initialize() async {
    if (_testMode) {
      _initialized = true;
      return false;
    }
    if (_initialized) return _available;
    _initialized = true;
    try {
      _available = await _iap.isAvailable();
      if (!_available) return false;
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (e) => debugPrint('IAP stream error: $e'),
      );
    } catch (e) {
      debugPrint('IAP init error: $e');
      _available = false;
    }
    return _available;
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (_isPremiumProduct(purchase.productID)) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          _iap.completePurchase(purchase);
        }
      }
    }
  }

  bool _isPremiumProduct(String productId) =>
      IapConstants.premiumProductIds.contains(productId);

  /// Resolve entitlement from store - returns premium if any premium product owned
  Future<EntitlementResult> resolveEntitlement() async {
    await initialize();
    if (!_available) return EntitlementResult.unavailable;

    try {
      await _iap.restorePurchases();
      final purchases = await _getPastPurchases();
      if (purchases.any((p) =>
          _isPremiumProduct(p.productID) &&
          (p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored))) {
        return EntitlementResult.premium;
      }
      return EntitlementResult.free;
    } catch (e) {
      debugPrint('IAP resolveEntitlement error: $e');
      return EntitlementResult.unavailable;
    }
  }

  Future<List<PurchaseDetails>> _getPastPurchases() async {
    if (!_available) return [];
    final results = <PurchaseDetails>[];
    final sub = _iap.purchaseStream.listen((purchases) {
      for (final p in purchases) {
        if (_isPremiumProduct(p.productID) &&
            (p.status == PurchaseStatus.purchased ||
                p.status == PurchaseStatus.restored)) {
          results.add(p);
        }
      }
    });
    await _iap.restorePurchases();
    await Future.delayed(const Duration(seconds: 2));
    await sub.cancel();
    return results;
  }

  /// Query available products
  Future<ProductDetailsResponse> queryProducts() async {
    await initialize();
    if (!_available) {
      return ProductDetailsResponse(
        productDetails: [],
        notFoundIDs: IapConstants.premiumProductIds.toList(),
      );
    }
    return _iap.queryProductDetails(IapConstants.premiumProductIds);
  }

  /// Purchase a product (subscription)
  Future<PurchaseResult> purchase(ProductDetails product) async {
    await initialize();
    if (!_available) {
      return PurchaseResult(
        success: false,
        error: 'Store not available',
      );
    }

    final param = PurchaseParam(productDetails: product);
    final success = await _iap.buyNonConsumable(purchaseParam: param);

    if (!success) {
      return PurchaseResult(success: false, error: 'Purchase failed to start');
    }

    final completer = Completer<PurchaseResult>();
    StreamSubscription<List<PurchaseDetails>>? sub;
    sub = _iap.purchaseStream.listen((purchases) async {
      for (final p in purchases) {
        if (p.productID == product.id) {
          await sub?.cancel();
          if (p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored) {
            await _iap.completePurchase(p);
            completer.complete(PurchaseResult(success: true));
          } else if (p.status == PurchaseStatus.error) {
            completer.complete(PurchaseResult(
              success: false,
              error: p.error?.message ?? 'Purchase failed',
            ));
          } else if (p.status == PurchaseStatus.canceled) {
            completer.complete(PurchaseResult(
              success: false,
              canceled: true,
              error: 'Purchase canceled',
            ));
          }
          return;
        }
      }
    });

    return completer.future.timeout(
      const Duration(seconds: 120),
      onTimeout: () {
        sub?.cancel();
        return PurchaseResult(success: false, error: 'Purchase timeout');
      },
    );
  }

  /// Restore purchases
  Future<RestoreResult> restorePurchases() async {
    await initialize();
    if (!_available) {
      return RestoreResult(success: false, error: 'Store not available');
    }

    try {
      await _iap.restorePurchases();
      await Future.delayed(const Duration(milliseconds: 500));
      final result = await resolveEntitlement();
      return RestoreResult(
        success: result == EntitlementResult.premium,
        restored: result == EntitlementResult.premium,
        error: result == EntitlementResult.unavailable
            ? 'Could not restore purchases'
            : null,
      );
    } catch (e) {
      return RestoreResult(success: false, error: e.toString());
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

class PurchaseResult {
  final bool success;
  final bool canceled;
  final String? error;

  PurchaseResult({
    required this.success,
    this.canceled = false,
    this.error,
  });
}

class RestoreResult {
  final bool success;
  final bool restored;
  final String? error;

  RestoreResult({
    required this.success,
    this.restored = false,
    this.error,
  });
}
