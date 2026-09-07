import '../utils/safe_json_parse.dart';
import 'transaction.dart';

/// Category model for organizing transactions
class Category {
  final String id;
  final String name;
  final TransactionType type;
  final String? parentId; // For subcategories
  final String? description;
  final String iconName;
  final String color; // Hex color code
  final bool isActive;
  final bool isDefault; // System categories
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    this.description,
    required this.iconName,
    required this.color,
    this.isActive = true,
    this.isDefault = false,
    this.sortOrder = 0,
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: safeStringOr(json['id'], ''),
      name: safeStringOr(json['name'], ''),
      type: TransactionType.values.byName(safeStringOr(json['type'], 'expense')),
      parentId: safeString(json['parentId']),
      description: safeString(json['description']),
      iconName: safeStringOr(json['iconName'], ''),
      color: safeStringOr(json['color'], '#000000'),
      isActive: json['isActive'] != false,
      isDefault: json['isDefault'] == true,
      sortOrder: safeInt(json['sortOrder']) ?? 0,
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
      'parentId': parentId,
      'description': description,
      'iconName': iconName,
      'color': color,
      'isActive': isActive,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    TransactionType? type,
    String? parentId,
    String? description,
    String? iconName,
    String? color,
    bool? isActive,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Extension methods for Category
extension CategoryX on Category {
  /// Check if this is a parent category
  bool get isParent => parentId == null;

  /// Check if this is a subcategory
  bool get isSubcategory => parentId != null;

  /// Create a copy with updated fields
  Category copyWithUpdatedAt() {
    return copyWith(updatedAt: DateTime.now());
  }
}

/// Default categories for the app
class DefaultCategories {
  static final List<Category> income = [
    Category(
      id: 'income_salary',
      name: 'Salary',
      type: TransactionType.income,
      iconName: 'work',
      color: '#4CAF50',
      isDefault: true,
      sortOrder: 1,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'income_freelance',
      name: 'Freelance',
      type: TransactionType.income,
      iconName: 'laptop',
      color: '#2196F3',
      isDefault: true,
      sortOrder: 2,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'income_investment',
      name: 'Investment',
      type: TransactionType.income,
      iconName: 'trending_up',
      color: '#FF9800',
      isDefault: true,
      sortOrder: 3,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'income_gift',
      name: 'Gift',
      type: TransactionType.income,
      iconName: 'card_giftcard',
      color: '#E91E63',
      isDefault: true,
      sortOrder: 4,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'income_other',
      name: 'Other Income',
      type: TransactionType.income,
      iconName: 'add_circle',
      color: '#9C27B0',
      isDefault: true,
      sortOrder: 5,
      createdAt: _defaultDate,
    ),
  ];

  static final List<Category> expenses = [
    Category(
      id: 'expense_food',
      name: 'Food & Dining',
      type: TransactionType.expense,
      iconName: 'restaurant',
      color: '#FF5722',
      isDefault: true,
      sortOrder: 1,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'expense_transport',
      name: 'Transportation',
      type: TransactionType.expense,
      iconName: 'directions_car',
      color: '#607D8B',
      isDefault: true,
      sortOrder: 2,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'expense_shopping',
      name: 'Shopping',
      type: TransactionType.expense,
      iconName: 'shopping_bag',
      color: '#9C27B0',
      isDefault: true,
      sortOrder: 3,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'expense_entertainment',
      name: 'Entertainment',
      type: TransactionType.expense,
      iconName: 'movie',
      color: '#E91E63',
      isDefault: true,
      sortOrder: 4,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'expense_utilities',
      name: 'Bills & Utilities',
      type: TransactionType.expense,
      iconName: 'receipt',
      color: '#795548',
      isDefault: true,
      sortOrder: 5,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'expense_healthcare',
      name: 'Healthcare',
      type: TransactionType.expense,
      iconName: 'local_hospital',
      color: '#F44336',
      isDefault: true,
      sortOrder: 6,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'expense_education',
      name: 'Education',
      type: TransactionType.expense,
      iconName: 'school',
      color: '#3F51B5',
      isDefault: true,
      sortOrder: 7,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'expense_travel',
      name: 'Travel',
      type: TransactionType.expense,
      iconName: 'flight',
      color: '#00BCD4',
      isDefault: true,
      sortOrder: 8,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'expense_home',
      name: 'Home & Garden',
      type: TransactionType.expense,
      iconName: 'home',
      color: '#4CAF50',
      isDefault: true,
      sortOrder: 9,
      createdAt: _defaultDate,
    ),
    Category(
      id: 'expense_other',
      name: 'Other Expenses',
      type: TransactionType.expense,
      iconName: 'more_horiz',
      color: '#757575',
      isDefault: true,
      sortOrder: 10,
      createdAt: _defaultDate,
    ),
  ];

  static final DateTime _defaultDate = DateTime.fromMicrosecondsSinceEpoch(0);

  static List<Category> get all => [...income, ...expenses];
}


