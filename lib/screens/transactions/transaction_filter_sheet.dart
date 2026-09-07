import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../models/transaction.dart';
import '../../models/wallet.dart';
import '../../models/category.dart' as cat_model;
import '../../providers/wallet_provider.dart';
import '../../providers/categories_provider.dart';
import '../../utils/category_icon_mapper.dart';
import '../../utils/category_colors.dart';

class TransactionFilterState {
  final TransactionType? type;
  final String? walletId;
  final String? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? amountMin;
  final double? amountMax;

  const TransactionFilterState({
    this.type,
    this.walletId,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.amountMin,
    this.amountMax,
  });

  bool get hasFilters =>
      type != null ||
      walletId != null ||
      categoryId != null ||
      startDate != null ||
      endDate != null ||
      amountMin != null ||
      amountMax != null;

  TransactionFilterState copyWith({
    TransactionType? type,
    String? walletId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    double? amountMin,
    double? amountMax,
    bool clearType = false,
    bool clearWallet = false,
    bool clearCategory = false,
    bool clearDates = false,
    bool clearAmount = false,
  }) {
    return TransactionFilterState(
      type: clearType ? null : (type ?? this.type),
      walletId: clearWallet ? null : (walletId ?? this.walletId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      amountMin: clearAmount ? null : (amountMin ?? this.amountMin),
      amountMax: clearAmount ? null : (amountMax ?? this.amountMax),
    );
  }

  static const empty = TransactionFilterState();
}

Future<TransactionFilterState?> showTransactionFilterSheet({
  required BuildContext context,
  required WidgetRef ref,
  TransactionFilterState current = TransactionFilterState.empty,
}) {
  return showModalBottomSheet<TransactionFilterState>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scroll) =>
          _FilterSheetContent(current: current, ref: ref, scrollController: scroll),
    ),
  );
}

class _FilterSheetContent extends StatefulWidget {
  final TransactionFilterState current;
  final WidgetRef ref;
  final ScrollController scrollController;

  const _FilterSheetContent({
    required this.current,
    required this.ref,
    required this.scrollController,
  });

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  late TransactionFilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final wallets = widget.ref.watch(walletsProvider).valueOrNull ?? [];
    final categories = widget.ref.watch(categoriesProvider).valueOrNull ?? [];

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Filters',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => setState(
                  () => _state = TransactionFilterState.empty),
              child: const Text('Reset'),
            ),
          ],
        ),
        const Gap(16),
        Text('Type', style: _labelStyle(context)),
        const Gap(8),
        Wrap(
          spacing: 8,
          children: [
            _chip('All', _state.type == null,
                () => setState(() => _state = _state.copyWith(clearType: true))),
            _chip('Expense', _state.type == TransactionType.expense,
                () => setState(() => _state = TransactionFilterState(
                    type: TransactionType.expense,
                    walletId: _state.walletId,
                    categoryId: _state.categoryId,
                    startDate: _state.startDate,
                    endDate: _state.endDate))),
            _chip('Income', _state.type == TransactionType.income,
                () => setState(() => _state = TransactionFilterState(
                    type: TransactionType.income,
                    walletId: _state.walletId,
                    categoryId: _state.categoryId,
                    startDate: _state.startDate,
                    endDate: _state.endDate))),
            _chip('Transfer', _state.type == TransactionType.transfer,
                () => setState(() => _state = TransactionFilterState(
                    type: TransactionType.transfer,
                    walletId: _state.walletId,
                    categoryId: _state.categoryId,
                    startDate: _state.startDate,
                    endDate: _state.endDate))),
          ],
        ),
        const Gap(20),
        Text('Wallet', style: _labelStyle(context)),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('All', _state.walletId == null,
                () => setState(() => _state = _state.copyWith(clearWallet: true))),
            ...wallets.map((w) => _chip(
                w.name,
                _state.walletId == w.id,
                () => setState(() => _state = TransactionFilterState(
                    type: _state.type,
                    walletId: w.id,
                    categoryId: _state.categoryId,
                    startDate: _state.startDate,
                    endDate: _state.endDate)))),
          ],
        ),
        const Gap(20),
        Text('Category', style: _labelStyle(context)),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('All', _state.categoryId == null,
                () => setState(() => _state = _state.copyWith(clearCategory: true))),
            ...categories.where((c) => c.isActive).map((c) => _chip(
                c.name,
                _state.categoryId == c.id,
                () => setState(() => _state = TransactionFilterState(
                    type: _state.type,
                    walletId: _state.walletId,
                    categoryId: c.id,
                    startDate: _state.startDate,
                    endDate: _state.endDate)))),
          ],
        ),
        const Gap(20),
        Text('Period', style: _labelStyle(context)),
        const Gap(8),
        Wrap(
          spacing: 8,
          children: [
            _chip('All Time', _state.startDate == null,
                () => setState(() => _state = _state.copyWith(clearDates: true))),
            _chip('Today', _isToday(), () {
              final now = DateTime.now();
              setState(() => _state = TransactionFilterState(
                  type: _state.type,
                  walletId: _state.walletId,
                  categoryId: _state.categoryId,
                  startDate: DateTime(now.year, now.month, now.day),
                  endDate: DateTime(now.year, now.month, now.day, 23, 59, 59)));
            }),
            _chip('This Week', _isThisWeek(), () {
              final now = DateTime.now();
              final weekStart = now.subtract(Duration(days: now.weekday - 1));
              setState(() => _state = TransactionFilterState(
                  type: _state.type,
                  walletId: _state.walletId,
                  categoryId: _state.categoryId,
                  startDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
                  endDate: DateTime(now.year, now.month, now.day, 23, 59, 59)));
            }),
            _chip('This Month', _isThisMonth(), () {
              final now = DateTime.now();
              setState(() => _state = TransactionFilterState(
                  type: _state.type,
                  walletId: _state.walletId,
                  categoryId: _state.categoryId,
                  startDate: DateTime(now.year, now.month),
                  endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59)));
            }),
            ActionChip(
              label: const Text('Custom Range'),
              onPressed: _pickRange,
            ),
          ],
        ),
        const Gap(32),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, _state),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Apply Filters', style: TextStyle(fontSize: 16)),
          ),
        ),
        const Gap(16),
      ],
    );
  }

  bool _isToday() {
    if (_state.startDate == null) return false;
    final now = DateTime.now();
    return _state.startDate!.day == now.day &&
        _state.startDate!.month == now.month &&
        _state.startDate!.year == now.year;
  }

  bool _isThisWeek() {
    if (_state.startDate == null) return false;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _state.startDate!.day == weekStart.day &&
        _state.startDate!.month == weekStart.month;
  }

  bool _isThisMonth() {
    if (_state.startDate == null) return false;
    final now = DateTime.now();
    return _state.startDate!.day == 1 && _state.startDate!.month == now.month;
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  TextStyle _labelStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w600);

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (range != null) {
      setState(() => _state = TransactionFilterState(
          type: _state.type,
          walletId: _state.walletId,
          categoryId: _state.categoryId,
          startDate: range.start,
          endDate: DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59)));
    }
  }
}
