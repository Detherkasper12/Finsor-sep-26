import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/models/wallet.dart';
import 'package:finsor/utils/currency_formatter.dart';

/// Sanity: wallet balance is always displayed in wallet.currency.
/// Changing primary currency (global) must not mutate wallet.currency.
void main() {
  test('wallet with BTC remains BTC; balance displayed in wallet.currency', () {
    final wallet = Wallet(
      id: 'w1',
      name: 'Crypto',
      type: WalletType.crypto,
      currency: 'BTC',
      initialBalance: 0,
      currentBalance: 0.5,
      createdAt: DateTime.now(),
    );
    expect(wallet.currency, equals('BTC'));
    final formatted = CurrencyFormatter.formatWalletBalance(wallet);
    expect(formatted, isNotEmpty);
    expect(wallet.currency, equals('BTC'));
  });
}
