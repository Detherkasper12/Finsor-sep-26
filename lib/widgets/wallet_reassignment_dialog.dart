import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../models/wallet.dart';
import '../utils/category_colors.dart';
import '../utils/category_icon_mapper.dart';

Future<String?> showWalletReassignmentDialog({
  required BuildContext context,
  required String walletName,
  required int transactionCount,
  required List<Wallet> availableWallets,
}) {
  if (availableWallets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No other wallet to reassign transactions to')),
    );
    return Future.value(null);
  }

  String? selectedId;

  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Reassign Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"$walletName" has $transactionCount transaction(s). '
                'Choose a wallet to reassign them to:'),
            const Gap(16),
            ...availableWallets.map((w) {
              final color = CategoryColors.fromHex(w.color ?? '#4CAF50');
              return RadioListTile<String>(
                value: w.id,
                groupValue: selectedId,
                onChanged: (v) => setState(() => selectedId = v),
                title: Text(w.name),
                secondary: Icon(CategoryIcons.walletIcon(w.type.name), color: color),
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),
          ],
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
