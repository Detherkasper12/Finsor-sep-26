import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsor/constants/supported_currencies.dart';
import 'package:finsor/models/wallet.dart';
import 'package:finsor/models/user_settings.dart';
import 'package:finsor/screens/ai/ai_screen.dart';
import 'package:finsor/utils/app_localizations.dart';

void main() {
  group('AI screen single chat', () {
    testWidgets('renders single chat only, no Finance tab', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AIScreen()),
          ),
        ),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(TabBar), findsNothing);
      expect(find.text('Finance'), findsNothing);
      expect(find.text('Assistant'), findsNothing);
    });
  });

  group('Currency picker contents', () {
    test('fiat list contains ILS, USD, EUR, GBP, JPY', () {
      final codes = SupportedCurrencies.fiat.map((c) => c.code).toList();
      expect(codes, contains('ILS'));
      expect(codes, contains('USD'));
      expect(codes, contains('EUR'));
      expect(codes, contains('GBP'));
      expect(codes, contains('JPY'));
    });

    test('fiat list has more than 5 currencies', () {
      expect(SupportedCurrencies.fiat.length, greaterThan(5));
    });
  });

  group('Crypto picker', () {
    test('crypto list contains BTC and ETH', () {
      final codes = SupportedCurrencies.crypto.map((c) => c.code).toList();
      expect(codes, contains('BTC'));
      expect(codes, contains('ETH'));
    });

    test('forWalletType crypto returns crypto currencies', () {
      final list = SupportedCurrencies.forWalletType(true);
      expect(list.any((c) => c.code == 'BTC'), isTrue);
      expect(list.any((c) => c.code == 'ETH'), isTrue);
    });

    test('forWalletType fiat returns fiat only', () {
      final list = SupportedCurrencies.forWalletType(false);
      expect(list.any((c) => c.code == 'BTC'), isFalse);
      expect(list.any((c) => c.code == 'USD'), isTrue);
    });
  });

  group('Base currency vs wallet currency', () {
    test('wallet currency is independent of primary currency', () {
      final wallet = Wallet(
        id: 'w1',
        name: 'My EUR Wallet',
        type: WalletType.bank,
        currency: 'EUR',
        createdAt: DateTime.now(),
      );
      final settings = UserSettings(
        primaryCurrency: const Currency(code: 'USD', name: 'US Dollar', symbol: r'$'),
        createdAt: DateTime.now(),
      );

      expect(wallet.currency, 'EUR');
      expect(settings.primaryCurrency.code, 'USD');
      expect(wallet.currency, isNot(equals(settings.primaryCurrency.code)));
    });

    test('primary currency change does not change wallet currency', () {
      final wallet = Wallet(
        id: 'w1',
        name: 'Crypto',
        type: WalletType.crypto,
        currency: 'BTC',
        createdAt: DateTime.now(),
      );
      final newSettings = UserSettings(
        primaryCurrency: const Currency(code: 'ILS', name: 'Israeli Shekel', symbol: '₪'),
        createdAt: DateTime.now(),
      );

      expect(wallet.currency, 'BTC');
      expect(newSettings.primaryCurrency.code, 'ILS');
    });
  });

  group('Language change updates labels', () {
    test('en and ru return different strings for same key', () {
      final en = AppLocalizations(const Locale('en'));
      final ru = AppLocalizations(const Locale('ru'));

      expect(en.home, 'Home');
      expect(ru.home, isNot(equals('Home')));
      expect(ru.home, isNotEmpty);
    });

    test('settings key differs between en and ru', () {
      final en = AppLocalizations(const Locale('en'));
      final ru = AppLocalizations(const Locale('ru'));

      expect(en.settings, 'Settings');
      expect(ru.settings, isNot(equals('Settings')));
    });
  });
}
