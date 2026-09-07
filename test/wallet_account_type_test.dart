import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/models/wallet.dart';

void main() {
  group('Wallet account type', () {
    test('fromJson with accountType regular defaults includeInTotal true', () {
      final w = Wallet.fromJson({
        'id': 'w1',
        'name': 'Cash',
        'type': 'cash',
        'currency': 'USD',
        'initialBalance': 0,
        'currentBalance': 100,
        'createdAt': '2024-01-01T00:00:00.000Z',
      });
      expect(w.accountType, AccountType.regular);
      expect(w.includeInTotal, isTrue);
    });

    test('fromJson with accountType debt defaults includeInTotal false', () {
      final w = Wallet.fromJson({
        'id': 'w2',
        'name': 'Credit',
        'type': 'card',
        'accountType': 'debt',
        'currency': 'USD',
        'debtIOwe': 500,
        'debtTotal': 500,
        'createdAt': '2024-01-01T00:00:00.000Z',
      });
      expect(w.accountType, AccountType.debt);
      expect(w.includeInTotal, isFalse);
      expect(w.debtIOwe, 500);
    });

    test('toJson round-trip preserves accountType and new fields', () {
      final w = Wallet(
        id: 'w3',
        name: 'Savings',
        type: WalletType.savings,
        accountType: AccountType.savings,
        currency: 'USD',
        initialBalance: 0,
        currentBalance: 200,
        includeInTotal: false,
        goalAmount: 1000,
        createdAt: DateTime.now(),
      );
      final json = w.toJson();
      expect(json['accountType'], 'savings');
      expect(json['goalAmount'], 1000);
      final w2 = Wallet.fromJson(json);
      expect(w2.accountType, AccountType.savings);
      expect(w2.goalAmount, 1000);
    });
  });
}
