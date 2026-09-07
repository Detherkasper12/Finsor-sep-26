import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/config/env.dart';

void main() {
  setUp(() => Env.reset());

  group('Offline mode', () {
    test('Env not configured -> isConfigured false', () {
      expect(Env.isConfigured, false);
      // In this state, app.dart _supabaseReady returns false
      // -> shows MainScreen wrapped with offline MaterialBanner
    });

    test('Env with empty values -> isConfigured false', () {
      Env.supabaseUrl = '';
      Env.anonKey = '';
      expect(Env.isConfigured, false);
    });

    test('load with missing file does not crash', () async {
      await Env.load(env: 'missing_env_that_does_not_exist');
      expect(Env.isConfigured, false);
      expect(Env.loaded, true);
      expect(Env.envName, 'missing_env_that_does_not_exist');
    });

    test('looksPlaceholder rejects REPLACE_ME', () {
      expect(Env.looksPlaceholder('REPLACE_ME_WITH_KEY'), true);
    });

    test('after failed load, requireConfigured throws', () async {
      await Env.load(env: 'nonexistent');
      expect(() => Env.requireConfigured(), throwsStateError);
    });

    test('reset clears all state', () {
      Env.supabaseUrl = 'https://abc.supabase.co';
      Env.anonKey = 'key';
      Env.envName = 'prod';
      Env.deviceId = 'device-123';
      expect(Env.isConfigured, true);

      Env.reset();
      expect(Env.isConfigured, false);
      expect(Env.supabaseUrl, isNull);
      expect(Env.anonKey, isNull);
      expect(Env.envName, 'dev');
      expect(Env.deviceId, '');
    });
  });
}
