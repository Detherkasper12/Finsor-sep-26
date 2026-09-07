import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
});

final authServiceProvider = Provider<AuthService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return AuthService(client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  if (authService == null) return const Stream.empty();
  return authService.authStateChanges;
});

/// Single source of truth: recomputes when auth stream emits (SIGNED_IN / SIGNED_OUT).
final isAuthenticatedProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  try {
    return ref.read(authServiceProvider)?.isAuthenticated ?? false;
  } catch (_) {
    return false;
  }
});

/// Current session or null. Reactive to auth state changes.
final sessionOrNullProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider);
  try {
    return Supabase.instance.client.auth.currentSession;
  } catch (_) {
    return null;
  }
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  try {
    return ref.read(authServiceProvider)?.currentUser;
  } catch (_) {
    return null;
  }
});

final userIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.id;
});

final userEmailProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.email;
});

/// Set to true when auth state is PASSWORD_RECOVERY; clear after user sets new password.
final recoverySessionPendingProvider = StateProvider<bool>((ref) => false);
