import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/categories_provider.dart';
import '../../models/category.dart';
import '../../utils/category_colors.dart';
import '../../utils/category_icon_mapper.dart';
import '../../utils/category_utils.dart';
import '../../widgets/add_transaction_bottom_sheet.dart';
import '../edit_transaction_screen.dart';
import '../main_screen.dart';
import 'transaction_filter_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _searchVisible = false;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  TransactionFilterState _filterState = TransactionFilterState.empty;
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  bool _pageNotifierInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(transactionsPageNotifierProvider.notifier).loadMore();
    }
  }

  void _ensurePageLoaded(WidgetRef ref) {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final monthStart = _selectedMonth;
    final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
    Set<String>? categoryIds;
    if (_filterState.categoryId != null) {
      categoryIds = getDescendantCategoryIds(categories, _filterState.categoryId!);
    }
    final notifier = ref.read(transactionsPageNotifierProvider.notifier);
    notifier.setQuery(
      startDate: monthStart,
      endDate: monthEnd,
      filterState: _filterState,
      categoryIds: categoryIds,
    );
    notifier.loadFirstPage();
    _pageNotifierInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final pageState = ref.watch(transactionsPageNotifierProvider);
    final walletsAsync = ref.watch(walletsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final balanceAsync = ref.watch(transactionsMonthBalanceProvider((
      month: _selectedMonth,
      walletId: _filterState.walletId,
    )));

    if (!_pageNotifierInitialized &&
        pageState.valueOrNull?.list.isEmpty == true &&
        !pageState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePageLoaded(ref));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildMonthSelector(context),
            if (_filterState.hasFilters) _buildActiveFiltersBadge(context),
            const Gap(4),
            Expanded(
              child: pageState.when(
                data: (state) {
                  final wallets = walletsAsync.valueOrNull ?? [];
                  final categories = categoriesAsync.valueOrNull ?? [];
                  var filtered = state.list;
                  if (_searchVisible &&
                      _searchController.text.trim().isNotEmpty) {
                    final q = _searchController.text.trim().toLowerCase();
                    final parsedAmount = _tryParseAmount(q);
                    filtered = filtered.where((t) {
                      if (parsedAmount != null &&
                          (t.amount - parsedAmount).abs() < 0.01) {
                        return true;
                      }
                      final desc = (t.description ?? '').toLowerCase();
                      final cat = categories
                          .where((c) => c.id == t.categoryId)
                          .firstOrNull;
                      final catName = (cat?.name ?? '').toLowerCase();
                      return desc.contains(q) || catName.contains(q);
                    }).toList();
                  }

                  final grouped = _groupByDate(filtered);
                  final beginBal = balanceAsync.valueOrNull?.begin ?? 0.0;
                  final endBal = balanceAsync.valueOrNull?.end ?? 0.0;

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No transactions this month'));
                  }

                  final idListKey = (filtered.map((t) => t.id).toList()..sort()).join(',');
                  return Consumer(
                    builder: (context, ref, _) {
                      final subcatAsync = ref.watch(subcategoryNamesForTransactionsProvider(idListKey));
                      final subcategoryNamesMap = subcatAsync.valueOrNull ?? <String, List<String>>{};
                      return ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildBalanceRow(context, beginBal, endBal),
                          const Gap(8),
                          ...grouped.entries.expand((entry) {
                            final dayTotal = entry.value.fold<double>(0, (s, t) {
                              if (t.type == TransactionType.expense) return s - t.amount;
                              if (t.type == TransactionType.income) return s + t.amount;
                              return s;
                            });
                            final tiles = entry.value.map((tx) =>
                                _TransactionTile(
                                    transaction: tx,
                                    wallets: wallets,
                                    categories: categories,
                                    subcategoryNames: subcategoryNamesMap[tx.id] ?? const [],
                                    isSelectionMode: _selectionMode,
                                    isSelected: _selectedIds.contains(tx.id),
                                    onTap: () {
                                      if (_selectionMode) {
                                        setState(() {
                                          if (_selectedIds.contains(tx.id)) {
                                            _selectedIds.remove(tx.id);
                                            if (_selectedIds.isEmpty) _selectionMode = false;
                                          } else {
                                            _selectedIds.add(tx.id);
                                          }
                                        });
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  EditTransactionScreen(transaction: tx)),
                                        );
                                      }
                                    },
                                    onLongPress: () {
                                      setState(() {
                                        if (!_selectionMode) {
                                          _selectionMode = true;
                                          _selectedIds.add(tx.id);
                                        } else {
                                          if (_selectedIds.contains(tx.id)) {
                                            _selectedIds.remove(tx.id);
                                            if (_selectedIds.isEmpty) _selectionMode = false;
                                          } else {
                                            _selectedIds.add(tx.id);
                                          }
                                        }
                                      });
                                    }));
                            return [
                              _buildDateHeader(context, entry.key, dayTotal),
                              ...tiles,
                            ];
                          }),
                          const Gap(8),
                          if (state.isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
            if (_selectionMode && _selectedIds.isNotEmpty) _buildBulkBar(context),
          ],
        ),
      ),
      floatingActionButton: _selectionMode ? null : FloatingActionButton(
        heroTag: 'add_tx',
        onPressed: _showAddTransaction,
        tooltip: 'Add operation',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
      child: Row(
        children: [
          if (!_searchVisible)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
            ),
          if (_searchVisible)
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search by name, amount...',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            )
          else
            Expanded(
              child: Text('Transactions',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          IconButton(
            icon: Icon(_searchVisible ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searchVisible = !_searchVisible;
              if (!_searchVisible) _searchController.clear();
            }),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _filterState.hasFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final fmt = DateFormat('MMMM yyyy');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _selectedMonth = DateTime(
                  _selectedMonth.year, _selectedMonth.month - 1);
              _pageNotifierInitialized = false;
              ref.read(transactionsPageNotifierProvider.notifier).reset();
            }),
          ),
          Text(fmt.format(_selectedMonth),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _selectedMonth = DateTime(
                  _selectedMonth.year, _selectedMonth.month + 1);
              _pageNotifierInitialized = false;
              ref.read(transactionsPageNotifierProvider.notifier).reset();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersBadge(BuildContext context) {
    final parts = <String>[];
    if (_filterState.type != null) parts.add(_filterState.type!.name);
    if (_filterState.walletId != null) parts.add('wallet');
    if (_filterState.categoryId != null) parts.add('category');
    if (_filterState.startDate != null) parts.add('period');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: Colors.blue),
          const Gap(4),
          Text('Filters: ${parts.join(", ")}',
              style: const TextStyle(fontSize: 12, color: Colors.blue)),
          const Spacer(),
          GestureDetector(
            onTap: () =>
                setState(() {
                  _filterState = TransactionFilterState.empty;
                  _pageNotifierInitialized = false;
                  ref.read(transactionsPageNotifierProvider.notifier).reset();
                }),
            child: const Text('Clear',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceRow(
      BuildContext context, double beginBal, double endBal) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Beginning', style: Theme.of(context).textTheme.bodySmall),
            Text(fmt.format(beginBal),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Ending', style: Theme.of(context).textTheme.bodySmall),
            Text(fmt.format(endBal),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }

  Widget _buildDateHeader(
      BuildContext context, String date, double dayTotal) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(date,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          Text(fmt.format(dayTotal),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: dayTotal >= 0 ? Colors.green : Colors.red)),
        ],
      ),
    );
  }

  List<Transaction> _applyMonthFilter(List<Transaction> all) {
    final start = _selectedMonth;
    final end =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
    return all
        .where((t) =>
            t.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.createdAt.isBefore(end.add(const Duration(seconds: 1))))
        .toList();
  }

  List<Transaction> _applyFilterState(
    List<Transaction> list, [
    List<Category>? categories,
  ]) {
    var result = list;
    if (_filterState.type != null) {
      result = result.where((t) => t.type == _filterState.type).toList();
    }
    if (_filterState.walletId != null) {
      result = result
          .where((t) =>
              t.walletId == _filterState.walletId ||
              t.toWalletId == _filterState.walletId)
          .toList();
    }
    if (_filterState.categoryId != null) {
      final ids = categories != null
          ? getDescendantCategoryIds(categories, _filterState.categoryId!)
          : {_filterState.categoryId!};
      result = result.where((t) => ids.contains(t.categoryId)).toList();
    }
    if (_filterState.startDate != null && _filterState.endDate != null) {
      result = result
          .where((t) =>
              t.createdAt.isAfter(
                  _filterState.startDate!.subtract(const Duration(seconds: 1))) &&
              t.createdAt.isBefore(
                  _filterState.endDate!.add(const Duration(seconds: 1))))
          .toList();
    }
    if (_filterState.amountMin != null) {
      result = result.where((t) => t.amount >= _filterState.amountMin!).toList();
    }
    if (_filterState.amountMax != null) {
      result = result.where((t) => t.amount <= _filterState.amountMax!).toList();
    }
    return result;
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> txs) {
    final sorted = List<Transaction>.from(txs)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final map = <String, List<Transaction>>{};
    final fmt = DateFormat('MMM d, yyyy');
    for (final tx in sorted) {
      final key = fmt.format(tx.createdAt);
      map.putIfAbsent(key, () => []).add(tx);
    }
    return map;
  }

  double _calcBeginBalance(List<Transaction> allTx, List wallets) {
    final beforeMonth = allTx.where((t) =>
        t.createdAt.isBefore(_selectedMonth));
    double bal = 0;
    for (final t in beforeMonth) {
      if (t.type == TransactionType.income) bal += t.amount;
      if (t.type == TransactionType.expense) bal -= t.amount;
    }
    return bal;
  }

  double _calcEndBalance(List<Transaction> monthTx, double begin) {
    double bal = begin;
    for (final t in monthTx) {
      if (t.type == TransactionType.income) bal += t.amount;
      if (t.type == TransactionType.expense) bal -= t.amount;
    }
    return bal;
  }

  static double? _tryParseAmount(String input) {
    final normalized = input.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _openFilterSheet() async {
    final result = await showTransactionFilterSheet(
      context: context,
      ref: ref,
      current: _filterState,
    );
    if (result != null) {
      setState(() {
        _filterState = result;
        _pageNotifierInitialized = false;
        ref.read(transactionsPageNotifierProvider.notifier).reset();
      });
    }
  }

  Future<void> _repeatLastTransaction() async {
    final transactions = ref.read(transactionsProvider).valueOrNull ?? [];
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to repeat')),
      );
      return;
    }
    final sorted = List<Transaction>.from(transactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final last = sorted.first;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: AddTransactionBottomSheet(
            initialType: last.type,
            initialCategoryId: last.categoryId,
            initialWalletId: last.walletId,
            initialAmount: last.amount.toStringAsFixed(2),
            initialDescription: last.description,
            initialToWalletId: last.toWalletId,
          ),
        ),
      ),
    );
  }

  Widget _buildBulkBar(BuildContext context) {
    final transactions = ref.read(transactionsProvider).valueOrNull ?? [];
    final selected = transactions.where((t) => _selectedIds.contains(t.id)).toList();
    final notifier = ref.read(transactionNotifierProvider.notifier);
    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: SafeArea(
        child: Row(
          children: [
            TextButton(
              onPressed: () => setState(() {
                _selectionMode = false;
                _selectedIds.clear();
              }),
              child: const Text('Cancel'),
            ),
            Text('${_selectedIds.length} selected', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete transactions?'),
                    content: Text('Delete ${selected.length} transaction(s)?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  for (final t in selected) await notifier.deleteTransaction(t.id);
                  setState(() { _selectionMode = false; _selectedIds.clear(); });
                  ref.invalidate(transactionsProvider);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.label_outline),
              onPressed: () async {
                final categoryId = await showDialog<String>(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                    title: const Text('Change category'),
                    children: categories
                        .where((c) => c.type == TransactionType.expense || c.type == TransactionType.income)
                        .map((c) => ListTile(
                              title: Text(c.name),
                              onTap: () => Navigator.pop(ctx, c.id),
                            ))
                        .toList(),
                  ),
                );
                if (categoryId != null && mounted) {
                  for (final t in selected) {
                    await notifier.updateTransaction(t.copyWith(categoryId: categoryId, updatedAt: DateTime.now()));
                  }
                  setState(() { _selectionMode = false; _selectedIds.clear(); });
                  ref.invalidate(transactionsProvider);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              onPressed: () async {
                final walletId = await showDialog<String>(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                    title: const Text('Change account'),
                    children: wallets
                        .map((w) => ListTile(
                              title: Text(w.name),
                              onTap: () => Navigator.pop(ctx, w.id),
                            ))
                        .toList(),
                  ),
                );
                if (walletId != null && mounted) {
                  for (final t in selected) {
                    await notifier.updateTransaction(t.copyWith(walletId: walletId, updatedAt: DateTime.now()));
                  }
                  setState(() { _selectionMode = false; _selectedIds.clear(); });
                  ref.invalidate(transactionsProvider);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransaction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const AddTransactionBottomSheet(),
        ),
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final Transaction transaction;
  final List wallets;
  final List categories;
  final List<String> subcategoryNames;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TransactionTile({
    required this.transaction,
    required this.wallets,
    required this.categories,
    this.subcategoryNames = const [],
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = categories
        .where((c) => c.id == transaction.categoryId)
        .firstOrNull;
    final catName = cat?.name ?? 'Unknown';
    final catIcon = cat?.iconName ?? 'category';
    final catColor = CategoryColors.fromHex(cat?.color ?? '#666666');
    final isExpense = transaction.type == TransactionType.expense;
    final isIncome = transaction.type == TransactionType.income;
    final sign = isExpense ? '-' : (isIncome ? '+' : '');
    final amountColor = isExpense
        ? Colors.red
        : (isIncome ? Colors.green : Theme.of(context).colorScheme.primary);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
              )
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: catColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CategoryIcons.fromName(catIcon), color: catColor, size: 20),
              ),
        title: Text(
          transaction.description?.isNotEmpty == true
              ? transaction.description!
              : catName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(catName, style: Theme.of(context).textTheme.bodySmall),
            if (subcategoryNames.isNotEmpty)
              Text(
                subcategoryNames.join(' • '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Text('$sign${fmt.format(transaction.amount)}',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: amountColor)),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}