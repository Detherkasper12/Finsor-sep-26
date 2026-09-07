import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../models/wallet.dart';
import '../../models/transaction.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/premium_provider.dart';
import '../../premium/premium_features.dart';
import '../../widgets/premium/premium_gate.dart';

enum _BudgetFormType { global, category, wallet }

class CreateBudgetScreen extends ConsumerStatefulWidget {
  final Budget? budget;
  const CreateBudgetScreen({super.key, this.budget});

  @override
  ConsumerState<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends ConsumerState<CreateBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  _BudgetFormType _budgetType = _BudgetFormType.category;
  String? _selectedCategoryId;
  String? _selectedWalletId;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  double _warningThreshold = 80.0;
  bool _isLoading = false;

  bool get _isEdit => widget.budget != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final b = widget.budget!;
      _nameController.text = b.name;
      _amountController.text = b.amount.toStringAsFixed(2);
      _selectedCategoryId = b.categoryId;
      _selectedWalletId = b.walletId;
      if (b.categoryId != null) _budgetType = _BudgetFormType.category;
      else if (b.walletId != null) _budgetType = _BudgetFormType.wallet;
      else _budgetType = _BudgetFormType.global;
      _selectedPeriod = b.period;
      _warningThreshold = b.warningThreshold;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Budget' : 'Create Budget'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Budget Name'),
            const Gap(8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g., Monthly Food Budget',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Name is required' : null,
            ),
            const Gap(24),
            _buildSectionTitle('Budget Amount'),
            const Gap(8),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v?.trim().isEmpty == true) return 'Amount is required';
                final amount = double.tryParse(v!);
                if (amount == null || amount <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const Gap(24),
            _buildSectionTitle('Budget Type'),
            const Gap(8),
            SegmentedButton<_BudgetFormType>(
              segments: const [
                ButtonSegment(value: _BudgetFormType.global, label: Text('Global')),
                ButtonSegment(value: _BudgetFormType.category, label: Text('Category')),
                ButtonSegment(value: _BudgetFormType.wallet, label: Text('Wallet')),
              ],
              selected: {_budgetType},
              onSelectionChanged: (s) => setState(() {
                _budgetType = s.first;
                if (_budgetType == _BudgetFormType.global) {
                  _selectedCategoryId = null;
                  _selectedWalletId = null;
                } else if (_budgetType == _BudgetFormType.category) {
                  _selectedWalletId = null;
                } else {
                  _selectedCategoryId = null;
                }
              }),
            ),
            const Gap(24),
            if (_budgetType == _BudgetFormType.category) ...[
              _buildSectionTitle('Category'),
              const Gap(8),
              categoriesAsync.when(
                data: (categories) {
                  final expenseCategories = categories
                      .where((c) => c.type == TransactionType.expense)
                      .toList();
                  return _buildCategoryDropdown(expenseCategories);
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading categories'),
              ),
              const Gap(24),
            ],
            if (_budgetType == _BudgetFormType.wallet) ...[
              _buildSectionTitle('Wallet'),
              const Gap(8),
              walletsAsync.when(
                data: (wallets) => _buildWalletDropdown(wallets),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading wallets'),
              ),
              const Gap(24),
            ],
            _buildSectionTitle('Budget Period'),
            const Gap(8),
            _buildPeriodSelector(),
            const Gap(24),
            _buildSectionTitle('Warning Threshold'),
            const Gap(4),
            if (!isPremium)
              const PremiumFeatureBanner(message: 'Custom thresholds are Premium'),
            const Gap(8),
            PremiumGate(
              feature: PremiumFeature.budgetAlerts,
              useSubtleBadge: true,
              child: _buildThresholdSlider(),
            ),
            const Gap(32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBudget,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEdit ? 'Save Changes' : 'Create Budget',
                        style: const TextStyle(fontSize: 16)),
              ),
            ),
            const Gap(24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildCategoryDropdown(List<Category> categories) {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      decoration: InputDecoration(
        hintText: 'Select category',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      items: categories.map((c) {
        final color = Color(int.parse(c.color.replaceAll('#', '0xFF')));
        return DropdownMenuItem(
          value: c.id,
          child: Row(
            children: [
              Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                  color: color.withAlpha(50),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color, width: 2),
                ),
              ),
              const Gap(12),
              Text(c.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedCategoryId = v),
      validator: (v) => _budgetType == _BudgetFormType.category && v == null ? 'Select a category' : null,
    );
  }

  Widget _buildPeriodSelector() {
    return Wrap(
      spacing: 8,
      children: [BudgetPeriod.weekly, BudgetPeriod.monthly].map((period) {
        final isSelected = _selectedPeriod == period;
        final label = period == BudgetPeriod.weekly ? 'Weekly' : 'Monthly';
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedPeriod = period),
        );
      }).toList(),
    );
  }

  Widget _buildWalletDropdown(List<Wallet> wallets) {
    return DropdownButtonFormField<String>(
      value: _selectedWalletId,
      decoration: InputDecoration(
        hintText: 'Select wallet',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      items: wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
      onChanged: (v) => setState(() => _selectedWalletId = v),
      validator: (v) => _budgetType == _BudgetFormType.wallet && v == null ? 'Select a wallet' : null,
    );
  }

  Widget _buildThresholdSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Alert at ${_warningThreshold.toInt()}%'),
            Text(
              _warningThreshold >= 90 ? 'Late warning' : 'Standard',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        Slider(
          value: _warningThreshold,
          min: 50,
          max: 95,
          divisions: 9,
          label: '${_warningThreshold.toInt()}%',
          onChanged: (v) => setState(() => _warningThreshold = v),
        ),
      ],
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    final categoryId = _budgetType == _BudgetFormType.category ? _selectedCategoryId : null;
    final walletId = _budgetType == _BudgetFormType.wallet ? _selectedWalletId : null;
    if (categoryId != null && walletId != null) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.trim());

      if (_isEdit) {
        final updated = widget.budget!.copyWith(
          name: _nameController.text.trim(),
          categoryId: categoryId,
          walletId: walletId,
          amount: amount,
          period: _selectedPeriod,
          warningThreshold: _warningThreshold,
          updatedAt: DateTime.now(),
        );
        await ref.read(budgetNotifierProvider.notifier).updateBudget(updated);
      } else {
        await ref.read(budgetNotifierProvider.notifier).createBudget(
              name: _nameController.text.trim(),
              categoryId: categoryId,
              walletId: walletId,
              amount: amount,
              period: _selectedPeriod,
              warningThreshold: _warningThreshold,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Budget updated' : 'Budget created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
