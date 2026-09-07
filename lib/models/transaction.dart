import '../utils/safe_json_parse.dart';

/// Transaction types
enum TransactionType {
  income,
  expense,
  transfer,
}

/// Transaction model for financial operations
class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String walletId;
  final String? toWalletId;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? recurringId;
  final String? goalId;
  final Map<String, dynamic> metadata;
  final String? parentTransactionId;
  final bool isSplit;
  final int? splitIndex;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.walletId,
    this.toWalletId,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.recurringId,
    this.goalId,
    this.metadata = const {},
    this.parentTransactionId,
    this.isSplit = false,
    this.splitIndex,
  });

  bool get isRecurring => recurringId != null;
  /// Transaction date (same as createdAt for backward compatibility).
  DateTime get date => createdAt;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: safeStringOr(json['id'], ''),
      amount: safeDouble(json['amount']) ?? 0.0,
      type: TransactionType.values.byName(safeStringOr(json['type'], 'expense')),
      categoryId: safeStringOr(json['categoryId'], ''),
      walletId: safeStringOr(json['walletId'], ''),
      toWalletId: safeString(json['toWalletId']),
      description: safeString(json['description']),
      createdAt: safeDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: safeDateTime(json['updatedAt']),
      recurringId: safeString(json['recurringId']),
      goalId: safeString(json['goalId']),
      metadata: Map<String, dynamic>.from(json['metadata'] is Map ? json['metadata'] as Map : {}),
      parentTransactionId: safeString(json['parentTransactionId'] ?? json['parent_transaction_id']),
      isSplit: json['isSplit'] == true || json['is_split'] == true,
      splitIndex: safeInt(json['splitIndex'] ?? json['split_index']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'walletId': walletId,
      'toWalletId': toWalletId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'recurringId': recurringId,
      'goalId': goalId,
      'metadata': metadata,
      'parentTransactionId': parentTransactionId,
      'isSplit': isSplit,
      'splitIndex': splitIndex,
    };
  }

  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? walletId,
    String? toWalletId,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? recurringId,
    String? goalId,
    Map<String, dynamic>? metadata,
    String? parentTransactionId,
    bool? isSplit,
    int? splitIndex,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      toWalletId: toWalletId ?? this.toWalletId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recurringId: recurringId ?? this.recurringId,
      goalId: goalId ?? this.goalId,
      metadata: metadata ?? this.metadata,
      parentTransactionId: parentTransactionId ?? this.parentTransactionId,
      isSplit: isSplit ?? this.isSplit,
      splitIndex: splitIndex ?? this.splitIndex,
    );
  }
}

/// Extension methods for Transaction
extension TransactionX on Transaction {
  /// Check if transaction is an expense
  bool get isExpense => type == TransactionType.expense;

  /// Check if transaction is an income
  bool get isIncome => type == TransactionType.income;

  /// Check if transaction is a transfer
  bool get isTransfer => type == TransactionType.transfer;

  /// Get display amount (negative for expenses)
  double get displayAmount {
    switch (type) {
      case TransactionType.expense:
        return -amount;
      case TransactionType.income:
      case TransactionType.transfer:
        return amount;
    }
  }

  /// Create a copy with updated fields
  Transaction copyWithUpdatedAt() {
    return copyWith(updatedAt: DateTime.now());
  }
}
