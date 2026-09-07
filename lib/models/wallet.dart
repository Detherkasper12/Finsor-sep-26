import '../utils/safe_json_parse.dart';

/// Account type (1Money-style)
enum AccountType { regular, debt, savings }

/// Wallet types
enum WalletType {
  cash,
  bank,
  card,
  savings,
  investment,
  crypto,
  other,
}

/// Wallet model for managing different accounts
class Wallet {
  final String id;
  final String name;
  final WalletType type;
  final AccountType accountType;
  final String currency;
  final double initialBalance;
  final double currentBalance;
  final String? description;
  final String? color;
  final String? iconName;
  final bool isActive;
  final bool includeInTotal;
  final bool isDefault;
  final double? creditLimit;
  final double? debtIOwe;
  final double? debtOwedToMe;
  final double? debtTotal;
  final bool showDebtInExpenses;
  final double? goalAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    this.accountType = AccountType.regular,
    required this.currency,
    this.initialBalance = 0.0,
    this.currentBalance = 0.0,
    this.description,
    this.color,
    this.iconName,
    this.isActive = true,
    this.includeInTotal = true,
    this.isDefault = false,
    this.creditLimit,
    this.debtIOwe,
    this.debtOwedToMe,
    this.debtTotal,
    this.showDebtInExpenses = false,
    this.goalAmount,
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final atStr = safeStringOr(json['accountType'], 'regular');
    AccountType at = AccountType.regular;
    for (final e in AccountType.values) { if (e.name == atStr) { at = e; break; } }
    final includeDefault = at == AccountType.regular;
    return Wallet(
      id: safeStringOr(json['id'], ''),
      name: safeStringOr(json['name'], ''),
      type: WalletType.values.byName(safeStringOr(json['type'], 'other')),
      accountType: at,
      currency: safeStringOr(json['currency'], 'USD'),
      initialBalance: safeDouble(json['initialBalance']) ?? 0.0,
      currentBalance: safeDouble(json['currentBalance']) ?? 0.0,
      description: safeString(json['description']),
      color: safeString(json['color']),
      iconName: safeString(json['iconName']),
      isActive: json['isActive'] != false,
      includeInTotal: json['includeInTotal'] ?? includeDefault,
      isDefault: json['isDefault'] == true,
      creditLimit: safeDouble(json['creditLimit']),
      debtIOwe: safeDouble(json['debtIOwe']),
      debtOwedToMe: safeDouble(json['debtOwedToMe']),
      debtTotal: safeDouble(json['debtTotal']),
      showDebtInExpenses: json['showDebtInExpenses'] == true,
      goalAmount: safeDouble(json['goalAmount']),
      createdAt: safeDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: safeDateTime(json['updatedAt']),
      metadata: Map<String, dynamic>.from(json['metadata'] is Map ? json['metadata'] as Map : {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'accountType': accountType.name,
      'currency': currency,
      'initialBalance': initialBalance,
      'currentBalance': currentBalance,
      'description': description,
      'color': color,
      'iconName': iconName,
      'isActive': isActive,
      'includeInTotal': includeInTotal,
      'isDefault': isDefault,
      'creditLimit': creditLimit,
      'debtIOwe': debtIOwe,
      'debtOwedToMe': debtOwedToMe,
      'debtTotal': debtTotal,
      'showDebtInExpenses': showDebtInExpenses,
      'goalAmount': goalAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  Wallet copyWith({
    String? id,
    String? name,
    WalletType? type,
    AccountType? accountType,
    String? currency,
    double? initialBalance,
    double? currentBalance,
    String? description,
    String? color,
    String? iconName,
    bool? isActive,
    bool? includeInTotal,
    bool? isDefault,
    double? creditLimit,
    double? debtIOwe,
    double? debtOwedToMe,
    double? debtTotal,
    bool? showDebtInExpenses,
    double? goalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      accountType: accountType ?? this.accountType,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      description: description ?? this.description,
      color: color ?? this.color,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
      includeInTotal: includeInTotal ?? this.includeInTotal,
      isDefault: isDefault ?? this.isDefault,
      creditLimit: creditLimit ?? this.creditLimit,
      debtIOwe: debtIOwe ?? this.debtIOwe,
      debtOwedToMe: debtOwedToMe ?? this.debtOwedToMe,
      debtTotal: debtTotal ?? this.debtTotal,
      showDebtInExpenses: showDebtInExpenses ?? this.showDebtInExpenses,
      goalAmount: goalAmount ?? this.goalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Extension methods for Wallet
extension WalletX on Wallet {
  /// Get wallet type display name
  String get typeDisplayName {
    switch (type) {
      case WalletType.cash:
        return 'Cash';
      case WalletType.bank:
        return 'Bank Account';
      case WalletType.card:
        return 'Credit/Debit Card';
      case WalletType.savings:
        return 'Savings Account';
      case WalletType.investment:
        return 'Investment Account';
      case WalletType.crypto:
        return 'Cryptocurrency';
      case WalletType.other:
        return 'Other';
    }
  }

  /// Get default icon for wallet type
  String get defaultIcon {
    switch (type) {
      case WalletType.cash:
        return 'cash';
      case WalletType.bank:
        return 'bank';
      case WalletType.card:
        return 'credit_card';
      case WalletType.savings:
        return 'savings';
      case WalletType.investment:
        return 'trending_up';
      case WalletType.crypto:
        return 'currency_bitcoin';
      case WalletType.other:
        return 'account_balance_wallet';
    }
  }

  /// Create a copy with updated balance and timestamp
  Wallet copyWithNewBalance(double newBalance) {
    return copyWith(
      currentBalance: newBalance,
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  Wallet copyWithUpdatedAt() {
    return copyWith(updatedAt: DateTime.now());
  }
}
