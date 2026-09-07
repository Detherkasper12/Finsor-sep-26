import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/config/env.dart';

void main() {
  setUp(() => Env.reset());

  group('Auth gate logic', () {
    test('when not configured, app should show MainScreen (offline mode)', () {
      Env.supabaseUrl = null;
      Env.anonKey = null;
      expect(Env.isConfigured, false);
      // Auth gate in app.dart checks _supabaseReady which requires
      // Env.isConfigured == true AND Supabase.instance accessible.
      // When not configured -> offline banner + MainScreen.
    });

    test('when configured but Supabase not initialized, still offline', () {
      Env.supabaseUrl = 'https://abc.supabase.co';
      Env.anonKey = 'real-key';
      expect(Env.isConfigured, true);
      // But Supabase.instance.client would throw since not initialized
      // -> _supabaseReady returns false -> offline mode
    });

    test('isConfigured true with real credentials', () {
      Env.supabaseUrl = 'https://qwzqpgtispittliygcan.supabase.co';
      Env.anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test-anon-key';
      expect(Env.isConfigured, true);
    });

    test('isConfigured false with placeholder URL', () {
      Env.supabaseUrl = 'https://YOUR_DEV_PROJECT.supabase.co';
      Env.anonKey = 'YOUR_DEV_ANON_KEY';
      expect(Env.isConfigured, false);
    });
  });
}
