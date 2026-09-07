import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../providers/categories_provider.dart';
import '../../utils/category_icon_mapper.dart';
import '../../utils/category_colors.dart';
import '../../widgets/category_reassignment_dialog.dart';
import 'add_edit_category_screen.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: categoriesAsync.when(
        data: (categories) => _CategoriesManageList(categories: categories),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditCategoryScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoriesManageList extends ConsumerWidget {
  final List<Category> categories;
  const _CategoriesManageList({required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseCats = categories
        .where((c) => c.type == TransactionType.expense && c.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final incomeCats = categories
        .where((c) => c.type == TransactionType.income && c.isActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (expenseCats.isNotEmpty) ...[
          Text('Expense Categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
          const Gap(8),
          _ReorderableSection(categories: expenseCats),
          const Gap(24),
        ],
        if (incomeCats.isNotEmpty) ...[
          Text('Income Categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
          const Gap(8),
          _ReorderableSection(categories: incomeCats),
        ],
      ],
    );
  }
}

class _ReorderableSection extends ConsumerWidget {
  final List<Category> categories;
  const _ReorderableSection({required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final reordered = List<Category>.from(categories);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);
        ref
            .read(categoryNotifierProvider.notifier)
            .reorderCategories(reordered.map((c) => c.id).toList());
      },
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _CategoryTile(key: ValueKey(cat.id), category: cat);
      },
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final Category category;
  const _CategoryTile({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = CategoryColors.fromHex(category.color);
    final countAsync =
        ref.watch(transactionCountByCategoryProvider(category.id));
    final subs = ref.watch(categoriesProvider).valueOrNull?.where(
            (c) => c.parentId == category.id && c.isActive) ??
        [];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(CategoryIcons.fromName(category.iconName), color: color),
        ),
        title: Text(category.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            countAsync.when(
              data: (n) => Text('$n transaction(s)',
                  style: Theme.of(context).textTheme.bodySmall),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if (subs.isNotEmpty)
              Text('${subs.length} subcategory(ies)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle, color: Colors.grey),
            const Gap(4),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddEditCategoryScreen(category: category)),
              ),
            ),
            if (!category.isDefault)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20,
                    color: Colors.red),
                onPressed: () => _confirmDelete(context, ref),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final allCats = await ref.read(categoriesProvider.future);
    final children = allCats
        .where((c) => c.parentId == category.id && c.isActive)
        .toList();

    // Block deletion if parent has subcategories — force user to move/delete children first
    if (children.isNotEmpty) {
      if (!context.mounted) return;
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Category Has Subcategories'),
          content: Text(
              '"${category.name}" has ${children.length} subcategory(ies).\n\n'
              'Choose how to handle them before deleting:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'move'),
              child: const Text('Move children to another parent'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'delete_all'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete all'),
            ),
          ],
        ),
      );
      if (action == null || !context.mounted) return;

      if (action == 'move') {
        final targets = allCats
            .where((c) =>
                c.type == category.type &&
                c.id != category.id &&
                !children.any((ch) => ch.id == c.id) &&
                c.isActive)
            .toList();
        if (!context.mounted) return;
        final targetId = await showCategoryReassignmentDialog(
          context: context,
          categoryName: '${category.name} subcategories',
          transactionCount: children.length,
          availableCategories: targets,
          labelOverride: 'Move subcategories to:',
        );
        if (targetId == null || !context.mounted) return;
        final notifier = ref.read(categoryNotifierProvider.notifier);
        for (final child in children) {
          await notifier.updateCategory(child.copyWith(
            parentId: targetId,
            updatedAt: DateTime.now(),
          ));
        }
      } else if (action == 'delete_all') {
        // Delete all children first (with their own transaction reassignment if needed)
        final notifier = ref.read(categoryNotifierProvider.notifier);
        for (final child in children) {
          final childCount = await ref
              .read(transactionCountByCategoryProvider(child.id).future);
          if (childCount > 0) {
            // Reassign child transactions to parent before deleting child
            await notifier.deleteCategory(child.id, reassignToId: category.id);
          } else {
            await notifier.deleteCategory(child.id);
          }
        }
      }
      // Fall through to delete the parent itself
    }

    if (!context.mounted) return;
    final count =
        await ref.read(transactionCountByCategoryProvider(category.id).future);
    if (count == 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Delete "${category.name}"?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (ok == true) {
        await ref
            .read(categoryNotifierProvider.notifier)
            .deleteCategory(category.id);
      }
    } else {
      final targets = allCats
          .where((c) =>
              c.type == category.type &&
              c.id != category.id &&
              c.isActive)
          .toList();
      if (!context.mounted) return;
      final targetId = await showCategoryReassignmentDialog(
        context: context,
        categoryName: category.name,
        transactionCount: count,
        availableCategories: targets,
      );
      if (targetId != null && context.mounted) {
        await ref
            .read(categoryNotifierProvider.notifier)
            .deleteCategory(category.id, reassignToId: targetId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Category deleted, transactions reassigned')),
          );
        }
      }
    }
  }
}
