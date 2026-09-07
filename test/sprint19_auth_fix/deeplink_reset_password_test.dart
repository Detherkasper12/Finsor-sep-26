import 'package:flutter_test/flutter_test.dart';

bool isAuthDeepLink(Uri uri) {
  return uri.scheme == 'io.supabase.finsor' &&
      (uri.host == 'reset-password' ||
          uri.host == 'auth-callback' ||
          uri.host == 'login-callback');
}

String? deepLinkScreen(Uri uri) {
  if (!isAuthDeepLink(uri)) return null;
  if (uri.host == 'reset-password') return 'ResetPasswordScreen';
  if (uri.host == 'auth-callback' || uri.host == 'login-callback') return 'AuthCallbackScreen';
  return null;
}

void main() {
  group('Deep link parsing (Sprint 19.1)', () {
    test('reset-password URI is recognized as auth deep link', () {
      final uri = Uri.parse('io.supabase.finsor://reset-password');
      expect(isAuthDeepLink(uri), true);
      expect(deepLinkScreen(uri), 'ResetPasswordScreen');
    });

    test('auth-callback URI is recognized', () {
      final uri = Uri.parse('io.supabase.finsor://auth-callback');
      expect(isAuthDeepLink(uri), true);
      expect(deepLinkScreen(uri), 'AuthCallbackScreen');
    });

    test('login-callback URI is recognized', () {
      final uri = Uri.parse('io.supabase.finsor://login-callback');
      expect(isAuthDeepLink(uri), true);
      expect(deepLinkScreen(uri), 'AuthCallbackScreen');
    });

    test('wrong scheme is not recognized', () {
      final uri = Uri.parse('https://example.com/reset-password');
      expect(isAuthDeepLink(uri), false);
      expect(deepLinkScreen(uri), isNull);
    });

    test('wrong host is not recognized', () {
      final uri = Uri.parse('io.supabase.finsor://other');
      expect(isAuthDeepLink(uri), false);
      expect(deepLinkScreen(uri), isNull);
    });
  });
}
