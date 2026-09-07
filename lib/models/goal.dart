import '../utils/safe_json_parse.dart';

enum GoalType { savings, debt }
enum GoalStatus { active, completed, cancelled }

class Goal {
  final String id;
  final String name;
  final GoalType type;
  final double targetAmount;
  final double currentAmount;
  final String? linkedWalletId;
  final String? debtorName;
  final DateTime? dueDate;
  final GoalStatus status;
  final String iconName;
  final String color;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Goal({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.linkedWalletId,
    this.debtorName,
    this.dueDate,
    this.status = GoalStatus.active,
    this.iconName = 'savings',
    this.color = '#4CAF50',
    required this.createdAt,
    this.updatedAt,
  });

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => status == GoalStatus.completed;
  bool get isSavings => type == GoalType.savings;
  bool get isDebt => type == GoalType.debt;

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: safeStringOr(json['id'], ''),
      name: safeStringOr(json['name'], ''),
      type: GoalType.values.byName(safeStringOr(json['type'], 'savings')),
      targetAmount: safeDouble(json['targetAmount']) ?? 0.0,
      currentAmount: safeDouble(json['currentAmount']) ?? 0.0,
      linkedWalletId: safeString(json['linkedWalletId']),
      debtorName: safeString(json['debtorName']),
      dueDate: safeDateTime(json['dueDate']),
      status: GoalStatus.values.byName(safeStringOr(json['status'], 'active')),
      iconName: safeStringOr(json['iconName'], 'savings'),
      color: safeStringOr(json['color'], '#4CAF50'),
      createdAt: safeDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: safeDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'linkedWalletId': linkedWalletId,
      'debtorName': debtorName,
      'dueDate': dueDate?.toIso8601String(),
      'status': status.name,
      'iconName': iconName,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Goal copyWith({
    String? id,
    String? name,
    GoalType? type,
    double? targetAmount,
    double? currentAmount,
    String? linkedWalletId,
    String? debtorName,
    DateTime? dueDate,
    GoalStatus? status,
    String? iconName,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      linkedWalletId: linkedWalletId ?? this.linkedWalletId,
      debtorName: debtorName ?? this.debtorName,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
