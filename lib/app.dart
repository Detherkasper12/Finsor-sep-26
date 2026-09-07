import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'config/env.dart';
import 'constants/app_theme.dart';
import 'config/app_config.dart';
import 'constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/database_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/premium_provider.dart';
import 'providers/sync_provider.dart';
import 'models/user_settings.dart' as models;
import 'screens/auth/auth_callback_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'services/hive_database_service.dart';
import 'services/sync_service.dart';
import 'utils/app_localizations.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'widgets/app_lock_gate.dart';

/// Enhanced splash screen with animations
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryLight,
              AppTheme.primaryDark,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appTagline,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Main application widget
class FinsorApp extends ConsumerWidget {
  const FinsorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final databaseInit = ref.watch(databaseInitProvider);
    final settings = ref.watch(settingsProvider);

    ref.listen(databaseInitProvider, (_, next) {
      next.whenData((_) {
        ref.read(premiumStateProvider.notifier).refreshPremiumState();
      });
    });

    final locale = settings.when(
      data: (userSettings) => AppLocalizations.localeFromCode(userSettings.locale),
      loading: () => const Locale('en'),
      error: (_, __) => const Locale('en'),
    );
    final textDirection = AppLocalizations.isRtl(locale.languageCode)
        ? TextDirection.rtl
        : TextDirection.ltr;
    return MaterialApp(
      key: ValueKey('${locale.languageCode}_${locale.countryCode ?? ""}'),
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: textDirection,
        child: child!,
      ),
      
      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.when(
        data: (userSettings) {
          switch (userSettings.themeMode) {
            case models.ThemeMode.light:
              return ThemeMode.light;
            case models.ThemeMode.dark:
              return ThemeMode.dark;
            case models.ThemeMode.system:
              return ThemeMode.system;
          }
        },
        loading: () => ThemeMode.system,
        error: (_, __) => ThemeMode.system,
      ),
      
      home: databaseInit.when(
        data: (_) => settings.when(
          data: (_) => const _AppHome(),
          loading: () => const SplashScreen(),
          error: (_, __) => const _AppHome(),
        ),
        loading: () => const SplashScreen(),
        error: (_, __) => const SplashScreen(),
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/auth-callback') {
          return MaterialPageRoute(
            builder: (_) => const AuthCallbackScreen(),
          );
        }
        if (settings.name == '/reset-password') {
          return MaterialPageRoute(
            builder: (_) => const ResetPasswordScreen(),
          );
        }
        return null;
      },
    );
  }
}

/// App home with onboarding check
class _AppHome extends ConsumerStatefulWidget {
  const _AppHome();

  @override
  ConsumerState<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends ConsumerState<_AppHome> {
  bool _syncInitialized = false;
  bool _bannerDismissed = false;

  bool get _supabaseReady {
    if (!Env.isConfigured) return false;
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _initSync() {
    if (_syncInitialized) return;
    if (!_supabaseReady) return;
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser != null) {
        final db = HiveDatabaseService.instance;
        final syncService = SyncService(client, db, onSyncComplete: () {
          if (mounted) {
            ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
            ref.read(lastSyncAtProvider.notifier).state = DateTime.now();
            ref.read(pendingOpsCountProvider.notifier).state = db.pendingOpsCount;
            ref.invalidate(settingsProvider);
          }
        });
        ref.read(syncServiceProvider.notifier).state = syncService;
        ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
        ref.read(pendingOpsCountProvider.notifier).state = db.pendingOpsCount;

        if (kDebugMode) {
          debugPrint('[Sync] Starting after login: user=${client.auth.currentUser?.id}');
        }
        syncService.bootstrap().then((_) {
          if (mounted) ref.read(pendingOpsCountProvider.notifier).state = db.pendingOpsCount;
          syncService.subscribeRealtime();
          syncService.sync();
        });

        _syncInitialized = true;
      }
    } catch (_) {}
  }

  void _showHowToFix() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('How to configure sync'),
        content: const Text(
          '1. Create .env.dev (or .env.prod) in the project root.\n'
          '2. Add:\n'
          '   SUPABASE_URL=https://<project>.supabase.co\n'
          '   SUPABASE_ANON_KEY=<anon-key>\n'
          '   ENV_NAME=dev\n'
          '3. Run with --dart-define=ENV=dev\n'
          '4. Restart the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _wrapWithOfflineBanner(Widget child) {
    if (_bannerDismissed || _supabaseReady || Env.isConfigured) return child;
    return Column(
      children: [
        MaterialBanner(
          content: const Text('Offline mode (Supabase not configured)'),
          leading: const Icon(Icons.cloud_off),
          actions: [
            TextButton(
              onPressed: _showHowToFix,
              child: const Text('How to fix'),
            ),
            TextButton(
              onPressed: () => setState(() => _bannerDismissed = true),
              child: const Text('Dismiss'),
            ),
          ],
        ),
        Expanded(child: child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingComplete = AppConfig.skipOnboarding
        ? const AsyncValue.data(true)
        : ref.watch(isOnboardingCompleteProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    ref.listen(databaseInitProvider, (_, next) {
      next.whenData((_) => _initSync());
    });

    ref.listen(authStateProvider, (prev, next) {
      next.whenData((state) {
        if (kDebugMode) {
          final session = Supabase.instance.client.auth.currentSession;
          debugPrint('[Auth] ${state.event.name} currentSession=${session != null ? "set" : "null"}');
        }
        _syncInitialized = false;
        if (state.event == AuthChangeEvent.signedOut) {
          ref.read(syncServiceProvider.notifier).state = null;
          ref.read(syncStatusProvider.notifier).state = SyncStatus.offline;
        }
        if (state.event == AuthChangeEvent.passwordRecovery) {
          ref.read(recoverySessionPendingProvider.notifier).state = true;
        }
        _initSync();
      });
    });

    return AppLockGate(
      child: onboardingComplete.when(
        data: (complete) {
          if (!complete) {
            if (kDebugMode) debugPrint('[AuthGate] Route: OnboardingScreen (onboarding incomplete)');
            return const OnboardingScreen();
          }
          if (!_supabaseReady) {
            if (kDebugMode) debugPrint('[AuthGate] Route: MainScreen (offline banner)');
            return _wrapWithOfflineBanner(const MainScreen());
          }
          if (!AppConfig.authEnabled) {
            if (kDebugMode) debugPrint('[AuthGate] Route: MainScreen (auth disabled)');
            return _wrapWithOfflineBanner(const MainScreen());
          }
          if (!isAuthenticated) {
            if (kDebugMode) debugPrint('[AuthGate] Route: AuthScreen (not authenticated)');
            return const AuthScreen();
          }
          final recoveryPending = ref.watch(recoverySessionPendingProvider);
          if (recoveryPending) {
            if (kDebugMode) debugPrint('[AuthGate] Route: ResetPasswordScreen (recovery)');
            return const ResetPasswordScreen();
          }
          if (kDebugMode) debugPrint('[AuthGate] Route: MainScreen (signed in)');
          return _wrapWithOfflineBanner(const MainScreen());
        },
        loading: () => const SplashScreen(),
        error: (_, __) => _wrapWithOfflineBanner(const MainScreen()),
      ),
    );
  }
}
