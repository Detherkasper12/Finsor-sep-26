import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../providers/categories_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/category_icon_mapper.dart';
import '../../utils/category_colors.dart';
import '../../widgets/category_reassignment_dialog.dart';
import 'categories_screen.dart';
import 'add_edit_category_screen.dart';
import '../main_screen.dart';

class CategoriesOverviewScreen extends ConsumerStatefulWidget {
  const CategoriesOverviewScreen({super.key});

  @override
  ConsumerState<CategoriesOverviewScreen> createState() =>
      _CategoriesOverviewScreenState();
}

class _CategoriesOverviewScreenState
    extends ConsumerState<CategoriesOverviewScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _showExpense = true;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildMonthSelector(context),
            const Gap(8),
            _buildTypeToggle(context),
            const Gap(12),
            Expanded(
              child: categoriesAsync.when(
                data: (categories) => transactionsAsync.when(
                  data: (transactions) => _buildCategoryGrid(
                      context, ref, categories, transactions),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_cat',
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AddEditCategoryScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
          ),
          Text('Categories',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen())),
            tooltip: 'Manage',
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
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: 'Expense',
              selected: _showExpense,
              onTap: () => setState(() => _showExpense = true),
            ),
          ),
          const Gap(8),
          Expanded(
            child: _ToggleButton(
              label: 'Income',
              selected: !_showExpense,
              onTap: () => setState(() => _showExpense = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, WidgetRef ref,
      List<Category> categories, List<Transaction> transactions) {
    final type =
        _showExpense ? TransactionType.expense : TransactionType.income;
    final filtered =
        categories.where((c) => c.type == type && c.isActive).toList();
    filtered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final startOfMonth = _selectedMonth;
    final endOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
    final monthTx = transactions
        .where((t) =>
            t.type == type &&
            t.createdAt.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
            t.createdAt.isBefore(endOfMonth.add(const Duration(seconds: 1))))
        .toList();

    final Map<String, double> amounts = {};
    for (final tx in monthTx) {
      amounts[tx.categoryId] = (amounts[tx.categoryId] ?? 0) + tx.amount;
    }
    final total =
        amounts.values.fold<double>(0, (sum, v) => sum + v);

    if (filtered.isEmpty) {
      return Center(
        child: Text('No ${_showExpense ? "expense" : "income"} categories'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final cat = filtered[index];
        final amount = amounts[cat.id] ?? 0;
        final color = CategoryColors.fromHex(cat.color);
        final pct = total > 0 ? (amount / total * 100) : 0.0;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddEditCategoryScreen(category: cat)),
          ),
          onLongPress: () => _showCategoryContextMenu(context, ref, cat, filtered),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color:
                      Theme.of(context).colorScheme.outline.withAlpha(30)),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(CategoryIcons.fromName(cat.iconName),
                      color: color, size: 22),
                ),
                const Gap(6),
                Text(cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600)),
                const Gap(2),
                Text(
                  NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                      .format(amount),
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold),
                ),
                if (pct > 0)
                  Text('${pct.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoryContextMenu(
      BuildContext context, WidgetRef ref, Category cat, List<Category> allFiltered) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AddEditCategoryScreen(category: cat)));
              },
            ),
            if (!cat.isDefault)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleCategoryDelete(context, ref, cat, allFiltered);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCategoryDelete(
      BuildContext context, WidgetRef ref, Category cat, List<Category> allFiltered) async {
    final count = await ref.read(transactionCountByCategoryProvider(cat.id).future);
    if (count == 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Delete "${cat.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (ok == true) {
        await ref.read(categoryNotifierProvider.notifier).deleteCategory(cat.id);
      }
    } else {
      final allCats = await ref.read(categoriesProvider.future);
      final targets = allCats
          .where((c) => c.type == cat.type && c.id != cat.id && c.isActive)
          .toList();
      if (!context.mounted) return;
      final targetId = await showCategoryReassignmentDialog(
        context: context,
        categoryName: cat.name,
        transactionCount: count,
        availableCategories: targets,
      );
      if (targetId != null && context.mounted) {
        await ref.read(categoryNotifierProvider.notifier)
            .deleteCategory(cat.id, reassignToId: targetId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category deleted, transactions reassigned')),
          );
        }
      }
    }
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}
