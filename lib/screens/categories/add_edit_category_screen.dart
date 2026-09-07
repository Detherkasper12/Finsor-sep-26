import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:uuid/uuid.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../providers/categories_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/category_icon_mapper.dart';
import '../../utils/category_colors.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final Category? category;
  const AddEditCategoryScreen({super.key, this.category});

  @override
  ConsumerState<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState
    extends ConsumerState<AddEditCategoryScreen> {
  final _nameController = TextEditingController();
  late TransactionType _type;
  late String _selectedIcon;
  late String _selectedColor;
  String? _parentId;
  bool _isLoading = false;
  List<String> _subcategoryNames = [];

  bool get _isEdit => widget.category != null;
  bool get _isNewParent => !_isEdit && _parentId == null;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameController.text = cat?.name ?? '';
    _type = cat?.type ?? TransactionType.expense;
    _selectedIcon = cat?.iconName ?? 'category';
    _selectedColor = cat?.color ?? CategoryColors.palette.first;
    _parentId = cat?.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Category' : 'New Category'),
        titleTextStyle: const TextStyle(fontSize: 18),
        actions: [
          if (_isEdit && !(widget.category!.isDefault))
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteCategory,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Name'),
          const Gap(8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Category name',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ),
          const Gap(24),
          if (!_isEdit) ...[
            _sectionTitle('Type'),
            const Gap(8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Expense'),
                    selected: _type == TransactionType.expense,
                    onSelected: (_) =>
                        setState(() => _type = TransactionType.expense),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Income'),
                    selected: _type == TransactionType.income,
                    onSelected: (_) =>
                        setState(() => _type = TransactionType.income),
                  ),
                ),
              ],
            ),
            const Gap(24),
          ],
          _sectionTitle('Parent Category (optional)'),
          const Gap(8),
          categoriesAsync.when(
            data: (cats) {
              final parents = cats
                  .where((c) =>
                      c.type == _type &&
                      c.parentId == null &&
                      c.id != widget.category?.id &&
                      c.isActive)
                  .toList();
              return DropdownButtonFormField<String?>(
                value: _parentId,
                decoration: InputDecoration(
                  hintText: 'None (top-level)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None (top-level)')),
                  ...parents.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name),
                      )),
                ],
                onChanged: (v) => setState(() => _parentId = v),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Error loading categories'),
          ),
          const Gap(16),
          _sectionTitle('Category currency'),
          const Gap(4),
          settings.when(
            data: (s) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${s.primaryCurrency.code} (${s.primaryCurrency.symbol})', style: Theme.of(context).textTheme.bodyMedium),
              subtitle: const Text('Same as primary currency'),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (_isNewParent || (_isEdit && widget.category!.parentId == null)) ...[
            const Gap(24),
            _sectionTitle('Subcategories'),
            const Gap(8),
            ...(_isEdit ? _buildLoadedSubcategories() : _buildSubcategoryList()),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add subcategory'),
              onTap: _showAddSubcategoryDialog,
            ),
          ],
          const Gap(24),
          _sectionTitle('Icon'),
          const Gap(8),
          _buildIconPicker(),
          const Gap(24),
          _sectionTitle('Color'),
          const Gap(8),
          _buildColorPicker(),
          const Gap(32),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Save Changes' : 'Create Category',
                      style: const TextStyle(fontSize: 16)),
            ),
          ),
          const Gap(24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w600));

  List<Widget> _buildSubcategoryList() {
    return _subcategoryNames.map((name) => ListTile(
      dense: true,
      leading: Icon(CategoryIcons.fromName(_selectedIcon), size: 20, color: CategoryColors.fromHex(_selectedColor)),
      title: Text(name),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, size: 20),
        onPressed: () => setState(() => _subcategoryNames.remove(name)),
      ),
    )).toList();
  }

  List<Widget> _buildLoadedSubcategories() {
    final parentId = widget.category!.id;
    final subcatsAsync = ref.watch(subcategoriesProvider(parentId));
    return subcatsAsync.when(
      data: (list) => list.map((c) => ListTile(
        dense: true,
        leading: Icon(CategoryIcons.fromName(c.iconName), size: 20, color: CategoryColors.fromHex(c.color)),
        title: Text(c.name),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (v) async {
            if (v == 'delete') {
              final count = await ref.read(transactionCountByCategoryProvider(c.id).future);
              if (count > 0) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reassign or delete transactions first')));
                return;
              }
              await ref.read(categoryNotifierProvider.notifier).deleteCategory(c.id);
              ref.invalidate(categoriesProvider);
              ref.invalidate(subcategoriesProvider(parentId));
              if (mounted) setState(() {});
            } else if (v == 'edit' && mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditCategoryScreen(category: c)));
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      )).toList(),
      loading: () => [const ListTile(title: Text('Loading...'))],
      error: (_, __) => [],
    );
  }

  Future<void> _showAddSubcategoryDialog() async {
    if (_isEdit) {
      final name = await showDialog<String>(context: context, builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Add subcategory'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: 'Name', hintText: 'Subcategory name'),
            autofocus: true,
            onSubmitted: (_) => Navigator.pop(ctx, c.text.trim()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Add')),
          ],
        );
      });
      if (name != null && name.isNotEmpty && mounted) {
        final parent = widget.category!;
        final child = Category(
          id: const Uuid().v4(),
          name: name,
          type: parent.type,
          parentId: parent.id,
          iconName: parent.iconName,
          color: parent.color,
          sortOrder: 999,
          createdAt: DateTime.now(),
        );
        await ref.read(categoryNotifierProvider.notifier).addCategory(child);
        ref.invalidate(categoriesProvider);
        ref.invalidate(subcategoriesProvider(parent.id));
        if (mounted) setState(() {});
      }
    } else {
      final name = await showDialog<String>(context: context, builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Add subcategory'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: 'Name', hintText: 'Subcategory name'),
            autofocus: true,
            onSubmitted: (_) => Navigator.pop(ctx, c.text.trim()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Add')),
          ],
        );
      });
      if (name != null && name.isNotEmpty && mounted) setState(() => _subcategoryNames.add(name));
    }
  }

  Widget _buildIconPicker() {
    final names = CategoryIcons.allNames;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: names.map((name) {
        final selected = name == _selectedIcon;
        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = name),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: selected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary, width: 2)
                  : null,
            ),
            child: Icon(CategoryIcons.fromName(name),
                size: 22,
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CategoryColors.palette.map((hex) {
        final color = CategoryColors.fromHex(hex);
        final selected = hex == _selectedColor;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = hex),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: selected
                  ? [BoxShadow(color: color.withAlpha(100), blurRadius: 8)]
                  : null,
            ),
            child:
                selected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
          ),
        );
      }).toList(),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isEdit) {
        final updated = widget.category!.copyWith(
          name: name,
          iconName: _selectedIcon,
          color: _selectedColor,
          parentId: _parentId,
          updatedAt: DateTime.now(),
        );
        await ref.read(categoryNotifierProvider.notifier).updateCategory(updated);
      } else {
        final parent = Category(
          id: const Uuid().v4(),
          name: name,
          type: _type,
          parentId: _parentId,
          iconName: _selectedIcon,
          color: _selectedColor,
          sortOrder: 999,
          createdAt: DateTime.now(),
        );
        await ref.read(categoryNotifierProvider.notifier).addCategory(parent);
        for (final subName in _subcategoryNames) {
          final child = Category(
            id: const Uuid().v4(),
            name: subName,
            type: _type,
            parentId: parent.id,
            iconName: _selectedIcon,
            color: _selectedColor,
            sortOrder: 999,
            createdAt: DateTime.now(),
          );
          await ref.read(categoryNotifierProvider.notifier).addCategory(child);
        }
      }
      if (mounted) Navigator.pop(context);
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

  Future<void> _deleteCategory() async {
    final cat = widget.category!;
    final count =
        await ref.read(transactionCountByCategoryProvider(cat.id).future);
    if (count == 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Delete "${cat.name}"?'),
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
        await ref.read(categoryNotifierProvider.notifier).deleteCategory(cat.id);
        if (mounted) Navigator.pop(context);
      }
    } else {
      final allCats = await ref.read(categoriesProvider.future);
      final targets = allCats
          .where((c) =>
              c.type == cat.type && c.id != cat.id && c.isActive)
          .toList();
      if (targets.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No other category to reassign to')),
          );
        }
        return;
      }
      if (!mounted) return;
      final targetId = await _showReassignDialog(targets, count);
      if (targetId != null && mounted) {
        await ref
            .read(categoryNotifierProvider.notifier)
            .deleteCategory(cat.id, reassignToId: targetId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category deleted, transactions reassigned')),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  Future<String?> _showReassignDialog(
      List<Category> targets, int count) {
    String? selected;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Reassign Transactions'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '"${widget.category!.name}" has $count transaction(s). '
                    'Choose a category to reassign them to:'),
                const Gap(16),
                ...targets.map((c) {
                  final clr = CategoryColors.fromHex(c.color);
                  return RadioListTile<String>(
                    value: c.id,
                    groupValue: selected,
                    onChanged: (v) => setS(() => selected = v),
                    title: Text(c.name),
                    secondary:
                        Icon(CategoryIcons.fromName(c.iconName), color: clr),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed:
                  selected == null ? null : () => Navigator.pop(ctx, selected),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reassign & Delete'),
            ),
          ],
        ),
      ),
    );
  }
}
