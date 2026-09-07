import '../utils/safe_json_parse.dart';

/// Budget period types
enum BudgetPeriod {
  weekly,
  monthly,
  quarterly,
  yearly,
  custom,
}

/// Budget model for spending limits and goals
class Budget {
  final String id;
  final String name;
  final String? categoryId; // null for total budget
  final String? walletId; // null for all wallets
  final double amount;
  final double spent;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool notifyWhenExceeded;
  final double warningThreshold; // Percentage
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  const Budget({
    required this.id,
    required this.name,
    this.categoryId,
    this.walletId,
    required this.amount,
    this.spent = 0.0,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.notifyWhenExceeded = false,
    this.warningThreshold = 80.0,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: safeStringOr(json['id'], ''),
      name: safeStringOr(json['name'], ''),
      categoryId: safeString(json['categoryId']),
      walletId: safeString(json['walletId']),
      amount: safeDouble(json['amount']) ?? 0.0,
      spent: safeDouble(json['spent']) ?? 0.0,
      period: BudgetPeriod.values.byName(safeStringOr(json['period'], 'monthly')),
      startDate: safeDateTime(json['startDate']) ?? DateTime.now(),
      endDate: safeDateTime(json['endDate']) ?? DateTime.now(),
      isActive: json['isActive'] != false,
      notifyWhenExceeded: json['notifyWhenExceeded'] == true,
      warningThreshold: safeDouble(json['warningThreshold']) ?? 80.0,
      description: safeString(json['description']),
      createdAt: safeDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: safeDateTime(json['updatedAt']),
      metadata: Map<String, dynamic>.from(json['metadata'] is Map ? json['metadata'] as Map : {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'walletId': walletId,
      'amount': amount,
      'spent': spent,
      'period': period.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'notifyWhenExceeded': notifyWhenExceeded,
      'warningThreshold': warningThreshold,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  Budget copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? walletId,
    double? amount,
    double? spent,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? notifyWhenExceeded,
    double? warningThreshold,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      notifyWhenExceeded: notifyWhenExceeded ?? this.notifyWhenExceeded,
      warningThreshold: warningThreshold ?? this.warningThreshold,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Extension methods for Budget
extension BudgetX on Budget {
  /// Calculate percentage spent
  double get percentageSpent {
    if (amount <= 0) return 0.0;
    return (spent / amount) * 100;
  }

  /// Check if budget is exceeded
  bool get isExceeded => spent > amount;

  /// Check if warning threshold is reached
  bool get isWarningThresholdReached => percentageSpent >= warningThreshold;

  /// Get remaining amount
  double get remaining => amount - spent;

  /// Check if budget is active for current date
  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Get period display name
  String get periodDisplayName {
    switch (period) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.quarterly:
        return 'Quarterly';
      case BudgetPeriod.yearly:
        return 'Yearly';
      case BudgetPeriod.custom:
        return 'Custom';
    }
  }

  /// Get status color based on spending
  String get statusColor {
    if (isExceeded) return '#F44336'; // Red
    if (isWarningThresholdReached) return '#FF9800'; // Orange
    return '#4CAF50'; // Green
  }

  /// Create a copy with updated spent amount
  Budget copyWithSpent(double newSpent) {
    return copyWith(
      spent: newSpent,
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  Budget copyWithUpdatedAt() {
    return copyWith(updatedAt: DateTime.now());
  }
}


