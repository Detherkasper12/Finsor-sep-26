import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../services/hive_database_service.dart';

class Env {
  static String? supabaseUrl;
  static String? anonKey;
  static String? googleWebClientId;
  static String envName = 'dev';
  static String deviceId = '';
  static bool _loaded = false;

  static bool get isConfigured =>
      supabaseUrl != null &&
      supabaseUrl!.isNotEmpty &&
      !looksPlaceholder(supabaseUrl!) &&
      anonKey != null &&
      anonKey!.isNotEmpty &&
      !looksPlaceholder(anonKey!) &&
      !looksServiceRole(anonKey!);

  static bool looksPlaceholder(String v) {
    final lower = v.trim().toLowerCase();
    if (lower.isEmpty) return true;
    const markers = ['your_', 'paste_here', 'xxx', 'todo', 'replace_me'];
    for (final m in markers) {
      if (lower.contains(m)) return true;
    }
    if (v.trim().startsWith('https://YOUR')) return true;
    return false;
  }

  static bool looksServiceRole(String v) {
    final lower = v.trim().toLowerCase();
    if (lower.contains('service_role')) return true;
    if (lower.startsWith('sb_secret')) return true;
    return false;
  }

  static void requireConfigured() {
    if (anonKey != null && looksServiceRole(anonKey!)) {
      throw StateError(
        'SECURITY ERROR: You pasted a service_role / secret key.\n'
        'The Flutter client must use the anon (public) key only.\n'
        'Find it in Supabase Dashboard > Settings > API > anon public.',
      );
    }
    if (!isConfigured) {
      throw StateError(
        'Supabase is not configured.\n'
        'Create .env.dev / .env.prod in the project root with:\n'
        '  SUPABASE_URL=https://<project>.supabase.co\n'
        '  SUPABASE_ANON_KEY=<anon-key>\n'
        '  ENV_NAME=dev|prod\n'
        'Then run with --dart-define=ENV=dev or ENV=prod.',
      );
    }
  }

  static Future<void> load({String? env}) async {
    final target = env ??
        const String.fromEnvironment('ENV', defaultValue: 'dev');
    envName = target;

    try {
      await dotenv.load(fileName: '.env.$target');
    } catch (e) {
      debugPrint('[ENV] Could not load .env.$target: $e');
      supabaseUrl = null;
      anonKey = null;
      _loaded = true;
      return;
    }

    supabaseUrl = dotenv.env['SUPABASE_URL'];
    anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    envName = dotenv.env['ENV_NAME'] ?? target;
    googleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];

    if (anonKey != null && looksServiceRole(anonKey!)) {
      debugPrint(
        '[ENV] FATAL: .env.$target contains a service_role / secret key. '
        'Replace SUPABASE_ANON_KEY with the anon public key from '
        'Supabase Dashboard > Settings > API.',
      );
      anonKey = null; // block usage
    }

    _loaded = true;

    try {
      deviceId = await _getOrCreateDeviceId();
    } catch (_) {
      // Hive may not be ready in tests
    }
  }

  static bool get loaded => _loaded;

  static String? get webOrigin {
    if (!kIsWeb) return null;
    final base = Uri.base;
    return '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
  }

  static Future<String> _getOrCreateDeviceId() async {
    final db = HiveDatabaseService.instance;
    final existing = db.getMetadata('device_id');
    if (existing != null) return existing;
    final id = const Uuid().v4();
    await db.setMetadata('device_id', id);
    return id;
  }

  @visibleForTesting
  static void reset() {
    supabaseUrl = null;
    anonKey = null;
    googleWebClientId = null;
    envName = 'dev';
    deviceId = '';
    _loaded = false;
  }
}
