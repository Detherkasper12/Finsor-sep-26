import 'package:flutter/foundation.dart';

/// Dev-only app config. Flip flags to re-enable features temporarily turned off.
class AppConfig {
  static const bool skipOnboarding = kDebugMode;

  /// When false: AuthGate skips Sign-in, drawer/settings hide account CTAs.
  /// Set true again when Google Sign-In (or email auth) is ready.
  static const bool authEnabled = false;

  /// Google Sign-In is paused — keep false until Google OAuth is re-enabled.
  static const bool googleSignInEnabled = false;
}
