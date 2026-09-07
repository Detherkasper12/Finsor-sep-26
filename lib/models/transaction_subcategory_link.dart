import '../utils/safe_json_parse.dart';

/// Link between a transaction and a subcategory (tag). Analytics use main category only.
class TransactionSubcategoryLink {
  final String id;
  final String transactionId;
  final String subcategoryId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TransactionSubcategoryLink({
    required this.id,
    required this.transactionId,
    required this.subcategoryId,
    required this.createdAt,
    this.updatedAt,
  });

  factory TransactionSubcategoryLink.fromJson(Map<String, dynamic> json) {
    return TransactionSubcategoryLink(
      id: safeStringOr(json['id'], ''),
      transactionId: safeStringOr(json['transactionId'] ?? json['transaction_id'], ''),
      subcategoryId: safeStringOr(json['subcategoryId'] ?? json['subcategory_id'], ''),
      createdAt: safeDateTime(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
      updatedAt: safeDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'subcategoryId': subcategoryId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String() ?? createdAt.toIso8601String(),
    };
  }
}
