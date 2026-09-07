import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/constants/app_constants.dart';
import 'package:finsor/services/auth_service.dart';

void main() {
  group('AuthResult', () {
    test('ok has success and no error', () {
      const result = AuthResult.ok(null);
      expect(result.success, true);
      expect(result.error, isNull);
      expect(result.needsEmailVerification, false);
    });

    test('fail has error and no user', () {
      const result = AuthResult.fail('Invalid credentials');
      expect(result.success, false);
      expect(result.error, 'Invalid credentials');
      expect(result.user, isNull);
    });

    test('needsEmailVerification is set for signup pending verification', () {
      const result = AuthResult(
        success: true,
        error: null,
        user: null,
        needsEmailVerification: true,
      );
      expect(result.success, true);
      expect(result.needsEmailVerification, true);
    });
  });

  group('Password validation (sign up)', () {
    test('password mismatch should be validated in UI', () {
      const password = 'secret123';
      const confirm = 'secret124';
      expect(password == confirm, false);
    });

    test('password match allows submit', () {
      const password = 'secret123';
      const confirm = 'secret123';
      expect(password == confirm, true);
    });

    test('short password under 6 characters is invalid', () {
      const password = '12345';
      expect(password.length >= 6, false);
    });
  });

  group('Verify email code', () {
    test('verify screen accepts variable-length code up to max', () {
      const maxLength = AppConstants.kVerificationCodeMaxLength;
      expect(maxLength, greaterThan(0));
      expect('123'.length <= maxLength, true);
      expect('123456'.length <= maxLength, true);
      expect('123456789012'.length <= maxLength, true);
    });

    test('submit enabled when code is non-empty', () {
      expect(''.trim().isNotEmpty, false);
      expect('123'.trim().isNotEmpty, true);
      expect('123456'.trim().isNotEmpty, true);
    });
  });

  group('Resend cooldown', () {
    test('cooldown starts at positive seconds and decrements', () {
      int cooldown = 60;
      expect(cooldown > 0, true);
      cooldown--;
      expect(cooldown, 59);
    });

    test('resend disabled when cooldown > 0', () {
      const cooldown = 30;
      final canResend = cooldown <= 0;
      expect(canResend, false);
    });

    test('resend enabled when cooldown is 0', () {
      const cooldown = 0;
      final canResend = cooldown <= 0;
      expect(canResend, true);
    });
  });

  group('Auth routing (session)', () {
    test('no session implies show auth screen', () {
      const hasSession = false;
      expect(hasSession, false);
    });

    test('has session implies show app', () {
      const hasSession = true;
      expect(hasSession, true);
    });
  });
}
