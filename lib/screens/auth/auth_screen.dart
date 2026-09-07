import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/env.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import 'verify_email_code_screen.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  String? _error;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _runSmokeCheck() async {
    try {
      await Supabase.instance.client
          .from('wallets')
          .select('id')
          .limit(1);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('relation') || msg.contains('does not exist') && mounted) {
        final ref = Env.envName == 'prod'
            ? 'bnvcznkfmnyqzoniwioc'
            : 'qwzqpgtispittliygcan';
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Database not migrated'),
            content: Text(
              'The Supabase database tables are missing.\n\n'
              'Run in your terminal:\n'
              '  supabase link --project-ref $ref\n'
              '  supabase db push\n\n'
              'Then restart the app.',
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
    }
  }

  void _showRedirectMismatchHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Google redirect URI mismatch'),
        content: const Text(
          'The redirect URI configured in Google Cloud Console does not '
          'match the Supabase callback URL.\n\n'
          'See docs/auth_google_setup.md for the correct URIs.',
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

  void _clearError() => setState(() => _error = null);

  void _onAuthSuccess() {
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed in')));
    } else {
      _runSmokeCheck();
    }
  }

  void _onAuthFailure(String? message) {
    if (!mounted) return;
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _handleGoogle() async {
    setState(() { _loading = true; _error = null; });
    final auth = ref.read(authServiceProvider);
    if (auth == null) {
      setState(() { _loading = false; _error = 'Auth not available'; });
      _onAuthFailure('Auth not available');
      return;
    }
    final result = await auth.signInWithGoogle();
    if (!mounted) return;
    setState(() { _loading = false; _error = result.success ? null : result.error; });
    if (result.success && result.user != null) {
      _onAuthSuccess();
    } else {
      if (result.error != null) _onAuthFailure(result.error);
      if (result.error?.contains('redirect_uri_mismatch') == true) _showRedirectMismatchHelp();
    }
  }

  Future<void> _handleApple() async {
    setState(() { _loading = true; _error = null; });
    final auth = ref.read(authServiceProvider);
    if (auth == null) {
      setState(() { _loading = false; _error = 'Auth not available'; });
      _onAuthFailure('Auth not available');
      return;
    }
    final result = await auth.signInWithApple();
    if (!mounted) return;
    setState(() { _loading = false; _error = result.success ? null : result.error; });
    if (result.success) {
      _onAuthSuccess();
    } else if (result.error != null) {
      _onAuthFailure(result.error);
    }
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Enter your password');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final auth = ref.read(authServiceProvider);
    if (auth == null) {
      setState(() { _loading = false; _error = 'Auth not available'; });
      return;
    }
    final result = await auth.signInWithEmailPassword(email, password);
    if (!mounted) return;
    setState(() { _loading = false; _error = result.success ? null : result.error; });
    if (result.success) {
      _onAuthSuccess();
    } else if (result.error != null) {
      _onAuthFailure(result.error);
    }
  }

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final auth = ref.read(authServiceProvider);
    if (auth == null) {
      setState(() { _loading = false; _error = 'Auth not available'; });
      return;
    }
    final result = await auth.signUpWithEmailPassword(email, password);
    if (!mounted) return;
    setState(() { _loading = false; _error = result.success ? null : result.error; });
    if (result.success && result.user != null) {
      if (result.needsEmailVerification) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerifyEmailCodeScreen(email: email),
          ),
        );
      } else {
        _onAuthSuccess();
      }
    } else if (result.error != null) {
      _onAuthFailure(result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showApple = AuthService.showApple;
    final showGoogle = AuthService.showGoogle;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.account_balance_wallet,
                      size: 56, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 24),
                Text(AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Sign in or create an account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (_) => _clearError(),
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    indicator: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    tabs: const [
                      Tab(text: 'Sign in'),
                      Tab(text: 'Sign up'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer)),
                  ),
                  const SizedBox(height: 16),
                ],
                if (showApple)
                  _AuthButton(
                    icon: Icons.apple,
                    label: 'Continue with Apple',
                    onTap: _loading ? null : _handleApple,
                    dark: true,
                  ),
                if (showGoogle) ...[
                  if (showApple) const SizedBox(height: 12),
                  _AuthButton(
                    icon: Icons.g_mobiledata,
                    label: 'Continue with Google',
                    onTap: _loading ? null : _handleGoogle,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or use email',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 320,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _SignInForm(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        loading: _loading,
                        onSignIn: _handleSignIn,
                        onForgotPassword: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                      ),
                      _SignUpForm(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        confirmPasswordController: _confirmPasswordController,
                        loading: _loading,
                        onSignUp: _handleSignUp,
                      ),
                    ],
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

class _SignInForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool loading;
  final VoidCallback onSignIn;
  final VoidCallback onForgotPassword;

  const _SignInForm({
    required this.emailController,
    required this.passwordController,
    required this.loading,
    required this.onSignIn,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'you@example.com',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSignIn(),
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: loading ? null : onForgotPassword,
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: loading ? null : onSignIn,
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Sign in'),
          ),
        ),
      ],
    );
  }
}

class _SignUpForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool loading;
  final VoidCallback onSignUp;

  const _SignUpForm({
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.loading,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'you@example.com',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: true,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'At least 6 characters',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: confirmPasswordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSignUp(),
          decoration: InputDecoration(
            labelText: 'Confirm password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'By continuing you agree to our Terms of Service and Privacy Policy.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: loading ? null : onSignUp,
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Create account'),
          ),
        ),
      ],
    );
  }
}

class _AuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool dark;

  const _AuthButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: dark
          ? FilledButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 24),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 24),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
    );
  }
}
