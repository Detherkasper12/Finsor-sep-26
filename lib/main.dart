import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/env.dart';
import 'services/observability_service.dart';
import 'services/storage_service.dart';
import 'services/hive_database_service.dart';
import 'services/recurring_service.dart';

final Stopwatch _coldStartTimer = Stopwatch();

void main() async {
  _coldStartTimer.start();
  WidgetsFlutterBinding.ensureInitialized();
  final bindingTime = _coldStartTimer.elapsedMilliseconds;

  if (kDebugMode) {
    WidgetsApp.debugAllowBannerOverride = false;
  }

  await Hive.initFlutter();
  final hiveInitTime = _coldStartTimer.elapsedMilliseconds;
  debugPrint('[ColdStart] Hive.initFlutter: ${hiveInitTime - bindingTime}ms');

  await HiveDatabaseService.instance.init();
  final dbInitTime = _coldStartTimer.elapsedMilliseconds;
  debugPrint('[ColdStart] HiveDatabaseService.init: ${dbInitTime - hiveInitTime}ms');

  await StorageService.init();
  final storageTime = _coldStartTimer.elapsedMilliseconds;

  final recurringService = RecurringService(HiveDatabaseService.instance);
  await recurringService.generateDueTransactions();
  final recurringTime = _coldStartTimer.elapsedMilliseconds;
  debugPrint('[ColdStart] RecurringService: ${recurringTime - storageTime}ms');

  // Load environment and initialize Supabase
  await Env.load();
  final _safeUrl = Env.supabaseUrl ?? 'null';
  final _safeKey = Env.anonKey;
  final _keyTail = _safeKey != null && _safeKey.length >= 6
      ? '****${_safeKey.substring(_safeKey.length - 6)}'
      : 'null';
  debugPrint('[ENV] ${Env.envName} configured=${Env.isConfigured}'
      ' url=$_safeUrl anon=$_keyTail');

  if (Env.isConfigured) {
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl!,
        anonKey: Env.anonKey!,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: true,
        ),
      );
      debugPrint('[ColdStart] Supabase initialized (${Env.envName}) — session persisted by default, autoRefreshToken=true');

      final appLinks = AppLinks();
      final uri = await appLinks.getInitialLink();
      if (uri != null &&
          uri.scheme == 'io.supabase.finsor' &&
          (uri.host == 'reset-password' ||
              uri.host == 'auth-callback' ||
              uri.host == 'login-callback')) {
        try {
          await Supabase.instance.client.auth.getSessionFromUrl(uri);
          debugPrint('[ColdStart] Recovered session from deep link: ${uri.host}');
        } catch (e) {
          debugPrint('[ColdStart] getSessionFromUrl failed: $e');
        }
      }
    } catch (e) {
      debugPrint('[ColdStart] Supabase init FAILED: $e — continuing offline');
    }
  }

  final supabaseTime = _coldStartTimer.elapsedMilliseconds;
  debugPrint('[ColdStart] Total pre-runApp: ${supabaseTime}ms');

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  await ObservabilityService.runApp(null, () {
    ObservabilityService.trackAppStart();
    runApp(
      const ProviderScope(
        child: FinsorApp(),
      ),
    );
  });
}
