import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Returns current session or null. Safe to call when Supabase not configured.
Session? getSessionOrNull() {
  try {
    return Supabase.instance.client.auth.currentSession;
  } catch (_) {
    return null;
  }
}

/// If no session: shows "Please sign in" and returns false. Otherwise returns true.
bool requireAuthOrShowPrompt(BuildContext context) {
  if (!AppConfig.authEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign-in is temporarily unavailable.')),
    );
    return false;
  }
  if (getSessionOrNull() != null) return true;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Please sign in to use this feature.')),
  );
  return false;
}
