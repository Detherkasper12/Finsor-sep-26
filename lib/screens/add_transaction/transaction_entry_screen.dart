import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/wallet.dart';
import '../../providers/categories_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/categories_provider.dart';

class TransactionEntryScreen extends ConsumerStatefulWidget {
  final TransactionType type;
  final String walletId;
  final String categoryId;
  final String? toWalletId;

  const TransactionEntryScreen({
    super.key,
    required this.type,
    required this.walletId,
    required this.categoryId,
    this.toWalletId,
  });

  @override
  ConsumerState<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends ConsumerState<TransactionEntryScreen> {
  String _amount = '';
  String _note = '';
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedSubcategoryIds = [];
  bool _isLoading = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final wallets = walletsAsync.valueOrNull ?? <Wallet>[];
    final categories = categoriesAsync.valueOrNull ?? <Category>[];
    final wallet = wallets.where((w) => w.id == widget.walletId).firstOrNull;
    final category = categories.where((c) => c.id == widget.categoryId).firstOrNull;
    final subcategories = categories.where((c) => c.parentId == widget.categoryId).toList();
    final walletName = wallet?.name ?? 'Account';
    final categoryName = category?.name ?? 'Category';
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add transaction'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  walletName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Gap(4),
                Text(
                  categoryName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, keyboardHeight + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAmountSection(),
                  const Gap(24),
                  _buildDateSection(),
                  const Gap(24),
                  _buildNoteSection(),
                  if (subcategories.isNotEmpty) ...[
                    const Gap(24),
                    _buildSubcategorySection(subcategories),
                  ],
                  _buildAnomalyBanner(),
                  const Gap(32),
                  _buildSaveButton(),
                  const Gap(32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Gap(12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: _getTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getTypeColor().withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Text(
                _amount.isEmpty ? '0.00' : _formatAmount(_amount),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getTypeColor(),
                    ),
              ),
            ],
          ),
        ),
        const Gap(16),
        _buildKeypad(),
      ],
    );
  }

  Widget _buildKeypad() {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: keys.expand((row) => row).map((key) {
        final isBackspace = key == '⌫';
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              if (isBackspace) {
                if (_amount.isNotEmpty) _amount = _amount.substring(0, _amount.length - 1);
              } else {
                if (key == '.' && _amount.contains('.')) return;
                if (_amount.length < 10) _amount += key;
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              key,
              style: TextStyle(
                fontSize: isBackspace ? 20 : 22,
                fontWeight: FontWeight.w600,
                color: isBackspace ? Colors.red : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Gap(12),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                const Gap(12),
                Text(
                  DateFormat('MMM dd, yyyy – HH:mm').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note (optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Gap(12),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            hintText: 'Enter note...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          maxLines: 2,
          onChanged: (v) => setState(() => _note = v),
        ),
      ],
    );
  }

  Widget _buildSubcategorySection(List<Category> subcategories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subcategories (tags)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Gap(12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: subcategories.map((c) {
            final selected = _selectedSubcategoryIds.contains(c.id);
            final color = Color(int.parse(c.color.replaceFirst('#', '0xFF')));
            return FilterChip(
              label: Text(c.name),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _selectedSubcategoryIds = [..._selectedSubcategoryIds, c.id];
                  } else {
                    _selectedSubcategoryIds = _selectedSubcategoryIds.where((id) => id != c.id).toList();
                  }
                });
              },
              selectedColor: color.withOpacity(0.3),
              checkmarkColor: color,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnomalyBanner() {
    if (widget.type != TransactionType.expense) return const SizedBox.shrink();
    final amount = double.tryParse(_amount);
    if (amount == null || amount <= 0) return const SizedBox.shrink();
    final avgAsync = ref.watch(categoryAverageAmountProvider(widget.categoryId));
    return avgAsync.when(
      data: (avg) {
        if (avg <= 0 || amount <= 2 * avg) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(40),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[800]),
              const Gap(8),
              const Expanded(
                child: Text(
                  'Unusually high spending for this category.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSaveButton() {
    final canSave = _amount.isNotEmpty && (double.tryParse(_amount) ?? 0) > 0;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSave && !_isLoading ? _save : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getTypeColor(),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Text('Save ${widget.type.name.toUpperCase()}'),
      ),
    );
  }

  Color _getTypeColor() {
    switch (widget.type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
    }
  }

  String _formatAmount(String amount) {
    if (amount.isEmpty) return '0.00';
    final clean = amount.replaceAll(RegExp(r'[^\d.]'), '');
    final value = double.tryParse(clean);
    return value != null ? NumberFormat('#,##0.00').format(value) : '0.00';
  }

  Future<void> _selectDate() async {
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
      setState(() {
        _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      });
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount) ?? 0;
    if (amount <= 0) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      final transaction = Transaction(
        id: const Uuid().v4(),
        amount: amount,
        type: widget.type,
        categoryId: widget.categoryId,
        walletId: widget.walletId,
        toWalletId: widget.toWalletId,
        description: _note.isEmpty ? null : _note,
        createdAt: _selectedDate,
      );
      final duplicates = await repo.findPotentialDuplicates(transaction);
      if (duplicates.isNotEmpty && mounted) {
        setState(() => _isLoading = false);
        final keepBoth = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Possible duplicate'),
            content: const Text(
              'This looks like a duplicate transaction. Merge (delete the other) or keep both?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep both'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Merge'),
              ),
            ],
          ),
        );
        if (keepBoth == null) return;
        if (keepBoth) {
          for (final d in duplicates) await repo.delete(d.id);
        }
        setState(() => _isLoading = true);
      }
      await repo.saveTransactionWithSubcategories(transaction, _selectedSubcategoryIds);
      ref.read(settingsNotifierProvider.notifier).updateLastUsedTransactionDefaults(
            walletId: widget.walletId,
            categoryId: widget.categoryId,
            type: widget.type.name,
          );
      ref.invalidate(transactionsProvider);
      ref.invalidate(walletProvider(widget.walletId));
      if (widget.toWalletId != null) ref.invalidate(walletProvider(widget.toWalletId!));
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.type.name} saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
