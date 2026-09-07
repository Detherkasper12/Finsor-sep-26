import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';
import '../../models/wallet.dart';
import '../../models/transaction.dart';
import '../../services/ai_chat_service.dart';

class AIContextPicker extends StatefulWidget {
  final AIChatContext? initialContext;
  final List<Category> categories;
  final List<Wallet> wallets;
  final void Function(AIChatContext) onConfirm;
  final VoidCallback? onCancel;

  const AIContextPicker({
    super.key,
    this.initialContext,
    required this.categories,
    required this.wallets,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  State<AIContextPicker> createState() => _AIContextPickerState();
}

class _AIContextPickerState extends State<AIContextPicker> {
  DateTimeRange? _dateRange;
  String? _categoryId;
  List<String> _accountIds = [];
  final _expenseCategories =
      <Category>[];

  @override
  void initState() {
    super.initState();
    _dateRange = widget.initialContext?.dateRange;
    _categoryId = widget.initialContext?.categoryId;
    _accountIds = List.from(widget.initialContext?.accountIds ?? []);
    _expenseCategories.addAll(widget.categories
        .where((c) => c.type == TransactionType.expense)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name)));
  }

  bool get _isValid =>
      (_dateRange != null) || (_categoryId != null && _categoryId!.trim().isNotEmpty);

  void _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
    );
    if (range != null && mounted) {
      setState(() => _dateRange = range);
    }
  }

  void _toggleAccount(String id) {
    setState(() {
      if (_accountIds.contains(id)) {
        _accountIds.remove(id);
      } else {
        _accountIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Set context'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'At least one of date range or category is required.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(16),
              ListTile(
                title: const Text('Date range'),
                trailing: Text(
                  _dateRange != null
                      ? '${DateFormat.yMMMd().format(_dateRange!.start)} – ${DateFormat.yMMMd().format(_dateRange!.end)}'
                      : 'Select',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                onTap: _pickDateRange,
              ),
              const Gap(8),
              DropdownButtonFormField<String?>(
                value: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any')),
                  ..._expenseCategories.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const Gap(16),
              Text(
                'Accounts (optional)',
                style: theme.textTheme.titleSmall,
              ),
              const Gap(8),
              ...widget.wallets.where((w) => w.isActive).map((w) {
                return CheckboxListTile(
                  title: Text(w.name),
                  value: _accountIds.contains(w.id),
                  onChanged: (_) => _toggleAccount(w.id),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isValid
              ? () {
                  final ctx = AIChatContext(
                    dateRange: _dateRange,
                    categoryId: _categoryId?.trim().isEmpty == true ? null : _categoryId,
                    accountIds: _accountIds.isEmpty ? null : _accountIds,
                  );
                  widget.onConfirm(ctx);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
