import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:finsor/services/hive_database_service.dart';
import 'package:finsor/models/user_settings.dart';

void main() {
  late HiveDatabaseService db;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final path = '${DateTime.now().millisecondsSinceEpoch}_settings_sync_test';
    Hive.init(path);
    db = HiveDatabaseService.instance;
    await db.init();
  });

  tearDownAll(() async {
    await db.close();
  });

  group('User Settings Sync', () {
    test('startOfMonthDay persists and roundtrips', () async {
      final settings = await db.getUserSettings();
      final updated = settings.copyWith(
        startOfMonthDay: 15,
        updatedAt: DateTime.now(),
      );
      await db.updateUserSettings(updated);

      final retrieved = await db.getUserSettings();
      expect(retrieved.startOfMonthDay, 15);
    });

    test('autoLockTimeout persists and roundtrips', () async {
      final settings = await db.getUserSettings();
      final updated = settings.copyWith(
        autoLockTimeout: 60,
        updatedAt: DateTime.now(),
      );
      await db.updateUserSettings(updated);

      final retrieved = await db.getUserSettings();
      expect(retrieved.autoLockTimeout, 60);
    });

    test('settings toJson includes sync-relevant fields', () async {
      final settings = await db.getUserSettings();
      final json = settings.toJson();

      expect(json.containsKey('startOfMonthDay'), true);
      expect(json.containsKey('autoLockTimeout'), true);
      expect(json.containsKey('themeMode'), true);
      expect(json.containsKey('locale'), true);
      expect(json.containsKey('primaryCurrency'), true);
      expect(json.containsKey('createdAt'), true);
      expect(json.containsKey('updatedAt'), true);
    });

    test('settings can be deserialized from remote format', () {
      final remoteJson = {
        'themeMode': 'dark',
        'primaryCurrency': {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'decimalPlaces': 2, 'exchangeRate': 1.0},
        'locale': 'fr',
        'requirePinForAccess': false,
        'useBiometrics': false,
        'showBalanceOnHome': true,
        'enableNotifications': true,
        'enableBudgetAlerts': true,
        'enableCloudSync': true,
        'includeTransferInStats': true,
        'weekStartDay': 7,
        'startOfMonthDay': 25,
        'autoLockTimeout': 120,
        'defaultWalletId': 'w1',
        'isPremiumUser': false,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-15T00:00:00.000Z',
        'preferences': {},
      };

      final settings = UserSettings.fromJson(remoteJson);
      expect(settings.startOfMonthDay, 25);
      expect(settings.autoLockTimeout, 120);
      expect(settings.locale, 'fr');
      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.primaryCurrency.code, 'EUR');
    });
  });
}
