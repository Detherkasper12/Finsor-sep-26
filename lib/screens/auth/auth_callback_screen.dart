import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shown briefly after OAuth redirect on web.
/// supabase_flutter auto-recovers the session from the URL fragment.
/// This screen just displays a spinner while that happens.
/// The auth gate in app.dart will swap to MainScreen once the session is detected.
class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  String? _error;
  bool _didNavigate = false;

  void _navigateHome() {
    if (_didNavigate || !mounted) return;
    _didNavigate = true;
    if (kDebugMode) {
      debugPrint('[AuthCallback] Navigating to / (post-frame)');
    }
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleCallback();
    });
  }

  Future<void> _handleCallback() async {
    try {
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      if (session != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _navigateHome());
        return;
      }
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      final sessionAfterWait = client.auth.currentSession;
      if (sessionAfterWait != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _navigateHome());
      } else {
        setState(() => _error = 'No session found. Try signing in again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Auth callback error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateHome());
                    },
                    child: const Text('Back to app'),
                  ),
                ],
              )
            : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Completing sign-in...'),
                ],
              ),
      ),
    );
  }
}
