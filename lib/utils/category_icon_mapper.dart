import 'package:flutter/material.dart';

class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> _map = {
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'shopping_bag': Icons.shopping_bag,
    'movie': Icons.movie,
    'work': Icons.work,
    'laptop': Icons.laptop_mac,
    'laptop_mac': Icons.laptop_mac,
    'trending_up': Icons.trending_up,
    'card_giftcard': Icons.card_giftcard,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'flight': Icons.flight,
    'receipt': Icons.receipt,
    'home': Icons.home,
    'more_horiz': Icons.more_horiz,
    'add_circle': Icons.add_circle,
    'pets': Icons.pets,
    'sports_esports': Icons.sports_esports,
    'fitness_center': Icons.fitness_center,
    'child_care': Icons.child_care,
    'local_grocery_store': Icons.local_grocery_store,
    'local_cafe': Icons.local_cafe,
    'local_bar': Icons.local_bar,
    'phone_android': Icons.phone_android,
    'music_note': Icons.music_note,
    'brush': Icons.brush,
    'build': Icons.build,
    'attach_money': Icons.attach_money,
    'savings': Icons.savings,
    'account_balance': Icons.account_balance,
    'credit_card': Icons.credit_card,
    'payments': Icons.payments,
    'currency_bitcoin': Icons.currency_bitcoin,
    'account_balance_wallet': Icons.account_balance_wallet,
    'category': Icons.category,
    'subscriptions': Icons.subscriptions,
    'local_gas_station': Icons.local_gas_station,
    'local_parking': Icons.local_parking,
    'local_laundry_service': Icons.local_laundry_service,
    'checkroom': Icons.checkroom,
    'volunteer_activism': Icons.volunteer_activism,
  };

  static IconData fromName(String name) => _map[name] ?? Icons.category;

  static List<String> get allNames => _map.keys.toList();

  static IconData walletIcon(String typeName) {
    switch (typeName) {
      case 'cash':
        return Icons.payments;
      case 'bank':
        return Icons.account_balance;
      case 'card':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      case 'investment':
        return Icons.trending_up;
      case 'crypto':
        return Icons.currency_bitcoin;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
