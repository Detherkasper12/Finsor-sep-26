import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../models/category.dart';
import '../utils/category_colors.dart';
import '../utils/category_icon_mapper.dart';

Future<String?> showCategoryReassignmentDialog({
  required BuildContext context,
  required String categoryName,
  required int transactionCount,
  required List<Category> availableCategories,
  String? labelOverride,
}) {
  if (availableCategories.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No other category to reassign to')),
    );
    return Future.value(null);
  }

  String? selectedId;

  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Reassign Transactions'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(labelOverride ??
                  '"$categoryName" has $transactionCount transaction(s). '
                  'Choose a category to reassign them to:'),
              const Gap(16),
              ...availableCategories.map((c) {
                final color = CategoryColors.fromHex(c.color);
                return RadioListTile<String>(
                  value: c.id,
                  groupValue: selectedId,
                  onChanged: (v) => setState(() => selectedId = v),
                  title: Text(c.name),
                  secondary: Icon(CategoryIcons.fromName(c.iconName), color: color),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: selectedId == null
                ? null
                : () => Navigator.pop(ctx, selectedId),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reassign & Delete'),
          ),
        ],
      ),
    ),
  );
}
