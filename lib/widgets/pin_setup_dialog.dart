import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef PinSetupResult = ({bool success, String? pin});

class PinSetupDialog extends StatefulWidget {
  final String title;
  final String confirmTitle;

  const PinSetupDialog({
    super.key,
    this.title = 'Enter 4-digit PIN',
    this.confirmTitle = 'Confirm PIN',
  });

  static Future<PinSetupResult?> show(BuildContext context) {
    return showDialog<PinSetupResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PinSetupDialog(),
    );
  }

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  final List<int> _digits = [];
  String? _firstPin;
  String? _error;
  bool _isConfirmStep = false;
  static const int _pinLength = 4;

  void _onDigit(int digit) {
    if (_digits.length >= _pinLength) return;
    setState(() {
      _digits.add(digit);
      _error = null;
    });
    if (_digits.length == _pinLength) _onComplete();
  }

  void _onBackspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits.removeLast());
  }

  void _onComplete() {
    final pin = _digits.join();
    if (_firstPin == null) {
      setState(() {
        _firstPin = pin;
        _digits.clear();
        _isConfirmStep = true;
      });
    } else {
      if (pin != _firstPin) {
        setState(() {
          _digits.clear();
          _error = 'PINs do not match';
        });
        HapticFeedback.vibrate();
      } else {
        Navigator.of(context).pop((success: true, pin: pin));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isConfirmStep ? widget.confirmTitle : widget.title;
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pinLength, (i) {
              final filled = i < _digits.length;
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
          const SizedBox(height: 24),
          _buildNumpad(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop((success: false, pin: null)),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildNumpad() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [1, 2, 3].map((d) => _digitBtn(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [4, 5, 6].map((d) => _digitBtn(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [7, 8, 9].map((d) => _digitBtn(d)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 64, height: 48),
            _digitBtn(0),
            IconButton(
              icon: const Icon(Icons.backspace_outlined),
              onPressed: _onBackspace,
            ),
          ],
        ),
      ],
    );
  }

  Widget _digitBtn(int d) {
    return SizedBox(
      width: 64,
      height: 48,
      child: ElevatedButton(
        onPressed: () => _onDigit(d),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text('$d', style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
