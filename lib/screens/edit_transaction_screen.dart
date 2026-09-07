import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/categories_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/categorization_provider.dart';
import '../constants/app_theme.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
  late TransactionType _type;
  late String _amount;
  late String? _selectedCategoryId;
  late String? _selectedWalletId;
  late String? _selectedToWalletId;
  late DateTime _selectedDate;
  late String _description;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _type = widget.transaction.type;
    _amount = widget.transaction.amount.toString();
    _selectedCategoryId = widget.transaction.categoryId;
    _selectedWalletId = widget.transaction.walletId;
    _selectedToWalletId = widget.transaction.toWalletId;
    _selectedDate = widget.transaction.createdAt;
    _description = widget.transaction.description ?? '';
    _amountController = TextEditingController(text: _amount);
    _descriptionController = TextEditingController(text: _description);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final categories = categoriesAsync.valueOrNull ?? [];
    final wallets = walletsAsync.valueOrNull ?? [];

    final filteredCategories = _type == TransactionType.transfer
        ? <Category>[]
        : categories.where((c) => c.type == _type).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
        actions: [
          TextButton(
            onPressed: _saveTransaction,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Selector
            _buildSectionTitle('Transaction Type'),
            const Gap(8),
            _buildTypeSelector(),

            const Gap(24),

            // Amount
            _buildSectionTitle('Amount'),
            const Gap(8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '\$ ',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              onChanged: (val) => _amount = val,
            ),

            const Gap(24),

            if (_type != TransactionType.transfer) ...[
              _buildSectionTitle('Category'),
              const Gap(8),
              _buildDropdown(
              value: _selectedCategoryId,
              items: filteredCategories
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategoryId = val),
            ),
            const Gap(24),
            ],

            _buildSectionTitle(_type == TransactionType.transfer ? 'From Wallet' : 'Wallet'),
            const Gap(8),
            _buildDropdown(
              value: _selectedWalletId,
              items: wallets
                  .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedWalletId = val),
            ),

            const Gap(24),

            if (_type == TransactionType.transfer) ...[
              _buildSectionTitle('To Wallet'),
              const Gap(8),
              _buildDropdown(
                value: _selectedToWalletId,
                items: wallets
                    .where((w) => w.id != _selectedWalletId)
                    .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedToWalletId = val),
              ),
              const Gap(24),
            ],

            _buildSectionTitle('Date'),
            const Gap(8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')} '
                '${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
            const Gap(24),

            // Description
            _buildSectionTitle('Description (Optional)'),
            const Gap(8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add a note...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => _description = val,
            ),

            const Gap(32),

            // Delete Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _deleteTransaction,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Delete Transaction',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time != null && mounted) {
      setState(() => _selectedDate = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      ));
    }
  }

  Widget _buildTypeSelector() {
    return Row(
      children: TransactionType.values.map((type) {
        final isSelected = _type == type;
        final color = type == TransactionType.expense
            ? Colors.red
            : type == TransactionType.income
                ? Colors.green
                : Colors.blue;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => setState(() {
                _type = type;
                _selectedCategoryId = type == TransactionType.transfer ? null : _selectedCategoryId;
                _selectedToWalletId = type == TransactionType.transfer ? _selectedToWalletId : null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? color.withAlpha(30) : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? color
                        : Theme.of(context).colorScheme.outline.withAlpha(50),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type == TransactionType.expense
                          ? Icons.arrow_upward
                          : type == TransactionType.income
                              ? Icons.arrow_downward
                              : Icons.swap_horiz,
                      color: isSelected ? color : Colors.grey,
                      size: 18,
                    ),
                    const Gap(6),
                    Text(
                      type.name[0].toUpperCase() + type.name.substring(1),
                      style: TextStyle(
                        color: isSelected ? color : Colors.grey,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdown({
    String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_type != TransactionType.transfer && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_type == TransactionType.transfer && _selectedToWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select destination wallet')),
      );
      return;
    }

    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a wallet')),
      );
      return;
    }

    final newCategoryId = _type == TransactionType.transfer ? 'transfer' : _selectedCategoryId!;
    final categoryChanged = widget.transaction.categoryId != newCategoryId;

    if (categoryChanged && _type != TransactionType.transfer) {
      final service = ref.read(categorizationServiceProvider);
      service.handleCorrection(
        description: _description.trim(),
        correctCategoryId: newCategoryId,
        transactionType: _type,
      );
    }

    final updated = Transaction(
      id: widget.transaction.id,
      amount: amount,
      type: _type,
      categoryId: newCategoryId,
      walletId: _selectedWalletId!,
      toWalletId: _type == TransactionType.transfer ? _selectedToWalletId : null,
      description: _description.isEmpty ? null : _description,
      createdAt: _selectedDate,
      updatedAt: DateTime.now(),
      metadata: widget.transaction.metadata,
      parentTransactionId: widget.transaction.parentTransactionId,
      isSplit: widget.transaction.isSplit,
      splitIndex: widget.transaction.splitIndex,
      recurringId: widget.transaction.recurringId,
      goalId: widget.transaction.goalId,
    );

    await ref.read(transactionNotifierProvider.notifier).updateTransaction(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(categoryChanged ? "Got it. I'll remember this." : 'Transaction updated'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  Future<void> _deleteTransaction() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(transactionNotifierProvider.notifier).deleteTransaction(widget.transaction.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction deleted'),
                  backgroundColor: Colors.red,
                ),
              );

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
