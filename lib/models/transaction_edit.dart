import '../utils/safe_json_parse.dart';

/// Audit record: previous state of a transaction before edit.
class TransactionEdit {
  final String id;
  final String transactionId;
  final double? previousAmount;
  final String? previousCategoryId;
  final DateTime? previousDate;
  final String? previousWalletId;
  final String? previousStatus;
  final DateTime editedAt;

  const TransactionEdit({
    required this.id,
    required this.transactionId,
    this.previousAmount,
    this.previousCategoryId,
    this.previousDate,
    this.previousWalletId,
    this.previousStatus,
    required this.editedAt,
  });

  factory TransactionEdit.fromJson(Map<String, dynamic> json) {
    return TransactionEdit(
      id: safeStringOr(json['id'], ''),
      transactionId: safeStringOr(json['transactionId'] ?? json['transaction_id'], ''),
      previousAmount: safeDouble(json['previousAmount'] ?? json['previous_amount']),
      previousCategoryId: safeString(json['previousCategoryId'] ?? json['previous_category_id']),
      previousDate: safeDateTime(json['previousDate'] ?? json['previous_date']),
      previousWalletId: safeString(json['previousWalletId'] ?? json['previous_wallet_id']),
      previousStatus: safeString(json['previousStatus'] ?? json['previous_status']),
      editedAt: safeDateTime(json['editedAt'] ?? json['edited_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'previousAmount': previousAmount,
      'previousCategoryId': previousCategoryId,
      'previousDate': previousDate?.toIso8601String(),
      'previousWalletId': previousWalletId,
      'previousStatus': previousStatus,
      'editedAt': editedAt.toIso8601String(),
    };
  }
}
