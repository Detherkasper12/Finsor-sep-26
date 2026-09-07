import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../models/wallet.dart';
import '../../models/category.dart';
import 'export_strategy.dart';

/// CSV export using current Finsor CSV logic.
class CsvExportStrategy implements ExportStrategy {
  @override
  Future<ExportResult> generate(ExportPayload payload) async {
    var filtered = payload.transactions;
    final opt = payload.options;
    if (opt.startDate != null) {
      filtered = filtered
          .where((t) => t.createdAt.isAfter(opt.startDate!))
          .toList();
    }
    if (opt.endDate != null) {
      final endOfDay = DateTime(
        opt.endDate!.year,
        opt.endDate!.month,
        opt.endDate!.day,
        23,
        59,
        59,
      );
      filtered =
          filtered.where((t) => t.createdAt.isBefore(endOfDay)).toList();
    }
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final walletMap = {for (var w in payload.wallets) w.id: w.name};
    final categoryMap = {for (var c in payload.categories) c.id: c.name};

    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Amount,Category,Wallet,Description');
    for (final tx in filtered) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(tx.createdAt);
      final type = tx.type.name.toUpperCase();
      final amount = tx.amount.toStringAsFixed(2);
      final category = _escapeCsv(categoryMap[tx.categoryId] ?? 'Unknown');
      final wallet = _escapeCsv(walletMap[tx.walletId] ?? 'Unknown');
      final description = _escapeCsv(tx.description ?? '');
      buffer.writeln('$date,$type,$amount,$category,$wallet,$description');
    }

    final csv = buffer.toString();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return ExportResult(
      bytes: Uint8List.fromList(utf8.encode(csv)),
      transactionCount: filtered.length,
      filename: 'finsor_export_$dateStr.csv',
    );
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
