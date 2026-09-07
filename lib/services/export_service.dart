import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/category.dart';

/// Export options
class ExportOptions {
  final bool includeTransactions;
  final bool includeWallets;
  final bool includeCategories;
  final DateTime? startDate;
  final DateTime? endDate;

  const ExportOptions({
    this.includeTransactions = true,
    this.includeWallets = false,
    this.includeCategories = false,
    this.startDate,
    this.endDate,
  });
}

/// Export result
class ExportResult {
  final String csv;
  final int transactionCount;
  final String filename;

  const ExportResult({
    required this.csv,
    required this.transactionCount,
    required this.filename,
  });
}

/// Service for exporting data to CSV
class ExportService {
  /// Export transactions to CSV format
  static ExportResult exportTransactionsToCsv({
    required List<Transaction> transactions,
    required List<Wallet> wallets,
    required List<Category> categories,
    ExportOptions options = const ExportOptions(),
  }) {
    // Filter by date if specified
    var filtered = transactions;
    if (options.startDate != null) {
      filtered = filtered.where((t) => t.createdAt.isAfter(options.startDate!)).toList();
    }
    if (options.endDate != null) {
      final endOfDay = DateTime(
        options.endDate!.year,
        options.endDate!.month,
        options.endDate!.day,
        23, 59, 59,
      );
      filtered = filtered.where((t) => t.createdAt.isBefore(endOfDay)).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Create lookup maps
    final walletMap = {for (var w in wallets) w.id: w.name};
    final categoryMap = {for (var c in categories) c.id: c.name};

    // Build CSV
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Date,Type,Amount,Category,Wallet,Description');

    // Rows
    for (final tx in filtered) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(tx.createdAt);
      final type = tx.type.name.toUpperCase();
      final amount = tx.amount.toStringAsFixed(2);
      final category = _escapeCsv(categoryMap[tx.categoryId] ?? 'Unknown');
      final wallet = _escapeCsv(walletMap[tx.walletId] ?? 'Unknown');
      final description = _escapeCsv(tx.description ?? '');

      buffer.writeln('$date,$type,$amount,$category,$wallet,$description');
    }

    // Generate filename
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final filename = 'finsor_export_$dateStr.csv';

    return ExportResult(
      csv: buffer.toString(),
      transactionCount: filtered.length,
      filename: filename,
    );
  }

  /// Export wallets to CSV
  static String exportWalletsToCsv(List<Wallet> wallets) {
    final buffer = StringBuffer();
    buffer.writeln('Name,Type,Currency,Balance');

    for (final w in wallets) {
      buffer.writeln(
        '${_escapeCsv(w.name)},${w.type.name},${w.currency},${w.currentBalance.toStringAsFixed(2)}',
      );
    }

    return buffer.toString();
  }

  /// Export categories to CSV
  static String exportCategoriesToCsv(List<Category> categories) {
    final buffer = StringBuffer();
    buffer.writeln('Name,Type,Color');

    for (final c in categories) {
      buffer.writeln('${_escapeCsv(c.name)},${c.type.name},${c.color}');
    }

    return buffer.toString();
  }

  /// Escape CSV special characters
  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Get CSV as bytes for file saving
  static List<int> getCsvBytes(String csv) {
    return utf8.encode(csv);
  }
}
