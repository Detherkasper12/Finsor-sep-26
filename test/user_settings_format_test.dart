import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/models/user_settings.dart';

void main() {
  group('UserSettings currency format and start screen', () {
    test('fromJson with currencyFormatId and startScreenIndex', () {
      final s = UserSettings.fromJson({
        'themeMode': 'system',
        'primaryCurrency': {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
        'locale': 'en',
        'weekStartDay': 1,
        'currencyFormatId': 'space_comma',
        'startScreenIndex': 2,
        'createdAt': '2024-01-01T00:00:00.000Z',
      });
      expect(s.currencyFormatId, 'space_comma');
      expect(s.startScreenIndex, 2);
    });

    test('fromJson missing currencyFormatId defaults to default', () {
      final s = UserSettings.fromJson({
        'themeMode': 'system',
        'primaryCurrency': {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
        'locale': 'en',
        'createdAt': '2024-01-01T00:00:00.000Z',
      });
      expect(s.currencyFormatId, 'default');
      expect(s.startScreenIndex, 0);
    });

    test('toJson includes currencyFormatId and startScreenIndex', () {
      final s = UserSettings(
        createdAt: DateTime.now(),
        currencyFormatId: 'dot_comma',
        startScreenIndex: 4,
      );
      final json = s.toJson();
      expect(json['currencyFormatId'], 'dot_comma');
      expect(json['startScreenIndex'], 4);
    });
  });
}
