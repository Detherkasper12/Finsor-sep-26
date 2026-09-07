import 'package:flutter/material.dart';
import '../constants/supported_currencies.dart';
import '../models/user_settings.dart';

/// Reusable currency picker with search. Fiat only or fiat+crypto.
class CurrencyPicker extends StatelessWidget {
  final Currency? selected;
  final ValueChanged<Currency> onSelected;
  final bool includeCrypto;
  final String title;

  const CurrencyPicker({
    super.key,
    this.selected,
    required this.onSelected,
    this.includeCrypto = false,
    this.title = 'Choose Currency',
  });

  @override
  Widget build(BuildContext context) {
    return _CurrencyPickerBody(
      selected: selected,
      onSelected: onSelected,
      includeCrypto: includeCrypto,
      title: title,
    );
  }
}

class _CurrencyPickerBody extends StatefulWidget {
  final Currency? selected;
  final ValueChanged<Currency> onSelected;
  final bool includeCrypto;
  final String title;

  const _CurrencyPickerBody({
    this.selected,
    required this.onSelected,
    required this.includeCrypto,
    required this.title,
  });

  @override
  State<_CurrencyPickerBody> createState() => _CurrencyPickerBodyState();
}

class _CurrencyPickerBodyState extends State<_CurrencyPickerBody> {
  String _query = '';

  List<CurrencyInfo> get _filtered {
    final list = widget.includeCrypto
        ? SupportedCurrencies.crypto
        : SupportedCurrencies.fiat;
    if (_query.trim().isEmpty) return list;
    final q = _query.toLowerCase();
    return list
        .where((c) =>
            c.code.toLowerCase().contains(q) ||
            c.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SizedBox(
      height: 500,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by code or name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final info = filtered[i];
                final curr = SupportedCurrencies.toCurrency(info);
                final isSelected =
                    widget.selected?.code == info.code;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      info.symbol,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  title: Text(info.name),
                  subtitle: Text('${info.code} - ${info.symbol}'),
                  trailing:
                      isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSelected(curr);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
