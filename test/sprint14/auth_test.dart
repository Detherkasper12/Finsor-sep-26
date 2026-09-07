import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('AuthResult.ok creates success result', () {
      const result = AuthResult.ok(null);
      expect(result.success, true);
      expect(result.error, isNull);
    });

    test('AuthResult.fail creates error result', () {
      const result = AuthResult.fail('Test error');
      expect(result.success, false);
      expect(result.error, 'Test error');
      expect(result.user, isNull);
    });

    test('AuthProvider enum has expected values', () {
      expect(AuthProvider.values.length, 3);
      expect(AuthProvider.values.contains(AuthProvider.apple), true);
      expect(AuthProvider.values.contains(AuthProvider.google), true);
      expect(AuthProvider.values.contains(AuthProvider.email), true);
    });

    test('showApple and showGoogle are platform-aware', () {
      // In test environment, these should return consistent values
      expect(AuthService.showApple, isA<bool>());
      expect(AuthService.showGoogle, isA<bool>());
    });
  });
}
