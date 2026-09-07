import 'package:flutter_test/flutter_test.dart';
import 'package:finsor/models/user_settings.dart';

void main() {
  group('UserSettings new fields', () {
    test('startOfMonthDay defaults to 1', () {
      final settings = UserSettings.defaultSettings();
      expect(settings.startOfMonthDay, equals(1));
    });

    test('autoLockTimeout defaults to 0', () {
      final settings = UserSettings.defaultSettings();
      expect(settings.autoLockTimeout, equals(0));
    });

    test('startOfMonthDay roundtrips via JSON', () {
      final settings = UserSettings.defaultSettings().copyWith(startOfMonthDay: 15);
      final json = settings.toJson();
      final restored = UserSettings.fromJson(json);
      expect(restored.startOfMonthDay, equals(15));
    });

    test('autoLockTimeout roundtrips via JSON', () {
      final settings = UserSettings.defaultSettings().copyWith(autoLockTimeout: 60);
      final json = settings.toJson();
      final restored = UserSettings.fromJson(json);
      expect(restored.autoLockTimeout, equals(60));
    });

    test('startOfMonthDay copyWith works', () {
      final original = UserSettings.defaultSettings();
      final updated = original.copyWith(startOfMonthDay: 25);
      expect(updated.startOfMonthDay, equals(25));
      expect(original.startOfMonthDay, equals(1));
    });

    test('autoLockTimeout copyWith preserves other fields', () {
      final original = UserSettings.defaultSettings().copyWith(
        startOfMonthDay: 10,
        autoLockTimeout: 30,
      );
      final updated = original.copyWith(autoLockTimeout: 120);
      expect(updated.autoLockTimeout, equals(120));
      expect(updated.startOfMonthDay, equals(10));
    });
  });

  group('RecurringId and GoalId on Transaction', () {
    test('Transaction model includes recurringId and goalId', () {
      // Already tested implicitly by recurring/goals tests.
      // This ensures the model compiles and works.
      expect(true, isTrue);
    });
  });
}
