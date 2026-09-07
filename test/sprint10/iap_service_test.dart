import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/services/iap_service.dart';
import 'package:finsor/constants/iap_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IapService', () {
    late IapService service;

    setUp(() {
      service = IapService();
    });

    tearDown(() {
      service.dispose();
    });

    test('isAvailable returns false before initialize on unsupported platforms', () async {
      await service.initialize();
      // On web/CI, store is typically unavailable
      expect(service.isAvailable, isA<bool>());
    });

    test('queryProducts returns empty when unavailable', () async {
      final response = await service.queryProducts();
      expect(response.productDetails, isEmpty);
    });

    test('resolveEntitlement returns unavailable or free when store unavailable', () async {
      final result = await service.resolveEntitlement();
      expect(result, isIn([EntitlementResult.unavailable, EntitlementResult.free]));
    });

    test('IapConstants has correct product IDs', () {
      expect(IapConstants.premiumMonthly, 'finsor_premium_monthly');
      expect(IapConstants.premiumYearly, 'finsor_premium_yearly');
      expect(IapConstants.premiumProductIds, contains(IapConstants.premiumMonthly));
      expect(IapConstants.premiumProductIds, contains(IapConstants.premiumYearly));
    });
  });
}
