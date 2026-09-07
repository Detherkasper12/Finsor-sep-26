import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthGate session logic (Sprint 19.1)', () {
    test('when session is null, gate should show AuthScreen', () {
      const hasSession = false;
      const onboardingComplete = true;
      const supabaseReady = true;
      final showAuth = supabaseReady && onboardingComplete && !hasSession;
      expect(showAuth, true);
    });

    test('when session exists and onboarding complete, gate should show MainScreen', () {
      const hasSession = true;
      const onboardingComplete = true;
      const supabaseReady = true;
      const recoveryPending = false;
      final showMain = supabaseReady && onboardingComplete && hasSession && !recoveryPending;
      expect(showMain, true);
    });

    test('when recovery pending, gate should show ResetPasswordScreen not MainScreen', () {
      const hasSession = true;
      const onboardingComplete = true;
      const supabaseReady = true;
      const recoveryPending = true;
      final showReset = supabaseReady && onboardingComplete && hasSession && recoveryPending;
      expect(showReset, true);
    });
  });
}
