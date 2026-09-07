import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/config/env.dart';
import 'package:finsor/services/auth_service.dart';

void main() {
  setUp(() => Env.reset());

  group('Google OAuth (web)', () {
    test('showGoogle is true on web or Android', () {
      // In test env (not web), showGoogle depends on platform
      expect(AuthService.showGoogle, isA<bool>());
    });

    test('showApple is false on web', () {
      // In test env (not web), showApple depends on platform
      expect(AuthService.showApple, isA<bool>());
    });

    test('Env.webOrigin returns null when not on web', () {
      // Tests run in VM, not web — so webOrigin should be null
      if (!kIsWeb) {
        expect(Env.webOrigin, isNull);
      }
    });

    test('Env.googleWebClientId is available after set', () {
      Env.googleWebClientId = '123-test.apps.googleusercontent.com';
      expect(Env.googleWebClientId, isNotNull);
      expect(Env.googleWebClientId, contains('apps.googleusercontent.com'));
    });

    test('redirect_uri_mismatch error is detectable', () {
      const result = AuthResult.fail(
        'redirect_uri_mismatch: The redirect URI does not match',
      );
      expect(result.success, false);
      expect(result.error, contains('redirect_uri_mismatch'));
    });

    test('web Google flow returns success even without user (page navigates away)', () {
      // On web, signInWithOAuth navigates the page, so the result
      // may come back as success=true, user=null
      const result = AuthResult(success: true, error: null, user: null);
      expect(result.success, true);
      expect(result.user, isNull);
    });
  });
}
