import '../utils/safe_json_parse.dart';
import 'transaction.dart';

enum RecurringFrequency { daily, weekly, monthly, yearly }

class RecurringTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String walletId;
  final String? toWalletId;
  final String? description;
  final RecurringFrequency frequency;
  final int interval; // every N days/weeks/months/years
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextRunDate;
  final DateTime? lastGeneratedDate;
  final bool isPaused;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RecurringTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.walletId,
    this.toWalletId,
    this.description,
    required this.frequency,
    this.interval = 1,
    required this.startDate,
    this.endDate,
    required this.nextRunDate,
    this.lastGeneratedDate,
    this.isPaused = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: safeStringOr(json['id'], ''),
      amount: safeDouble(json['amount']) ?? 0.0,
      type: TransactionType.values.byName(safeStringOr(json['type'], 'expense')),
      categoryId: safeStringOr(json['categoryId'], ''),
      walletId: safeStringOr(json['walletId'], ''),
      toWalletId: safeString(json['toWalletId']),
      description: safeString(json['description']),
      frequency: RecurringFrequency.values.byName(safeStringOr(json['frequency'], 'monthly')),
      interval: safeInt(json['interval']) ?? 1,
      startDate: safeDateTime(json['startDate']) ?? DateTime.now(),
      endDate: safeDateTime(json['endDate']),
      nextRunDate: safeDateTime(json['nextRunDate']) ?? DateTime.now(),
      lastGeneratedDate: safeDateTime(json['lastGeneratedDate']),
      isPaused: json['isPaused'] == true,
      createdAt: safeDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: safeDateTime(json['updatedAt']),
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
      'frequency': frequency.name,
      'interval': interval,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'nextRunDate': nextRunDate.toIso8601String(),
      'lastGeneratedDate': lastGeneratedDate?.toIso8601String(),
      'isPaused': isPaused,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  RecurringTransaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? walletId,
    String? toWalletId,
    String? description,
    RecurringFrequency? frequency,
    int? interval,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextRunDate,
    DateTime? lastGeneratedDate,
    bool? isPaused,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      toWalletId: toWalletId ?? this.toWalletId,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextRunDate: nextRunDate ?? this.nextRunDate,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      isPaused: isPaused ?? this.isPaused,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get frequencyLabel {
    switch (frequency) {
      case RecurringFrequency.daily:
        return interval == 1 ? 'Daily' : 'Every $interval days';
      case RecurringFrequency.weekly:
        return interval == 1 ? 'Weekly' : 'Every $interval weeks';
      case RecurringFrequency.monthly:
        return interval == 1 ? 'Monthly' : 'Every $interval months';
      case RecurringFrequency.yearly:
        return interval == 1 ? 'Yearly' : 'Every $interval years';
    }
  }
}
