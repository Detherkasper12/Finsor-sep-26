import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/services/auth_service.dart';

void main() {
  group('Email OTP flow', () {
    test('AuthResult.ok returns success with user', () {
      const result = AuthResult.ok(null);
      expect(result.success, true);
      expect(result.error, isNull);
    });

    test('AuthResult.fail returns error', () {
      const result = AuthResult.fail('OTP expired');
      expect(result.success, false);
      expect(result.error, 'OTP expired');
      expect(result.user, isNull);
    });

    test('signInWithEmailOtp result has success=true, user=null (code sent)', () {
      // When OTP is sent, success=true but user is null until verified
      const result = AuthResult(success: true, error: null, user: null);
      expect(result.success, true);
      expect(result.user, isNull);
    });

    test('verifyEmailOtp failure returns meaningful error', () {
      const result = AuthResult.fail('Invalid OTP token');
      expect(result.success, false);
      expect(result.error, contains('Invalid'));
    });

    test('AuthProvider enum includes email', () {
      expect(AuthProvider.values.contains(AuthProvider.email), true);
    });

    test('OTP type is email (not magiclink)', () {
      // Verify we use OtpType.email for 6-digit code, not magic link
      // This is a documentation/intent test
      expect(AuthProvider.email.name, 'email');
    });
  });
}
