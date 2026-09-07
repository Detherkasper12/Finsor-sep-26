import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Observability: crash reporting + usage events
/// No PII, no transaction data
/// Disabled when DSN empty or in debug
class ObservabilityService {
  static bool _initialized = false;
  static bool _enabled = false;

  static bool get isEnabled => _enabled;

  /// Run app with optional Sentry - call from main.dart
  /// When dsn is empty or debug, runs appRunner directly
  static Future<void> runApp(String? dsn, void Function() appRunner) async {
    if (_initialized) {
      appRunner();
      return;
    }
    _initialized = true;

    final effectiveDsn = dsn ?? const String.fromEnvironment(
      'SENTRY_DSN',
      defaultValue: '',
    );
    if (effectiveDsn.isEmpty || kDebugMode) {
      _enabled = false;
      appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = effectiveDsn;
        options.tracesSampleRate = 0.1;
        options.environment = kReleaseMode ? 'production' : 'debug';
        options.sendDefaultPii = false;
        options.attachStacktrace = true;
      },
      appRunner: appRunner,
    );
    _enabled = true;
  }

  /// Capture exception (call from catch blocks)
  static Future<void> captureException(
    dynamic exception,
    StackTrace? stackTrace, {
    Map<String, dynamic>? extras,
  }) async {
    if (!_enabled) return;
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (extras != null) {
          for (final e in extras.entries) {
            scope.setExtra(e.key, e.value);
          }
        }
      },
    );
  }

  /// Capture message (for non-exception errors)
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.warning,
  }) async {
    if (!_enabled) return;
    await Sentry.captureMessage(message, level: level);
  }

  /// Set user context (no PII - e.g. premium/free only)
  static void setContext(String key, Map<String, dynamic> value) {
    if (!_enabled) return;
    Sentry.configureScope((scope) => scope.setContexts(key, value));
  }

  /// Add breadcrumb for debugging
  static void addBreadcrumb(String message, {Map<String, dynamic>? data}) {
    if (!_enabled) return;
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      data: data,
      timestamp: DateTime.now(),
    ));
  }

  /// Fire usage event (fire-and-forget)
  static void trackEvent(String name, {Map<String, String>? attributes}) {
    if (!_enabled) return;
    addBreadcrumb('event: $name', data: attributes != null ? Map<String, dynamic>.from(attributes) : null);
    Sentry.captureMessage('event:$name', level: SentryLevel.info);
  }

  static void trackAppStart() => trackEvent('app_start');
  static void trackOnboardingCompleted() => trackEvent('onboarding_completed');
  static void trackPremiumUpgradeAttempt() => trackEvent('premium_upgrade_attempt');
  static void trackPremiumPurchaseSuccess() => trackEvent('premium_purchase_success');
  static void trackPremiumPurchaseFailure({String? reason}) =>
      trackEvent('premium_purchase_failure', attributes: reason != null ? {'reason': reason} : null);
  static void trackAiInsightViewed() => trackEvent('ai_insight_viewed');
  static void trackExportAttempted() => trackEvent('export_attempted');
}
