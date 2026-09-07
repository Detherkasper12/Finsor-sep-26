import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:uuid/uuid.dart';
import '../../constants/supported_currencies.dart';
import '../../models/wallet.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/currency_picker.dart';

class AddEditWalletScreen extends ConsumerStatefulWidget {
  final Wallet? wallet;

  const AddEditWalletScreen({super.key, this.wallet});

  @override
  ConsumerState<AddEditWalletScreen> createState() =>
      _AddEditWalletScreenState();
}

class _AddEditWalletScreenState extends ConsumerState<AddEditWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _balanceController;
  late TextEditingController _creditLimitController;
  late TextEditingController _debtAmountController;
  late TextEditingController _goalAmountController;
  late WalletType _type;
  late AccountType _accountType;
  late String _currencyCode;
  bool _includeInTotal = true;
  bool _showDebtInExpenses = false;
  bool _debtIsIOwe = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final w = widget.wallet;
    _nameController = TextEditingController(text: w?.name ?? '');
    _descController = TextEditingController(text: w?.description ?? '');
    _balanceController = TextEditingController(
      text: (w?.initialBalance ?? 0).toStringAsFixed(2),
    );
    _creditLimitController = TextEditingController(
      text: w?.creditLimit?.toStringAsFixed(2) ?? '',
    );
    _debtAmountController = TextEditingController(
      text: (w?.debtIOwe ?? w?.debtOwedToMe ?? w?.debtTotal ?? 0).toStringAsFixed(2),
    );
    _goalAmountController = TextEditingController(
      text: w?.goalAmount?.toStringAsFixed(2) ?? '',
    );
    _type = w?.type ?? WalletType.cash;
    _accountType = w?.accountType ?? AccountType.regular;
    _currencyCode = w?.currency ?? 'USD';
    _includeInTotal = w?.includeInTotal ?? (_accountType == AccountType.regular);
    _showDebtInExpenses = w?.showDebtInExpenses ?? false;
    if (w != null && w.debtOwedToMe != null && (w.debtOwedToMe ?? 0) > 0) _debtIsIOwe = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _balanceController.dispose();
    _creditLimitController.dispose();
    _debtAmountController.dispose();
    _goalAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.wallet != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit account' : 'New account'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Cash, Main Account',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const Gap(16),
            _buildAccountTypeSelector(),
            if (_accountType == AccountType.regular) ...[
              const Gap(16),
              DropdownButtonFormField<WalletType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Kind', border: OutlineInputBorder()),
                items: WalletType.values.map((t) => DropdownMenuItem(value: t, child: Text(_walletTypeLabel(t)))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() {
                    _type = v;
                    if (v == WalletType.crypto && !SupportedCurrencies.crypto.any((c) => c.code == _currencyCode)) _currencyCode = 'BTC';
                    else if (v != WalletType.crypto && SupportedCurrencies.crypto.any((c) => c.code == _currencyCode)) _currencyCode = 'USD';
                  });
                },
              ),
            ],
            const Gap(16),
            ListTile(
              title: Text(_getCurrencyDisplay()),
              subtitle: const Text('Tap to change'),
              trailing: const Icon(Icons.chevron_right),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              onTap: () => _showCurrencyPicker(),
            ),
            const Gap(8),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const Gap(16),
            SwitchListTile(
              title: const Text('Include in total balance'),
              subtitle: const Text('Учитывать в общем балансе'),
              value: _includeInTotal,
              onChanged: (v) => setState(() => _includeInTotal = v),
            ),
            const Gap(16),
            if (_accountType == AccountType.regular) ..._buildRegularFields(),
            if (_accountType == AccountType.debt) ..._buildDebtFields(),
            if (_accountType == AccountType.savings) ..._buildSavingsFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account type', style: Theme.of(context).textTheme.titleSmall),
        const Gap(8),
        Row(
          children: [
            Expanded(child: _accountTypeCard(AccountType.regular, Icons.account_balance_wallet, 'Regular', 'Обычный')),
            const Gap(8),
            Expanded(child: _accountTypeCard(AccountType.debt, Icons.credit_card, 'Debt', 'Долговой')),
            const Gap(8),
            Expanded(child: _accountTypeCard(AccountType.savings, Icons.savings, 'Savings', 'Накопительный')),
          ],
        ),
      ],
    );
  }

  Widget _accountTypeCard(AccountType type, IconData icon, String title, String subtitle) {
    final selected = _accountType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _accountType = type;
          if (type == AccountType.debt || type == AccountType.savings) _includeInTotal = false;
          else _includeInTotal = true;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: selected ? Theme.of(context).colorScheme.primary : null),
            const Gap(4),
            Text(title, style: TextStyle(fontWeight: selected ? FontWeight.bold : null, fontSize: 12)),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRegularFields() {
    return [
      TextFormField(
        controller: _balanceController,
        decoration: const InputDecoration(
          labelText: 'Starting balance',
          hintText: '0.00',
          border: OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          if (v == null || v.isEmpty) return null;
          return double.tryParse(v) == null ? 'Invalid number' : null;
        },
      ),
      const Gap(8),
      TextFormField(
        controller: _creditLimitController,
        decoration: const InputDecoration(
          labelText: 'Credit limit (optional)',
          border: OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    ];
  }

  List<Widget> _buildDebtFields() {
    return [
      Row(
        children: [
          Expanded(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('I owe')),
                ButtonSegment(value: false, label: Text('Owed to me')),
              ],
              selected: {_debtIsIOwe},
              onSelectionChanged: (s) => setState(() => _debtIsIOwe = s.first),
            ),
          ),
        ],
      ),
      const Gap(8),
      TextFormField(
        controller: _debtAmountController,
        decoration: const InputDecoration(
          labelText: 'Total debt amount',
          border: OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      const Gap(8),
      SwitchListTile(
        title: const Text('Show in expenses'),
        subtitle: const Text('Отображать в расходах'),
        value: _showDebtInExpenses,
        onChanged: (v) => setState(() => _showDebtInExpenses = v),
      ),
    ];
  }

  List<Widget> _buildSavingsFields() {
    return [
      TextFormField(
        controller: _balanceController,
        decoration: const InputDecoration(
          labelText: 'Starting balance',
          hintText: '0.00',
          border: OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      const Gap(8),
      TextFormField(
        controller: _goalAmountController,
        decoration: const InputDecoration(
          labelText: 'Goal amount',
          hintText: 'Цель',
          border: OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    ];
  }

  String _getCurrencyDisplay() {
    final info = SupportedCurrencies.byCode(_currencyCode);
    if (info != null) return '${info.code} - ${info.name}';
    return _currencyCode;
  }

  String _walletTypeLabel(WalletType t) {
    switch (t) {
      case WalletType.cash: return 'Cash';
      case WalletType.bank: return 'Bank';
      case WalletType.card: return 'Card';
      case WalletType.savings: return 'Savings';
      case WalletType.investment: return 'Investment';
      case WalletType.crypto: return 'Crypto';
      case WalletType.other: return 'Other';
    }
  }

  void _showCurrencyPicker() {
    final isCrypto = _type == WalletType.crypto;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => CurrencyPicker(
        title: isCrypto ? 'Choose Cryptocurrency' : 'Choose Currency',
        selected: () {
          final info = SupportedCurrencies.byCode(_currencyCode);
          return info != null ? SupportedCurrencies.toCurrency(info) : null;
        }(),
        includeCrypto: isCrypto,
        onSelected: (c) {
          setState(() => _currencyCode = c.code);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final desc = _descController.text.trim().isEmpty ? null : _descController.text.trim();
      double? balance;
      if (_accountType == AccountType.regular || _accountType == AccountType.savings) {
        balance = double.tryParse(_balanceController.text) ?? 0;
      }
      double? debtVal;
      if (_accountType == AccountType.debt) {
        debtVal = double.tryParse(_debtAmountController.text) ?? 0;
      }
      if (widget.wallet != null) {
        final w = widget.wallet!;
        final updated = w.copyWith(
          name: name,
          description: desc,
          type: _type,
          accountType: _accountType,
          currency: _currencyCode,
          includeInTotal: _includeInTotal,
          initialBalance: balance ?? w.initialBalance,
          currentBalance: _accountType == AccountType.regular || _accountType == AccountType.savings ? (balance ?? w.currentBalance) : w.currentBalance,
          creditLimit: _accountType == AccountType.regular ? double.tryParse(_creditLimitController.text) : null,
          debtIOwe: _accountType == AccountType.debt && _debtIsIOwe ? debtVal : null,
          debtOwedToMe: _accountType == AccountType.debt && !_debtIsIOwe ? debtVal : null,
          debtTotal: _accountType == AccountType.debt ? debtVal : null,
          showDebtInExpenses: _accountType == AccountType.debt ? _showDebtInExpenses : false,
          goalAmount: _accountType == AccountType.savings ? double.tryParse(_goalAmountController.text) : null,
          updatedAt: DateTime.now(),
        );
        await ref.read(walletNotifierProvider.notifier).updateWallet(updated);
      } else {
        final wallet = Wallet(
          id: const Uuid().v4(),
          name: name,
          type: _type,
          accountType: _accountType,
          currency: _currencyCode,
          description: desc,
          initialBalance: balance ?? 0,
          currentBalance: balance ?? 0,
          includeInTotal: _includeInTotal,
          creditLimit: _accountType == AccountType.regular ? double.tryParse(_creditLimitController.text) : null,
          debtIOwe: _accountType == AccountType.debt && _debtIsIOwe ? debtVal : null,
          debtOwedToMe: _accountType == AccountType.debt && !_debtIsIOwe ? debtVal : null,
          debtTotal: _accountType == AccountType.debt ? debtVal : null,
          showDebtInExpenses: _accountType == AccountType.debt ? _showDebtInExpenses : false,
          goalAmount: _accountType == AccountType.savings ? double.tryParse(_goalAmountController.text) : null,
          createdAt: DateTime.now(),
        );
        await ref.read(walletNotifierProvider.notifier).addWallet(wallet);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.wallet != null ? 'Account updated' : 'Account added')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
