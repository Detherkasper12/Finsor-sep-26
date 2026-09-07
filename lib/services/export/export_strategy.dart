import 'dart:typed_data';
import '../../models/transaction.dart';
import '../../models/wallet.dart';
import '../../models/category.dart';

/// Payload for export (transactions, wallets, categories, options).
class ExportPayload {
  final List<Transaction> transactions;
  final List<Wallet> wallets;
  final List<Category> categories;
  final ExportOptions options;

  const ExportPayload({
    required this.transactions,
    required this.wallets,
    required this.categories,
    this.options = const ExportOptions(),
  });
}

/// Export options (date range, what to include).
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

/// Result of an export (bytes + metadata for UI).
class ExportResult {
  final Uint8List bytes;
  final int transactionCount;
  final String filename;

  const ExportResult({
    required this.bytes,
    required this.transactionCount,
    required this.filename,
  });
}

/// Strategy for exporting data to a format. Default implementation is CSV.
abstract class ExportStrategy {
  Future<ExportResult> generate(ExportPayload payload);
}
