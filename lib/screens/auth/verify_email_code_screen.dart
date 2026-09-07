import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/env.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';

class VerifyEmailCodeScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyEmailCodeScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailCodeScreen> createState() =>
      _VerifyEmailCodeScreenState();
}

class _VerifyEmailCodeScreenState extends ConsumerState<VerifyEmailCodeScreen> {
  bool _loading = false;
  String? _error;
  final _codeController = TextEditingController();
  int _resendCooldown = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendCooldown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) t.cancel();
      });
    });
  }

  Future<void> _runSmokeCheck() async {
    try {
      await Supabase.instance.client
          .from('wallets')
          .select('id')
          .limit(1);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('relation') || msg.contains('does not exist')) {
        if (!mounted) return;
        final ref = Env.envName == 'prod'
            ? 'bnvcznkfmnyqzoniwioc'
            : 'qwzqpgtispittliygcan';
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Database not migrated'),
            content: Text(
              'Run: supabase link --project-ref $ref && supabase db push',
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

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter the code from your email');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final auth = ref.read(authServiceProvider);
    if (auth == null) {
      setState(() { _loading = false; _error = 'Auth not available'; });
      return;
    }
    final result = await auth.verifySignupCode(widget.email, code);
    if (!mounted) return;
    setState(() { _loading = false; _error = result.success ? null : result.error; });
    if (result.success) {
      await _runSmokeCheck();
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).popUntil((r) => r.isFirst);
      });
    }
  }

  Future<void> _handleResend() async {
    setState(() { _error = null; });
    final auth = ref.read(authServiceProvider);
    if (auth == null) return;
    final result = await auth.resendSignupCode(widget.email);
    if (!mounted) return;
    if (result.success) {
      _startResendCooldown();
    } else {
      setState(() => _error = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _codeController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Verify your email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the code sent to ${widget.email}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: AppConstants.kVerificationCodeMaxLength,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(
                      AppConstants.kVerificationCodeMaxLength),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Verification code',
                  hintText: 'Enter code',
                  counterText: '',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed:
                      (_loading || !canSubmit) ? null : _handleVerify,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verify'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _resendCooldown > 0 || _loading
                        ? null
                        : _handleResend,
                    child: Text(
                      _resendCooldown > 0
                          ? 'Resend code (${_resendCooldown}s)'
                          : 'Resend code',
                    ),
                  ),
                  const Text(' | '),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Change email'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
