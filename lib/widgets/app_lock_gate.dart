import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';

const _pinKey = 'app_lock_pin_hash';
const _pinSalt = 'finsor_pin_salt_v1';

Future<String?> _getStoredPinHash() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_pinKey);
}

Future<void> _setStoredPinHash(String hash) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_pinKey, hash);
}

Future<void> _clearStoredPinHash() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_pinKey);
}

Future<bool> setAppPin(String pin) async {
  if (pin.length != 4) return false;
  await _setStoredPinHash(_hashPin(pin));
  return true;
}

Future<void> clearAppPin() => _clearStoredPinHash();

String _hashPin(String pin) {
  final bytes = utf8.encode('$_pinSalt$pin');
  return sha256.convert(bytes).toString();
}

bool _verifyPin(String pin, String storedHash) => _hashPin(pin) == storedHash;

final hasPinSetProvider = FutureProvider<bool>((ref) async {
  final hash = await _getStoredPinHash();
  return hash != null && hash.isNotEmpty;
});

class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  DateTime? _lastBackgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _lastBackgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _checkLock();
    }
  }

  Future<void> _checkLock() async {
    final settings = await ref.read(settingsProvider.future);
    if (!settings.requirePinForAccess) {
      setState(() => _isLocked = false);
      return;
    }
    final hasPin = await ref.read(hasPinSetProvider.future);
    if (!hasPin) {
      setState(() => _isLocked = false);
      return;
    }
    if (_lastBackgroundTime != null) {
      final elapsed =
          DateTime.now().difference(_lastBackgroundTime!).inSeconds;
      final timeout = settings.autoLockTimeout;
      if (elapsed >= timeout) {
        setState(() => _isLocked = true);
      }
    }
  }

  void _onUnlocked() {
    setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) return widget.child;
    return _PinLockScreen(onUnlocked: _onUnlocked);
  }
}

class _PinLockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;

  const _PinLockScreen({required this.onUnlocked});

  @override
  ConsumerState<_PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<_PinLockScreen> {
  final List<int> _enteredDigits = [];
  String? _error;
  bool _useBiometrics = false;

  static const int _pinLength = 4;

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      final settings = await ref.read(settingsProvider.future);
      if (canCheck && settings.useBiometrics) {
        setState(() => _useBiometrics = true);
        final authenticated = await auth.authenticate(
          localizedReason: 'Unlock Finsor',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (authenticated && mounted) widget.onUnlocked();
      }
    } catch (_) {}
  }

  void _onDigit(int digit) {
    if (_enteredDigits.length >= _pinLength) return;
    setState(() {
      _enteredDigits.add(digit);
      _error = null;
    });
    if (_enteredDigits.length == _pinLength) _verify();
  }

  void _onBackspace() {
    if (_enteredDigits.isEmpty) return;
    setState(() => _enteredDigits.removeLast());
  }

  Future<void> _verify() async {
    final pin = _enteredDigits.join();
    final hash = await _getStoredPinHash();
    if (hash == null || !_verifyPin(pin, hash)) {
      setState(() {
        _enteredDigits.clear();
        _error = 'Wrong PIN';
      });
      HapticFeedback.vibrate();
      return;
    }
    widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              'Enter PIN',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final filled = i < _enteredDigits.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 48),
            if (_useBiometrics)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: IconButton(
                  icon: const Icon(Icons.fingerprint, size: 48),
                  onPressed: _tryBiometric,
                ),
              ),
            _buildNumpad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [1, 2, 3].map((d) => _digitButton(d)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [4, 5, 6].map((d) => _digitButton(d)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [7, 8, 9].map((d) => _digitButton(d)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 64),
              _digitButton(0),
              IconButton(
                icon: const Icon(Icons.backspace_outlined),
                onPressed: _onBackspace,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _digitButton(int digit) {
    return SizedBox(
      width: 64,
      height: 64,
      child: ElevatedButton(
        onPressed: () => _onDigit(digit),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Text('$digit', style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
