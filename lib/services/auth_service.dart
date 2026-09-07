import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../config/env.dart';

enum AuthProvider { apple, google, email }

class AuthResult {
  final bool success;
  final String? error;
  final User? user;
  final bool needsEmailVerification;

  const AuthResult({
    required this.success,
    this.error,
    this.user,
    this.needsEmailVerification = false,
  });
  const AuthResult.ok(this.user)
      : success = true, error = null, needsEmailVerification = false;
  const AuthResult.fail(this.error)
      : success = false, user = null, needsEmailVerification = false;
}

class AuthService {
  final SupabaseClient _client;
  AuthService(this._client);

  User? get currentUser => _client.auth.currentUser;
  String? get userId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;
  String? get userEmail => currentUser?.email;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Apple (native only) ──

  Future<AuthResult> signInWithApple() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: _nativeRedirectUrl,
      );
      final user = _client.auth.currentUser;
      return user != null
          ? AuthResult.ok(user)
          : const AuthResult.fail('Apple sign-in was cancelled');
    } catch (e) {
      debugPrint('[Auth] Apple sign-in error: $e');
      return AuthResult.fail(_mapAuthError(e));
    }
  }

  // ── Google ──

  Future<AuthResult> signInWithGoogle() async {
    if (kIsWeb) return _signInWithGoogleWeb();
    return _signInWithGoogleNative();
  }

  Future<AuthResult> _signInWithGoogleWeb() async {
    try {
      final origin = Env.webOrigin;
      final redirectTo = origin != null ? '$origin/#/auth-callback' : null;

      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      );
      final user = _client.auth.currentUser;
      return user != null
          ? AuthResult.ok(user)
          : const AuthResult(success: true, error: null, user: null);
    } catch (e) {
      final msg = e.toString();
      debugPrint('[Auth] Google web sign-in error: $msg');
      if (msg.contains('redirect_uri_mismatch')) {
        return const AuthResult.fail(
          'redirect_uri_mismatch: The redirect URI in Google Cloud Console '
          'does not match the Supabase callback URL. '
          'See docs/auth_google_setup.md for the correct URIs.',
        );
      }
      return AuthResult.fail(_mapAuthError(e));
    }
  }

  Future<AuthResult> _signInWithGoogleNative() async {
    try {
      const iosClientId = String.fromEnvironment(
        'GOOGLE_IOS_CLIENT_ID',
        defaultValue: '',
      );
      final webClientId = Env.googleWebClientId ?? '';

      final googleSignIn = GoogleSignIn(
        clientId: iosClientId.isNotEmpty ? iosClientId : null,
        serverClientId: webClientId.isNotEmpty ? webClientId : null,
      );

      try {
        await googleSignIn.signOut();
      } catch (_) {}
      try {
        await googleSignIn.disconnect();
      } catch (_) {}

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthResult.fail('Google sign-in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        return const AuthResult.fail('No ID token from Google');
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response.user != null
          ? AuthResult.ok(response.user)
          : const AuthResult.fail('Google sign-in failed');
    } catch (e) {
      debugPrint('[Auth] Google native sign-in error: $e');
      return AuthResult.fail(_mapAuthError(e));
    }
  }

  // ── Email + Password (Sign up / Sign in) ──

  Future<AuthResult> signUpWithEmailPassword(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      if (response.user == null) {
        return AuthResult.fail(
            response.user?.identities?.isEmpty == true
                ? 'An account with this email already exists. Sign in instead.'
                : 'Sign up failed');
      }
      final needsVerification = response.session == null;
      return AuthResult(
        success: true,
        error: null,
        user: response.user,
        needsEmailVerification: needsVerification,
      );
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthException(e));
    } catch (e) {
      debugPrint('[Auth] Sign up error: $e');
      return AuthResult.fail(_mapAuthError(e));
    }
  }

  Future<AuthResult> signInWithEmailPassword(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response.user != null
          ? AuthResult.ok(response.user)
          : const AuthResult.fail('Sign in failed');
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthException(e));
    } catch (e) {
      debugPrint('[Auth] Sign in error: $e');
      return AuthResult.fail(_mapAuthError(e));
    }
  }

  /// Verify signup email with 6-digit code. Use OtpType.signup for signup confirmation.
  Future<AuthResult> verifySignupCode(String email, String code) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email.trim(),
        token: code.trim(),
        type: OtpType.signup,
      );
      return response.user != null
          ? AuthResult.ok(response.user)
          : const AuthResult.fail('Verification failed');
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthException(e));
    } catch (e) {
      debugPrint('[Auth] Verify signup OTP error: $e');
      return AuthResult.fail(_mapAuthError(e));
    }
  }

  /// Resend signup confirmation code to email.
  Future<AuthResult> resendSignupCode(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );
      return const AuthResult(success: true, error: null, user: null);
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthException(e));
    } catch (e) {
      debugPrint('[Auth] Resend signup code error: $e');
      return AuthResult.fail(_mapAuthError(e));
    }
  }

  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return const AuthResult(success: true, error: null, user: null);
    } on AuthException catch (e) {
      return AuthResult.fail(_mapAuthException(e));
    } catch (e) {
      debugPrint('[Auth] Password reset error: $e');
      return AuthResult.fail(_mapAuthError(e));
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.global);
    } catch (e) {
      debugPrint('[Auth] Sign out error: $e');
    }
    if (!kIsWeb) {
      try {
        const iosClientId = String.fromEnvironment(
          'GOOGLE_IOS_CLIENT_ID',
          defaultValue: '',
        );
        final webClientId = Env.googleWebClientId ?? '';
        final googleSignIn = GoogleSignIn(
          clientId: iosClientId.isNotEmpty ? iosClientId : null,
          serverClientId: webClientId.isNotEmpty ? webClientId : null,
        );
        await googleSignIn.signOut();
      } catch (e) {
        debugPrint('[Auth] Google signOut error: $e');
      }
      try {
        const iosClientId = String.fromEnvironment(
          'GOOGLE_IOS_CLIENT_ID',
          defaultValue: '',
        );
        final webClientId = Env.googleWebClientId ?? '';
        final googleSignIn = GoogleSignIn(
          clientId: iosClientId.isNotEmpty ? iosClientId : null,
          serverClientId: webClientId.isNotEmpty ? webClientId : null,
        );
        await googleSignIn.disconnect();
      } catch (e) {
        debugPrint('[Auth] Google disconnect error: $e');
      }
    }
  }

  String? get _nativeRedirectUrl {
    if (kIsWeb) return null;
    return 'io.supabase.finsor://login-callback/';
  }

  static String _mapAuthError(dynamic e) {
    final s = e.toString();
    if (s.contains('Invalid login credentials') || s.contains('invalid_credentials')) {
      return 'Invalid email or password';
    }
    if (s.contains('Email not confirmed')) return 'Please verify your email first';
    if (s.contains('Token') && s.contains('expired')) return 'Code expired. Request a new one.';
    return s;
  }

  static String _mapAuthException(AuthException e) {
    switch (e.message.toLowerCase()) {
      case 'invalid login credentials':
      case 'invalid_credentials':
        return 'Invalid email or password';
      case 'email not confirmed':
        return 'Please verify your email first';
      case 'user already registered':
        return 'An account with this email already exists. Sign in instead.';
      case 'password should be at least 6 characters':
        return 'Password must be at least 6 characters';
      case 'token has expired or is invalid':
        return 'Code expired or invalid. Request a new one.';
    }
    return e.message;
  }

  static bool get showApple {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  static bool get showGoogle {
    if (!AppConfig.googleSignInEnabled) return false;
    if (kIsWeb) return true;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return true;
    }
  }
}
